#!/bin/bash
# Favorites (collect) management functions for paip.ai
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

# ── Collect Items ─────────────────────────────────────────────────────────────

# GET /user/collect/list - List collected items
# Usage: list_collects [page] [size] [type: agent|video|moment] [userId]
list_collects() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-10}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "type=$3")
    [[ -n "${4:-}" ]] && params+=(--data-urlencode "userId=$4")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/collect/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] type:\(.type) targetId:\(.targetId)\(if .desc != "" then " — \(.desc)" else "" end)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/collect/add - Add a collect
# Usage: add_collect "agent|video|moment" <target_id> [0|1 isPrivate] ["desc"] [group_id]
add_collect() {
    local payload
    payload=$(jq -n \
        --arg type "$1" \
        --argjson targetId "$2" \
        --argjson isPrivate "${3:-0}" \
        --arg desc "${4:-}" \
        '{type: $type, targetId: $targetId, isPrivate: $isPrivate, desc: $desc}')
    [[ -n "${5:-}" ]] && payload=$(echo "$payload" | jq --argjson groupId "$5" '. + {groupId: $groupId}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/collect/add" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Collected $1 #$2."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /user/collect/edit - Edit a collect (desc, privacy, group)
# Usage: edit_collect <collect_id> [0|1 isPrivate] ["desc"] [group_id]
edit_collect() {
    local payload
    payload=$(jq -n \
        --argjson id "$1" \
        --argjson isPrivate "${2:-0}" \
        --arg desc "${3:-}" \
        '{id: $id, isPrivate: $isPrivate, desc: $desc}')
    [[ -n "${4:-}" ]] && payload=$(echo "$payload" | jq --argjson groupId "$4" '. + {groupId: $groupId}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/user/collect/edit" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Collect $1 updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /user/collect/del - Remove a collect by type + targetId
# Usage: delete_collect "agent|video|moment" <target_id>
delete_collect() {
    local payload
    payload=$(jq -n --arg type "$1" --argjson targetId "$2" \
        '{type: $type, targetId: $targetId}')
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/user/collect/del" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Collect ($1 #$2) removed."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Collect Groups ────────────────────────────────────────────────────────────

# GET /user/collect/group/list - List collect groups
# Usage: list_collect_groups [page] [size] [parent_id]
list_collect_groups() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-10}" \
            --data-urlencode "parentId=${3:-0}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/collect/group/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.name)\(if .isPrivate then " [private]" else "" end)\(if .hasCollect then " [has items]" else "" end)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/collect/group/add - Create a collect group
# Usage: add_collect_group "Name" [0|1 isPrivate] ["desc"] [parent_id]
add_collect_group() {
    local payload
    payload=$(jq -n \
        --arg name "$1" \
        --argjson isPrivate "${2:-0}" \
        --arg desc "${3:-}" \
        '{name: $name, isPrivate: $isPrivate, desc: $desc}')
    [[ -n "${4:-}" ]] && payload=$(echo "$payload" | jq --argjson parentId "$4" '. + {parentId: $parentId}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/collect/group/add" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Collect group '$1' created."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /user/collect/group/edit - Update a collect group
# Usage: edit_collect_group <group_id> "NewName" [0|1 isPrivate] ["desc"]
edit_collect_group() {
    local payload
    payload=$(jq -n \
        --argjson id "$1" \
        --arg name "$2" \
        --argjson isPrivate "${3:-0}" \
        --arg desc "${4:-}" \
        '{id: $id, name: $name, isPrivate: $isPrivate, desc: $desc}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/user/collect/group/edit" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Collect group $1 updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /user/collect/group/del/:id - Delete a collect group
delete_collect_group() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/user/collect/group/del/$1" \
        "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Collect group $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
