#!/bin/bash
# Agent (Prompt) management functions for paip.ai
#
# Requires environment variables:
# - TOKEN: authentication token
# - USER_ID: current user ID

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

# ── Upload ────────────────────────────────────────────────────────────────────

# POST /user/common/upload/file - Upload agent (prompt) avatar or banner, returns URL
# Usage: upload_prompt_file "/path/file.jpg" <agent_id>
# REQUIRED before setting avatar or roleAvatar on an agent.
upload_prompt_file() {
    local resp
    resp=$(curl --max-time 600 -s -X POST "$BASE_URL/user/common/upload/file" \
        "-H" "Authorization: Bearer $TOKEN" \
        "-H" "X-DEVICE-ID: iOS" \
        "-H" "X-Response-Language: zh-cn" \
        -F "file=@$1" \
        -F "type=prompt" \
        -F "path=avatar" \
        -F "id=${2:-0}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.path'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Agent CRUD ────────────────────────────────────────────────────────────────

# POST /user/prompt/create - Create a new AI agent
# Usage: create_agent "Name" "Desc" "System settings" "public|private"
create_agent() {
    local payload
    payload=$(jq -n \
        --arg name "$1" --arg desc "$2" \
        --arg settings "$3" --arg mode "${4:-public}" \
        '{name: $name, desc: $desc, settings: $settings, mode: $mode}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/prompt/create" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Agent created. ID: $(echo "$resp" | jq -r '.data.id'), IM ID: $(echo "$resp" | jq -r '.data.imId')"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /user/prompt/update - Update an agent
# Usage: update_agent <id> "Name" "Desc" "Settings" "public|private" ["avatar_path_or_url"] ["role_avatar_path_or_url"]
# avatar/roleAvatar: local file path → auto-uploaded via /user/common/upload/file; URL → used as-is
update_agent() {
    local id=$1 name=$2 desc=$3 settings=$4 mode=${5:-public}
    local avatar_input=${6:-} role_avatar_input=${7:-}
    local avatar="" role_avatar=""

    if [[ -n "$avatar_input" ]]; then
        if [[ -f "$avatar_input" ]]; then
            echo "Uploading agent avatar..."
            avatar=$(upload_prompt_file "$avatar_input" "$id") || return 1
        else
            avatar=$avatar_input
        fi
    fi
    if [[ -n "$role_avatar_input" ]]; then
        if [[ -f "$role_avatar_input" ]]; then
            echo "Uploading agent banner..."
            role_avatar=$(upload_prompt_file "$role_avatar_input" "$id") || return 1
        else
            role_avatar=$role_avatar_input
        fi
    fi

    local payload
    payload=$(jq -n \
        --argjson id "$id" --arg name "$name" --arg desc "$desc" \
        --arg settings "$settings" --arg mode "$mode" \
        --arg avatar "$avatar" --arg roleAvatar "$role_avatar" \
        '{id: $id, name: $name, desc: $desc, settings: $settings, mode: $mode}
          | if $avatar != "" then . + {avatar: $avatar} else . end
          | if $roleAvatar != "" then . + {roleAvatar: $roleAvatar} else . end')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/user/prompt/update" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Agent $id updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/prompt/:id - Get agent by ID
get_agent() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/prompt/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, name, desc, mode, imid, fansCount, isFollow}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/prompt/imid/:imId - Get agent by IM ID
get_agent_by_imid() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/prompt/imid/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, name, desc, mode, imid, fansCount}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/prompt/list - List agents with optional filters
# Usage: list_agents [page] [size] [authorId] [mode: public|private]
list_agents() {
    local params
    params=(--data-urlencode "page=${1:-1}" --data-urlencode "size=${2:-10}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "authorId=$3")
    [[ -n "${4:-}" ]] && params+=(--data-urlencode "mode=$4")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/prompt/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.name) | \(.mode) | fans: \(.fansCount)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /user/prompt/:id - Delete an agent
delete_agent() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/user/prompt/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Agent $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/prompt/recommend - Get recommended agents
recommend_agents() {
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/prompt/recommend" \
        "${HEADERS[@]}" --data-urlencode "limit=${1:-10}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  [\(.id)] \(.name): \(.desc[:60])"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Agent Rules ───────────────────────────────────────────────────────────────

# POST /user/prompt/create/rule - Create a rule for an agent
# Usage: create_agent_rule <agent_id> "Rule name" "Rule content"
create_agent_rule() {
    local payload
    payload=$(jq -n \
        --argjson promptId "$1" --arg name "$2" --arg rule "$3" \
        '{promptId: $promptId, name: $name, rule: $rule}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/prompt/create/rule" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Rule created for agent $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /user/prompt/edit/rule - Update an agent rule
# Usage: update_agent_rule <rule_id> <agent_id> "New name" "New content"
update_agent_rule() {
    local payload
    payload=$(jq -n \
        --argjson id "$1" --argjson promptId "$2" \
        --arg name "$3" --arg rule "$4" \
        '{id: $id, promptId: $promptId, name: $name, rule: $rule}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/user/prompt/edit/rule" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Agent rule $1 updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/prompt/rule/list - List rules for an agent
# Usage: list_agent_rules <agent_id> [page] [size]
list_agent_rules() {
    local params
    params=(--data-urlencode "promptId=$1" \
            --data-urlencode "page=${2:-1}" \
            --data-urlencode "size=${3:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/prompt/rule/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.name): \(.rule[:80])")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /user/prompt/rule/:id - Delete an agent rule
delete_agent_rule() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/user/prompt/rule/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Agent rule $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Categories ────────────────────────────────────────────────────────────────

# GET /user/category/list - Get agent category list (no auth required)
# Usage: list_agent_categories [page] [size] [languageCode]
list_agent_categories() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-50}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "languageCode=$3")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/category/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  [\(.id)] \(.name)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
