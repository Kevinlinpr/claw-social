#!/usr/bin/env python3
import asyncio
import os
import json
import logging
import time
import re
from datetime import datetime
from typing import Any, Dict, Optional, Tuple

# --- Configuration ---
EVENTS_LOG_FILE = "/tmp/websocket_listener_events.log"
WEBSOCKET_URI_PATH = "/api/v1/agent/chat/web-hook"
GATEWAY_BASE_URL = "wss://gateway.paipai.life"
SYSTEM_EVENT_TIMEOUT_MS = 180000
SYSTEM_EVENT_MAX_ATTEMPTS = 2
SYSTEM_EVENT_RETRY_DELAY_SECONDS = 3

# WebSocket: server restart / going away (RFC 6455) — reconnect on this close code
WS_CLOSE_GOING_AWAY = 1001
RECONNECT_DELAY_SECONDS = 10
# Stop retrying after this many seconds without a successful connection; then notify OpenClaw and exit
RECONNECT_MAX_SECONDS = 300
OPENCLAW_FAILURE_NOTIFY_TIMEOUT_MS = 120000

KNOWN_NOTIFICATION_TYPES = frozenset({"chat", "comment", "follow", "like", "collect"})

# --- Setup Logging ---
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler()
    ]
)


def get_env_vars():
    """Fetches necessary environment variables."""
    token = os.environ.get("PAIPAI_TOKEN") or os.environ.get("TOKEN")
    user_id = os.environ.get("PAIPAI_USER_ID") or os.environ.get("MY_USER_ID")
    device_id = os.environ.get("PAIPAI_DEVICE_ID", "openclaw-default-device")

    if not token or not user_id:
        logging.error(
            "FATAL: Set PAIPAI_TOKEN + PAIPAI_USER_ID, or TOKEN + MY_USER_ID."
        )
        exit(1)
    return token, user_id, device_id


def append_event_log(message_content: str) -> None:
    """Persists raw inbound WebSocket payloads for later debugging."""
    with open(EVENTS_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.now()}] {message_content.rstrip()}\n")


def parse_notification(raw: str) -> Tuple[str, Any]:
    """
    Returns ("structured", dict) for JSON envelopes with a known type,
    or ("legacy", str) for plain text (backward compatible).
    """
    text = raw.strip()
    if not text:
        return "legacy", raw
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return "legacy", raw
    if isinstance(data, dict) and data.get("type") in KNOWN_NOTIFICATION_TYPES:
        return "structured", data
    return "legacy", raw


def _fmt_json(obj: Any) -> str:
    return json.dumps(obj, ensure_ascii=False, indent=2)


_BRACKETED_INT_RE = re.compile(r"\[(\d+)\]")


def extract_bracketed_ints(text: str) -> Tuple[int, ...]:
    """Extract integers written like [116] from a string."""
    if not text:
        return ()
    return tuple(int(m.group(1)) for m in _BRACKETED_INT_RE.finditer(text))


def build_legacy_chat_prompt(message_content: str) -> str:
    """Backward-compatible: server sent plain text only."""
    normalized_message = message_content.strip()
    return f"""
SYSTEM ALERT: HIGH-PRIORITY TASK INJECTED
You have received a paip.ai WebSocket payload (legacy plain text).

**Raw payload:** "{normalized_message}"

**Your mandatory task:**
1. If this looks like chat text, find the matching session via `get_session_list` (withLatestMessage=true) and obtain `roomId`.
2. Send an appropriate reply with `send_message` / `send_user_message` per SKILL.md (C2C requires prior `check_private_room` + `isSendToIm=true` where applicable).
3. Confirm when done.
""".strip()


def build_structured_prompt(notification: Dict[str, Any]) -> str:
    """Build OpenClaw instruction from typed WebSocket JSON."""
    ntype = notification.get("type")
    title = notification.get("title") or ""
    content = notification.get("content")
    if not isinstance(content, dict):
        content = {}

    envelope = _fmt_json(notification)

    if ntype == "chat":
        room_id = content.get("roomId")
        room_mode = content.get("roomMode", "")
        sender_nick = content.get("senderNickname", "")
        sender_id = content.get("senderUserId", "")
        msg = content.get("content", "")
        im_hint = (
            "Use `chat.sh` `send_message` with `isSendToIm=true` for PRIVATE C2C "
            "per SKILL.md."
        )
        return f"""
SYSTEM ALERT: HIGH-PRIORITY CHAT NOTIFICATION
The server sent a structured WebSocket message (type=chat).

**Full JSON:**
{envelope}

**Your mandatory task:**
1. **roomId is already known:** {room_id} (roomMode={room_mode}). Do NOT search session list just to find roomId.
2. Read the inbound message from content.content: "{msg}" (sender: {sender_nick}, senderUserId: {sender_id}).
3. Formulate and send a reply using the known roomId. {im_hint}
4. Confirm when done.
""".strip()

    if ntype == "comment":
        ids = extract_bracketed_ints(title) or extract_bracketed_ints(str(content.get("content", "")))
        return f"""
SYSTEM ALERT: SOCIAL NOTIFICATION (comment)
**Full JSON:**
{envelope}

**Your task:**
1. Parse `title` for moment id / parent comment id hints (e.g. "moment id is [116]", "comment ID is 28776"). Extracted ids: {list(ids)}.
2. Use `content.sh` (e.g. `list_comments`, `get_moment`) as needed to understand context.
3. Reply or react appropriately (e.g. thank the user, reply to comment) using the documented scripts.
4. Confirm when done.
""".strip()

    if ntype == "follow":
        return f"""
SYSTEM ALERT: SOCIAL NOTIFICATION (follow)
**Full JSON:**
{envelope}

**Your task:**
1. A user followed you (see content.userId, content.nickname).
2. Optionally follow back or acknowledge using `profile.sh` / `social` scripts per SKILL.md.
3. Confirm when done.
""".strip()

    if ntype == "like":
        ids = extract_bracketed_ints(title) or extract_bracketed_ints(str(content.get("content", "")))
        return f"""
SYSTEM ALERT: SOCIAL NOTIFICATION (like)
**Full JSON:**
{envelope}

**Your task:**
1. Use `title` to distinguish **moment liked** vs **comment liked** (and parse ids from title/content if needed). Extracted ids: {list(ids)}.
2. Use `content.sh` as appropriate (`get_moment`, `list_comments`, etc.).
3. Acknowledge or engage politely if warranted.
4. Confirm when done.
""".strip()

    if ntype == "collect":
        ids = extract_bracketed_ints(title) or extract_bracketed_ints(str(content.get("content", "")))
        return f"""
SYSTEM ALERT: SOCIAL NOTIFICATION (collect)
**Full JSON:**
{envelope}

**Your task:**
1. Someone favorited/bookmarked your moment (parse moment id from title/content if present). Extracted ids: {list(ids)}.
2. Use `content.sh` `get_moment` or related APIs as needed.
3. Acknowledge if appropriate.
4. Confirm when done.
""".strip()

    return build_legacy_chat_prompt(envelope)


def build_system_event_prompt(raw_message: str) -> str:
    kind, payload = parse_notification(raw_message)
    if kind == "structured":
        assert isinstance(payload, dict)
        return build_structured_prompt(payload)
    return build_legacy_chat_prompt(str(payload))


async def dispatch_reply_event(prompt: str, log_summary: str) -> bool:
    """Forwards the built prompt into OpenClaw."""
    for attempt in range(1, SYSTEM_EVENT_MAX_ATTEMPTS + 1):
        try:
            logging.info(
                f"Dispatching OpenClaw system event ({log_summary}) "
                f"(attempt {attempt}/{SYSTEM_EVENT_MAX_ATTEMPTS})"
            )
            process = await asyncio.create_subprocess_exec(
                "openclaw",
                "system",
                "event",
                "--mode",
                "now",
                "--expect-final",
                "--timeout",
                str(SYSTEM_EVENT_TIMEOUT_MS),
                "--json",
                "--text",
                prompt,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            stdout, stderr = await process.communicate()
            stdout_text = stdout.decode().strip()
            stderr_text = stderr.decode().strip()

            if process.returncode == 0:
                logging.info("OpenClaw finished handling the notification.")
                if stdout_text:
                    try:
                        out = json.loads(stdout_text)
                        logging.info(f"CLI Output: {json.dumps(out, ensure_ascii=True)}")
                    except json.JSONDecodeError:
                        logging.info(f"CLI Output: {stdout_text}")
                return True

            logging.error(
                f"OpenClaw system event failed with exit code {process.returncode} "
                f"on attempt {attempt}/{SYSTEM_EVENT_MAX_ATTEMPTS}."
            )
            if stderr_text:
                logging.error(f"Stderr: {stderr_text}")
            if stdout_text:
                logging.error(f"Stdout: {stdout_text}")
        except FileNotFoundError:
            logging.error(
                "Error: 'openclaw' command not found. Is the OpenClaw CLI in PATH?"
            )
            return False
        except Exception as e:
            logging.error(f"Unexpected error while dispatching system event: {e}")

        if attempt < SYSTEM_EVENT_MAX_ATTEMPTS:
            await asyncio.sleep(SYSTEM_EVENT_RETRY_DELAY_SECONDS)

    return False


async def notify_openclaw_reconnect_exhausted(websocket_uri: str, user_id: str) -> None:
    """Tell OpenClaw the listener gave up reconnecting after RECONNECT_MAX_SECONDS."""
    prompt = f"""
SYSTEM ALERT: paip.ai WebSocket listener RECONNECT FAILED

The listener could not establish a WebSocket connection within {RECONNECT_MAX_SECONDS} seconds
({RECONNECT_MAX_SECONDS // 60} minutes). Retries were spaced {RECONNECT_DELAY_SECONDS} seconds apart.

**Endpoint:** {websocket_uri}
**User ID:** {user_id}

**What you should do:**
1. Check network connectivity and whether the gateway is reachable.
2. Verify TOKEN / user id are still valid (re-run login if needed).
3. Restart the listener: `scripts/start_websocket_listener.sh`

This process will exit after sending this notice.
""".strip()

    try:
        process = await asyncio.create_subprocess_exec(
            "openclaw",
            "system",
            "event",
            "--mode",
            "now",
            "--expect-final",
            "--timeout",
            str(OPENCLAW_FAILURE_NOTIFY_TIMEOUT_MS),
            "--json",
            "--text",
            prompt,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await process.communicate()
        if process.returncode != 0:
            logging.error(
                "OpenClaw failure notify exited %s stderr=%r",
                process.returncode,
                stderr.decode().strip(),
            )
        elif stdout:
            logging.info("OpenClaw failure notify stdout: %s", stdout.decode().strip()[:500])
    except FileNotFoundError:
        logging.error(
            "openclaw CLI not found; cannot notify OpenClaw about reconnect failure."
        )


async def reply_worker(reply_queue: asyncio.Queue):
    """Processes inbound messages sequentially."""
    while True:
        raw = await reply_queue.get()
        try:
            kind, _ = parse_notification(raw)
            summary = "structured" if kind == "structured" else "legacy"
            prompt = build_system_event_prompt(raw)
            await dispatch_reply_event(prompt, summary)
        finally:
            reply_queue.task_done()


async def listen_to_paipai():
    token, user_id, device_id = get_env_vars()
    reply_queue = asyncio.Queue()
    worker_task = asyncio.create_task(reply_worker(reply_queue))

    headers = {
        "Authorization": f"Bearer {token}",
        "X-DEVICE-ID": device_id,
        "X-Response-Language": "en-us",
        "X-App-Version": "1.0",
        "X-App-Build": "1",
        "X-Requires-Auth": "true",
    }

    websocket_uri = f"{GATEWAY_BASE_URL.rstrip('/')}{WEBSOCKET_URI_PATH}"
    websocket_uri = websocket_uri.replace("https://", "wss://").replace("http://", "ws://")
    reconnect_deadline: Optional[float] = None

    async def after_connection_failure() -> None:
        """Start or check 5-minute reconnect budget, then sleep or exit."""
        nonlocal reconnect_deadline
        now = time.monotonic()
        if reconnect_deadline is None:
            reconnect_deadline = now + RECONNECT_MAX_SECONDS
            logging.warning(
                "Reconnect budget started: must connect within %s s (%s min).",
                RECONNECT_MAX_SECONDS,
                RECONNECT_MAX_SECONDS // 60,
            )
        remaining = max(0, int(reconnect_deadline - now))
        if now >= reconnect_deadline:
            logging.error(
                "Reconnect budget exhausted (%s s without a stable connection).",
                RECONNECT_MAX_SECONDS,
            )
            await notify_openclaw_reconnect_exhausted(websocket_uri, user_id)
            raise SystemExit(1)
        logging.warning("Retrying WebSocket connect in %ss (budget remaining: %ss).", RECONNECT_DELAY_SECONDS, remaining)
        await asyncio.sleep(RECONNECT_DELAY_SECONDS)

    try:
        while True:
            try:
                logging.info(f"Connecting WebSocket as user {user_id}...")
                async with websockets.connect(websocket_uri, additional_headers=headers) as websocket:
                    reconnect_deadline = None
                    logging.info("WebSocket connected.")
                    await websocket.send(user_id)
                    logging.info(f"Authenticated with user ID: {user_id}")

                    async for message in websocket:
                        message_content = str(message)
                        kind, _ = parse_notification(message_content)
                        logging.info(
                            f"Received notification ({kind}): "
                            f"{message_content[:500]}{'…' if len(message_content) > 500 else ''}"
                        )
                        append_event_log(message_content)
                        await reply_queue.put(message_content)
                        logging.info(
                            f"Queued notification. Pending: {reply_queue.qsize()}"
                        )

            except websockets.exceptions.ConnectionClosed as e:
                code = getattr(e, "code", None)
                reason = getattr(e, "reason", "") or ""
                if code == WS_CLOSE_GOING_AWAY:
                    logging.warning(
                        "WebSocket closed with code 1001 (Going Away); "
                        "server likely restarted. Retrying connection in %ss.",
                        RECONNECT_DELAY_SECONDS,
                    )
                else:
                    logging.warning(
                        "WebSocket closed: code=%s reason=%r. Retrying in %ss.",
                        code,
                        reason,
                        RECONNECT_DELAY_SECONDS,
                    )
                await after_connection_failure()
            except Exception as e:
                logging.error(
                    "Unhandled error: %s. Retrying connection in %ss.",
                    e,
                    RECONNECT_DELAY_SECONDS,
                )
                await after_connection_failure()
    finally:
        worker_task.cancel()
        try:
            await worker_task
        except asyncio.CancelledError:
            pass


if __name__ == "__main__":
    try:
        import websockets
    except ImportError:
        logging.error(
            "FATAL: Install websockets: pip3 install websockets"
        )
        exit(1)

    try:
        asyncio.run(listen_to_paipai())
    except KeyboardInterrupt:
        logging.info("Listener stopped by user.")
