import asyncio
import os
import shlex
import subprocess
import sys
from datetime import datetime

import websockets
from websockets.exceptions import ConnectionClosed

# --- Configuration ---
# Support both the existing routine-style env vars and the listener-specific ones.
AUTH_TOKEN = os.environ.get("PAIPAI_TOKEN") or os.environ.get("TOKEN")
MY_USER_ID_RAW = os.environ.get("PAIPAI_USER_ID") or os.environ.get("MY_USER_ID")

WEBSOCKET_URL = "wss://gateway.paipai.life/api/v1/agent/chat/web-hook"
RECONNECT_DELAY_SECONDS = 5
EVENT_LOG_PATH = os.environ.get("WEBSOCKET_EVENT_LOG", "/tmp/websocket_listener_events.log")
OPENCLAW_COMMAND = shlex.split(
    os.environ.get("OPENCLAW_EVENT_COMMAND", "openclaw system event --mode now")
)
HEADERS = {
    "Authorization": f"Bearer {AUTH_TOKEN or ''}",
    "X-Requires-Auth": "true",
    "X-DEVICE-ID": "iOS",
    "X-App-Version": "1.0",
    "X-App-Build": "1",
    "X-Response-Language": "zh-cn",
    # The gateway expects the same style of headers as the REST APIs.
    "X-User-Location": "MTE2LjQwNjd8MzkuODgyMnzljJfkuqzlpKnlnZs=",
}


def log(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}", flush=True)


def append_event_log(notification_text):
    timestamp = datetime.now().isoformat()
    with open(EVENT_LOG_PATH, "a", encoding="utf-8") as event_log:
        event_log.write(f"{timestamp}\t{notification_text}\n")


def validate_config():
    if not AUTH_TOKEN:
        log("FATAL: TOKEN or PAIPAI_TOKEN environment variable must be set.")
        return None

    if not MY_USER_ID_RAW:
        log("FATAL: MY_USER_ID or PAIPAI_USER_ID environment variable must be set.")
        return None

    try:
        return int(MY_USER_ID_RAW)
    except ValueError:
        log(f"FATAL: user id must be numeric, got: {MY_USER_ID_RAW!r}")
        return None


async def wake_openclaw(notification_text):
    system_event_text = f"New message notification from paip.ai: '{notification_text}'"

    try:
        completed = await asyncio.to_thread(
            subprocess.run,
            [*OPENCLAW_COMMAND, "--text", system_event_text],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        log("WARNING: `openclaw` command not found in PATH; notification was not injected.")
        return
    except Exception as exc:
        log(f"WARNING: failed to invoke openclaw: {exc}")
        return

    if completed.returncode == 0:
        log("Successfully injected event into OpenClaw main session.")
        return

    stderr = (completed.stderr or "").strip()
    stdout = (completed.stdout or "").strip()
    detail = stderr or stdout or f"exit code {completed.returncode}"
    log(f"WARNING: OpenClaw event command failed: {detail}")


# --- Main WebSocket Logic ---
async def listen_to_paipai(my_user_id):
    log(f"Attempting to connect to WebSocket as user {my_user_id}...")

    try:
        async with websockets.connect(
            WEBSOCKET_URL,
            additional_headers=HEADERS,
            ping_interval=20,
            ping_timeout=20,
            close_timeout=10,
        ) as websocket:
            log("WebSocket connection established.")

            # The backend expects the first frame to be a JSON number matching X-User-Id.
            log(f"Authenticating with user ID: {my_user_id}")
            await websocket.send(str(my_user_id))
            log("Authentication message sent.")

            while True:
                message = await websocket.recv()

                if isinstance(message, bytes):
                    message = message.decode("utf-8", errors="replace")

                message = message.strip()
                if not message:
                    log("Received an empty notification; ignoring.")
                    continue

                # The backend currently pushes only raw content, not a full message object.
                log(f"Received raw notification: {message}")
                append_event_log(message)
                log(f"Saved raw notification to {EVENT_LOG_PATH}")
                await wake_openclaw(message)

    except ConnectionClosed as exc:
        log(f"Connection closed: code={exc.code}, reason={exc.reason!r}")
    except Exception as exc:
        log(f"Failed to connect or an unhandled error occurred: {exc}")


async def main():
    my_user_id = validate_config()
    if my_user_id is None:
        sys.exit(1)

    log(f"Using OpenClaw event command: {' '.join(OPENCLAW_COMMAND)}")
    log(f"Writing raw notification events to: {EVENT_LOG_PATH}")
    log(f"Listener process PID: {os.getpid()}")

    while True:
        await listen_to_paipai(my_user_id)
        log(f"Restarting WebSocket listener in {RECONNECT_DELAY_SECONDS} seconds.")
        await asyncio.sleep(RECONNECT_DELAY_SECONDS)


if __name__ == "__main__":
    asyncio.run(main())
