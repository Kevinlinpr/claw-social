#!/bin/bash
# Chat session and messaging functions for paip.ai
#
# Requires environment variables:
# - TOKEN: authentication token

BASE_URL="https://gateway.paipai.life/api/v1"

HEADERS=(
  "-H" "Authorization: Bearer $TOKEN"
  "-H" "X-Requires-Auth: true"
  "-H" "X-DEVICE-ID: iOS"
  "-H" "X-User-Location: $(echo -n "" | base64)"
  "-H" "X-Response-Language: zh-cn"
  "-H" "X-App-Version: 1.0"
  "-H" "X-App-Build: 1"
  "-H" "Content-Type: application/json"
)

# ── Session ──────────────────────────────────────────────────────────────────

# GET /agent/chat/session/list - Get session list
# Usage: get_session_list [page] [size] [withLatestMessage: true|false]
get_session_list() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-20}" \
            --data-urlencode "withLatestMessage=${3:-true}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/agent/chat/session/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.roomId)] \(.roomName) | \(.roomMode) | lang: \(.language)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Messaging ────────────────────────────────────────────────────────────────

# POST /agent/chat/send/message - Send a message
# Usage: send_message <room_id> "content" [isNewChat: true|false] [isSendToIm: true|false]
# Note: for C2C private chat isSendToIm must be true
send_message() {
    local room_id=$1; local content=$2
    local is_new_chat=${3:-false}; local is_send_to_im=${4:-false}
    local payload
    payload=$(jq -n \
        --argjson roomId "$room_id" \
        --arg content "$content" \
        --argjson isNewChat "$is_new_chat" \
        --argjson isSendToIm "$is_send_to_im" \
        '{roomId: $roomId, content: $content, isNewChat: $isNewChat, isSendToIm: $isSendToIm}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/chat/send/message" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Message sent to room $room_id."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/chat/send/message - C2C private chat send (requires roomId)
# IMPORTANT: For C2C you MUST call room.sh:check_private_room --user <targetUserImId> first,
# then send the message with isSendToIm=true.
# Usage: send_user_message <room_id> "content" [isNewChat: true|false]
send_user_message() {
    local room_id=$1
    local content=$2
    local is_new_chat=${3:-false}
    send_message "$room_id" "$content" "$is_new_chat" true
}

# ── History ──────────────────────────────────────────────────────────────────

# GET /agent/chat/history - Get chat history
# Usage: get_chat_history <room_id> [page] [size]
get_chat_history() {
    local params
    params=(--data-urlencode "roomId=$1" \
            --data-urlencode "page=${2:-1}" \
            --data-urlencode "size=${3:-20}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/agent/chat/history" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.userType)] \(.createdAt): \(.content[:80])")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/chat/clear/history - Clear chat history
# Usage: clear_chat_history <room_id> [messageId1 messageId2 ...]
#        clear_chat_history <room_id>          → clears all
clear_chat_history() {
    local room_id=$1; shift
    local payload
    if [[ $# -eq 0 ]]; then
        payload=$(jq -n --argjson roomId "$room_id" '{roomId: $roomId, isClearAll: true}')
    else
        local ids_json; ids_json=$(printf '"%s"\n' "$@" | jq -s '.')
        payload=$(jq -n --argjson roomId "$room_id" --argjson messageIds "$ids_json" \
            '{roomId: $roomId, isClearAll: false, messageIds: $messageIds}')
    fi
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/chat/clear/history" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "History cleared for room $room_id."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Language & Style ─────────────────────────────────────────────────────────

# POST /agent/chat/set/language - Set chat room language
# Usage: set_chat_language <room_id> "zh|en|ja"
set_chat_language() {
    local payload
    payload=$(jq -n --argjson roomId "$1" --arg language "$2" \
        '{roomId: $roomId, language: $language}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/chat/set/language" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Language set to '$2' for room $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /agent/chat/style-list - Get available agent chat styles
get_chat_style_list() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/agent/chat/style-list" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.styles[] | "  \(.code): \(.name)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/chat/update-style - Set agent chat style
# Usage: set_chat_style <room_id> "style_code"
set_chat_style() {
    local payload
    payload=$(jq -n --argjson roomId "$1" --arg style "$2" \
        '{roomId: $roomId, style: $style}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/chat/update-style" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Style set to '$2' for room $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Duration ─────────────────────────────────────────────────────────────────

# POST /agent/chat/report/duration - Report chat duration (seconds)
report_chat_duration() {
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/chat/report/duration" \
        "${HEADERS[@]}" -d "{\"duration\": $1}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Cumulative: \(.durationMinutes) min (\(.duration) sec)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
