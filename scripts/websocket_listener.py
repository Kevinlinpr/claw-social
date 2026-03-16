#!/usr/bin/env python3
import asyncio
import os
import subprocess
import json
import logging
from datetime import datetime, timedelta, timezone

# --- Configuration ---
LOG_FILE = "/tmp/websocket_listener.log"
EVENTS_LOG_FILE = "/tmp/websocket_listener_events.log"
WEBSOCKET_URI_PATH = "/api/v1/agent/chat/web-hook"
BASE_URL = "https://gateway.paipai.life"

# --- Setup Logging ---
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

# --- Helper Functions ---
def get_env_vars():
    """Fetches necessary environment variables."""
    token = os.environ.get("PAIPAI_TOKEN")
    user_id = os.environ.get("PAIPAI_USER_ID")
    device_id = os.environ.get("PAIPAI_DEVICE_ID", "openclaw-default-device")
    
    if not token or not user_id:
        logging.error("FATAL: PAIPAI_TOKEN and PAIPAI_USER_ID environment variables must be set.")
        exit(1)
    return token, user_id, device_id

def schedule_reply_agent(message_content: str):
    """Calls the OpenClaw CLI to schedule an immediate isolated agent job."""
    try:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        job_name = f"paipai-reply-agent-{timestamp}"

        # The agent will run this prompt in an isolated session
        prompt = f"""
        SYSTEM ALERT: HIGH-PRIORITY TASK INJECTED
        You have received a new message on paip.ai. You MUST handle this now.

        **Message Content:** "{message_content}"

        **Your mandatory task is as follows:**
        1.  **Find the Room ID:** Immediately execute a search using the paip.ai API to find the chat session where the latest message content exactly matches the text above. This typically involves calling the `/agent/chat/session/list?withLatestMessage=true` endpoint and parsing the JSON response.
        2.  **Extract the `roomId`** from the correct session object in the search result.
        3.  **Formulate a Reply:** Based on the message content, formulate a natural, conversational reply.
        4.  **Send the Reply:** Use the paip.ai API to send your formulated reply to the extracted `roomId`.
        5.  **Confirm Completion:** After sending the reply, your task is complete.
        """

        # Schedule for 2 seconds in the future to ensure it's not in the past
        run_at_time = (datetime.now(timezone.utc) + timedelta(seconds=2)).isoformat()

        logging.info(f"Scheduling isolated agent '{job_name}' for message: \"{message_content}\"")
        
        # Correct, verified command syntax
        command = [
            "openclaw", "cron", "add",
            "--name", job_name,
            "--at", run_at_time,
            "--session", "isolated",
            "--message", prompt,
            "--thinking", "high", # Important for complex replies
            "--delete-after-run" # This is a one-shot job
        ]
        
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        
        logging.info("Successfully scheduled isolated agent.")
        logging.info(f"CLI Output: {result.stdout.strip()}")

    except FileNotFoundError:
        logging.error("Error: 'openclaw' command not found. Is the OpenClaw CLI in your system's PATH?")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error calling OpenClaw CLI: {e}")
        logging.error(f"Stderr: {e.stderr.strip()}")
    except Exception as e:
        logging.error(f"An unexpected error occurred while scheduling the job: {e}")

async def listen_to_paipai():
    """Main function to connect to the WebSocket and listen for messages."""
    token, user_id, device_id = get_env_vars()
    
    headers = {
        "Authorization": f"Bearer {token}",
        "X-DEVICE-ID": device_id,
        "X-Response-Language": "en-us",
        "X-App-Version": "1.0",
        "X-App-Build": "1",
        "X-Requires-Auth": "true",
    }
    
    websocket_uri = f"wss://{BASE_URL.split('//')[1]}{WEBSOCKET_URI_PATH}"

    while True:
        try:
            logging.info(f"Attempting to connect to WebSocket as user {user_id}...")
            async with websockets.connect(websocket_uri, additional_headers=headers) as websocket:
                logging.info("WebSocket connection established.")
                
                await websocket.send(user_id)
                logging.info(f"Authenticated with user ID: {user_id}")
                
                async for message in websocket:
                    message_content = str(message)
                    logging.info(f"Received raw notification: {message_content}")
                    
                    with open(EVENTS_LOG_FILE, "a") as f:
                        f.write(f"[{datetime.now()}] {message_content}\n")
                    
                    schedule_reply_agent(message_content)

        except (websockets.exceptions.ConnectionClosedError, websockets.exceptions.ConnectionClosedOK) as e:
            logging.warning(f"WebSocket connection closed: {e}. Reconnecting in 10 seconds.")
            await asyncio.sleep(10)
        except Exception as e:
            logging.error(f"An unhandled error occurred: {e}. Reconnecting in 10 seconds.")
            await asyncio.sleep(10)

if __name__ == "__main__":
    try:
        import websockets
    except ImportError:
        logging.error("FATAL: The 'websockets' library is not installed. Please run 'pip3 install websockets'.")
        exit(1)

    try:
        asyncio.run(listen_to_paipai())
    except KeyboardInterrupt:
        logging.info("Listener stopped by user.")
