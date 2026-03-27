#!/bin/bash
# Room management functions for paip.ai
#
# Requires environment variables:
# - TOKEN: authentication token
# - USER_ID: current user ID (optional, for upload)

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

# ── Room Config ──────────────────────────────────────────────────────────────

# GET /room/config - Get global room config (member limits, rule limits)
get_room_config() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/room/config" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Private Room ─────────────────────────────────────────────────────────────

# POST /room/check/private - Check or create a private room
# Usage: check_private_room --agent <agentImId>   (C2A)
#        check_private_room --user  <targetUserImId>  (C2C, targetUserImId = 对方用户的 IM ID 字符串)
check_private_room() {
    local payload
    if [[ "$1" == "--agent" ]]; then
        payload=$(jq -n --arg agentImId "$2" '{agentImId: $agentImId}')
    elif [[ "$1" == "--user" ]]; then
        payload=$(jq -n --arg targetUserId "$2" '{targetUserId: $targetUserId}')
    else
        echo "Usage: check_private_room --agent <agentImId> | --user <userImId>"; return 1
    fi
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/check/private" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {roomId, language, style, outputMode}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Upload ────────────────────────────────────────────────────────────────────

# POST /room/common/upload - Upload room-related file, returns URL
# Usage: upload_room_file "/path/file.jpg" [room_id]
# REQUIRED before setting avatar, cover, or background on a room.
upload_room_file() {
    local resp
    resp=$(curl --max-time 600 -s -X POST "$BASE_URL/room/common/upload" \
        "-H" "Authorization: Bearer $TOKEN" \
        "-H" "X-DEVICE-ID: iOS" \
        "-H" "X-Response-Language: zh-cn" \
        -F "file=@$1" \
        -F "type=room" \
        -F "path=room" \
        -F "id=${2:-0}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.path'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /room/common/upload - Upload chat image/file, returns URL
# Usage: upload_chat_file "/path/file.jpg" [room_id]
# Note: for chat messages, pass path=chat and type=image.
upload_chat_file() {
    local resp
    resp=$(curl --max-time 600 -s -X POST "$BASE_URL/room/common/upload" \
        "-H" "Authorization: Bearer $TOKEN" \
        "-H" "X-DEVICE-ID: iOS" \
        "-H" "X-Response-Language: zh-cn" \
        -F "file=@$1" \
        -F "type=image" \
        -F "path=chat" \
        -F "id=${2:-0}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.path'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Room CRUD ────────────────────────────────────────────────────────────────

# POST /room/create - Create a new room
# Usage: create_room "Name" "GROUP|PRIVATE" "PUBLIC|PRIVATE" <agentId> [userId...]
# mode and type are sent UPPERCASE to the API (normalized from any input case).
# GROUP / group chat: API requires agentIds — pass a real agent id (at least one agent).
# If none exists, run agent.sh list_agents or create_agent first.
create_room() {
    local name=$1
    local mode type
    mode=$(echo "${2:-GROUP}" | tr '[:lower:]' '[:upper:]')
    type=$(echo "${3:-PUBLIC}" | tr '[:lower:]' '[:upper:]')
    local agent_id=$4
    shift 4
    if [[ "$mode" == "GROUP" ]]; then
        if [[ -z "$agent_id" || ! "$agent_id" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: GROUP rooms require a valid numeric agentId (at least one agent)." >&2
            echo "Use agent.sh list_agents to pick an id, or agent.sh create_agent to create one first." >&2
            return 1
        fi
    fi
    local user_ids_json
    user_ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
    local payload
    payload=$(jq -n \
        --arg name "$name" \
        --arg mode "$mode" \
        --arg type "$type" \
        --argjson agentIds "[$agent_id]" \
        --argjson userIds "$user_ids_json" \
        '{name: $name, mode: $mode, type: $type, agentIds: $agentIds, userIds: $userIds}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/create" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Room created. ID: $(echo "$resp" | jq -r '.data.id'), IM ID: $(echo "$resp" | jq -r '.data.imId')"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /room/update - Update room info
# Usage: update_room <room_id> "NewName" ["PUBLIC|PRIVATE"] ["direct|default"] ["avatar_path_or_url"] ["cover_path_or_url"]
# avatar/cover: local file path → auto-uploaded via /room/common/upload; URL → used as-is
update_room() {
    local room_id=$1 name=$2
    local type=${3:-"PUBLIC"} output_mode=${4:-"default"}
    local avatar_input=${5:-} cover_input=${6:-}
    local avatar="" cover=""

    if [[ -n "$avatar_input" ]]; then
        if [[ -f "$avatar_input" ]]; then
            echo "Uploading room avatar..."
            avatar=$(upload_room_file "$avatar_input" "$room_id") || return 1
        else
            avatar=$avatar_input
        fi
    fi
    if [[ -n "$cover_input" ]]; then
        if [[ -f "$cover_input" ]]; then
            echo "Uploading room cover..."
            cover=$(upload_room_file "$cover_input" "$room_id") || return 1
        else
            cover=$cover_input
        fi
    fi

    local payload
    payload=$(jq -n \
        --argjson id "$room_id" --arg name "$name" \
        --arg type "$type" --arg outputMode "$output_mode" \
        --arg avatar "$avatar" --arg cover "$cover" \
        '{id: $id, name: $name, type: $type, outputMode: $outputMode}
          | if $avatar != "" then . + {avatar: $avatar} else . end
          | if $cover != "" then . + {cover: $cover} else . end')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/room/update" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Room $room_id updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /room/:id - Get room by ID
get_room() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/room/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, name, mode, type, imId, memberCount, isInTheRoom, freeMemberCap}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /room/imid/:imId - Get room by IM ID
get_room_by_imid() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/room/imid/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, name, mode, type, imId, memberCount}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /room/list - List rooms
# Usage: list_rooms [page] [size] [GROUP|PRIVATE]
list_rooms() {
    local page=${1:-1}; local size=${2:-10}; local mode=${3:-""}
    local params=(--data-urlencode "page=$page" --data-urlencode "size=$size")
    [[ -n "$mode" ]] && params+=(--data-urlencode "mode=$mode")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/room/list" "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.name) | \(.mode) | \(.memberCount)/\(.roomCap) members")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /room/:id - Dissolve a room (owner only)
delete_room() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/room/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Room $1 dissolved."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Room Membership ───────────────────────────────────────────────────────────

# POST /room/join - Join a room
join_room() {
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/join" \
        "${HEADERS[@]}" -d "{\"roomId\": $1}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Joined room $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /room/invite - Invite users or agents
# Usage: invite_to_room <room_id> --users 101 102 | --agents 201 202
invite_to_room() {
    local room_id=$1; shift
    local payload
    if [[ "$1" == "--users" ]]; then
        shift
        local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
        payload=$(jq -n --argjson roomId "$room_id" --argjson userIds "$ids_json" '{roomId: $roomId, userIds: $userIds}')
    elif [[ "$1" == "--agents" ]]; then
        shift
        local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
        payload=$(jq -n --argjson roomId "$room_id" --argjson agentIds "$ids_json" '{roomId: $roomId, agentIds: $agentIds}')
    else
        echo "Usage: invite_to_room <roomId> --users <id...> | --agents <id...>"; return 1
    fi
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/invite" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Invite sent to room $room_id."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /room/remove - Remove members (owner only)
# Usage: remove_from_room <room_id> --users 101 102 | --agents 201
remove_from_room() {
    local room_id=$1; shift
    local payload
    if [[ "$1" == "--users" ]]; then
        shift
        local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
        payload=$(jq -n --argjson roomId "$room_id" --argjson userIds "$ids_json" '{roomId: $roomId, userIds: $userIds}')
    elif [[ "$1" == "--agents" ]]; then
        shift
        local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
        payload=$(jq -n --argjson roomId "$room_id" --argjson agentIds "$ids_json" '{roomId: $roomId, agentIds: $agentIds}')
    else
        echo "Usage: remove_from_room <roomId> --users <id...> | --agents <id...>"; return 1
    fi
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/remove" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Members removed from room $room_id."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /room/exit - Exit a room
exit_room() {
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/exit" \
        "${HEADERS[@]}" -d "{\"roomId\": $1}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Exited room $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Room Background ───────────────────────────────────────────────────────────

# GET /room/background/default - Get default background list
get_default_backgrounds() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/room/background/default" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[]'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /room/background - Set chat background
# Usage: set_room_background <room_id> ["path_or_url"]  (empty = reset to default)
# Local file path → auto-uploaded via /room/common/upload; URL → used as-is
set_room_background() {
    local room_id=$1 bg_input=${2:-}
    local background=""

    if [[ -n "$bg_input" ]]; then
        if [[ -f "$bg_input" ]]; then
            echo "Uploading background..."
            background=$(upload_room_file "$bg_input" "$room_id") || return 1
        else
            background=$bg_input
        fi
    fi

    local payload
    payload=$(jq -n --argjson roomId "$room_id" --arg background "$background" \
        '{roomId: $roomId, background: $background}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/room/background" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Background updated for room $room_id."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Room Capacity ────────────────────────────────────────────────────────────

# POST /room/add/cap - Expand room capacity
# Usage: add_room_cap <room_id> <count>
add_room_cap() {
    local payload
    payload=$(jq -n --argjson roomId "$1" --argjson memberCount "$2" \
        '{roomId: $roomId, memberCount: $memberCount}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/add/cap" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "New capacity: $(echo "$resp" | jq -r '.data.roomCap')"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Room Rules ────────────────────────────────────────────────────────────────

# POST /room/rule/add - Add a rule to a room
add_room_rule() {
    local payload
    payload=$(jq -n --argjson roomId "$1" --arg rule "$2" '{roomId: $roomId, rule: $rule}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/room/rule/add" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Rule added to room $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /room/rule/update - Update a rule
# Usage: update_room_rule <rule_id> "New content"
update_room_rule() {
    local payload
    payload=$(jq -n --argjson id "$1" --arg rule "$2" '{id: $id, rule: $rule}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/room/rule/update" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Rule $1 updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /room/rule/:id - Get rule detail
get_room_rule() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/room/rule/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, rule, createdAt, updatedAt}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /room/rule/list - List rules for a room
# Usage: list_room_rules <room_id> [page] [size]
list_room_rules() {
    local params
    params=(--data-urlencode "roomId=$1" \
            --data-urlencode "page=${2:-1}" \
            --data-urlencode "size=${3:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/room/rule/list" "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.rule)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /room/rule/:id - Delete a rule
delete_room_rule() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/room/rule/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Rule $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Recommend ─────────────────────────────────────────────────────────────────

# GET /room/recommend - Get recommended rooms
recommend_rooms() {
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/room/recommend" \
        "${HEADERS[@]}" --data-urlencode "limit=${1:-10}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  [\(.id)] \(.name) | \(.mode) | \(.memberCount)/\(.roomCap) members"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
