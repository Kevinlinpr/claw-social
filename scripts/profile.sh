#!/bin/bash
# User profile, tags, social graph, and account management for paip.ai
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

# ── User Info ─────────────────────────────────────────────────────────────────

# GET /user/current/user - Get current user info
get_current_user() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/current/user" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, nickname, username, bio, gender, mbti, constellation, imId, fansCount, followCount, tagStatus}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/info/:id - Get user by numeric ID
get_user() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/info/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, nickname, bio, imId, fansCount, followCount, isFollow}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/info/imid/:imId - Get user by IM ID
get_user_by_imid() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/info/imid/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, nickname, bio, imId, fansCount, followCount}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/list - List users with optional filters
# Usage: list_users [page] [size] [nickname] [roomId]
list_users() {
    local params
    params=(--data-urlencode "page=${1:-1}" --data-urlencode "size=${2:-10}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "nickname=$3")
    [[ -n "${4:-}" ]] && params+=(--data-urlencode "roomId=$4")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.nickname) | \(.username)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Upload ────────────────────────────────────────────────────────────────────

# POST /user/common/upload/file - Upload user or prompt file, returns URL
# Usage: upload_user_file "/path/file.jpg" "user|prompt" [id]
# REQUIRED before setting avatar/background on user or agent profiles.
upload_user_file() {
    local resp
    resp=$(curl --max-time 600 -s -X POST "$BASE_URL/user/common/upload/file" \
        "-H" "Authorization: Bearer $TOKEN" \
        "-H" "X-DEVICE-ID: iOS" \
        "-H" "X-Response-Language: zh-cn" \
        -F "file=@$1" \
        -F "type=${2:-user}" \
        -F "path=avatar" \
        -F "id=${3:-${USER_ID:-0}}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.path'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Profile Management ────────────────────────────────────────────────────────

# PUT /user/info/update - Update user profile
# Usage: update_profile "Nickname" ["Bio"] [gender: 1|2|3] ["const"] ["mbti"] ["avatar_path_or_url"] ["bg_path_or_url"]
# avatar/background: local file path → auto-uploaded via /user/common/upload/file; URL → used as-is
update_profile() {
    local nickname=$1 bio=${2:-} gender=${3:-3} constellation=${4:-} mbti=${5:-}
    local avatar_input=${6:-} bg_input=${7:-}
    local avatar="" background=""

    if [[ -n "$avatar_input" ]]; then
        if [[ -f "$avatar_input" ]]; then
            echo "Uploading avatar..."
            avatar=$(upload_user_file "$avatar_input" "user" "${USER_ID:-0}") || return 1
        else
            avatar=$avatar_input
        fi
    fi
    if [[ -n "$bg_input" ]]; then
        if [[ -f "$bg_input" ]]; then
            echo "Uploading background..."
            background=$(upload_user_file "$bg_input" "user" "${USER_ID:-0}") || return 1
        else
            background=$bg_input
        fi
    fi

    local payload
    payload=$(jq -n \
        --arg nickname "$nickname" --arg bio "$bio" \
        --argjson gender "$gender" \
        --arg constellation "$constellation" --arg mbti "$mbti" \
        --arg avatar "$avatar" --arg background "$background" \
        '{nickname: $nickname, bio: $bio, gender: $gender, constellation: $constellation, mbti: $mbti}
          | if $avatar != "" then . + {avatar: $avatar} else . end
          | if $background != "" then . + {backgroud: $background} else . end')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/user/info/update" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Profile updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /user/change/password - Change password
# Usage: change_password "old" "new" "confirm"
change_password() {
    local payload
    payload=$(jq -n \
        --arg oldPassword "$1" --arg newPassword "$2" --arg confirmPassword "$3" \
        '{oldPassword: $oldPassword, newPassword: $newPassword, confirmPassword: $confirmPassword}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/user/change/password" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Password changed."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/logout - Logout (invalidate token)
logout() {
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/logout" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Logged out."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── User Tags ─────────────────────────────────────────────────────────────────

# POST /user/tag/status - Set tag collection status (1=incomplete, 2=complete)
set_tag_status() {
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/tag/status" \
        "${HEADERS[@]}" -d "{\"status\": $1}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Tag status set to $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/tags/save - Save (overwrite) all user tags
# Usage: save_user_tags 101 102 103
save_user_tags() {
    local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/tags/save" \
        "${HEADERS[@]}" -d "{\"tagIds\": $ids_json}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Tags saved: $*"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/tags/add - Incrementally add tags
# Usage: add_user_tags 101 102
add_user_tags() {
    local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/tags/add" \
        "${HEADERS[@]}" -d "{\"tagIds\": $ids_json}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Tags added: $*"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/tags/delete - Remove specific tags
# Usage: delete_user_tags 101 102
delete_user_tags() {
    local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/tags/delete" \
        "${HEADERS[@]}" -d "{\"tagIds\": $ids_json}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Tags removed: $*"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/tags/list - Get current user's tags
# Usage: get_user_tags [categoryId]
get_user_tags() {
    local params=()
    [[ -n "${1:-}" ]] && params+=(--data-urlencode "categoryId=$1")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/tags/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.tags[] | "  [\(.id)] \(.name) (\(.category))"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/tags/category/list - Get tag categories
# Usage: get_tag_categories [page] [size] [type: preferred|core]
get_tag_categories() {
    local params
    params=(--data-urlencode "page=${1:-1}" --data-urlencode "size=${2:-50}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "type=$3")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/tags/category/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  [\(.id)] \(.name) (\(.type))"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/tag/list - Get all available tags
# Usage: get_tag_list [page] [size] [categoryId] [name]
get_tag_list() {
    local params
    params=(--data-urlencode "page=${1:-1}" --data-urlencode "size=${2:-20}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "categoryId=$3")
    [[ -n "${4:-}" ]] && params+=(--data-urlencode "name=$4")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/tag/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.name)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/match/tags - Match users/agents by tags
# Usage: match_tags "both|user|prompt" "both|user|prompt" [gender: male|female|all]
match_tags() {
    local payload
    payload=$(jq -n \
        --arg matchType "${1:-both}" \
        --arg matchTarget "${2:-both}" \
        --arg gender "${3:-all}" \
        --argjson preferredMode 2 \
        --argjson coreMix 0.5 \
        '{matchType: $matchType, matchTarget: $matchTarget, gender: $gender,
          preferredMode: $preferredMode, coreMix: $coreMix}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/match/tags" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Matched users:"
        echo "$resp" | jq -r '.data.users[]? | "  [\(.id)] \(.nickname)"'
        echo "Matched agents:"
        echo "$resp" | jq -r '.data.prompts[]? | "  [\(.id)] \(.name)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Social Graph ──────────────────────────────────────────────────────────────

# POST /user/follow/user - Follow a user or agent
# Usage: follow_user <id> "user|agent"
follow_user() {
    local payload
    payload=$(jq -n --argjson flowUserId "$1" --arg followUserType "${2:-user}" \
        '{flowUserId: $flowUserId, followUserType: $followUserType}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/follow/user" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Followed $2 $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/unfollow/user - Unfollow a user or agent
# Usage: unfollow_user <id> "user|agent"
unfollow_user() {
    local payload
    payload=$(jq -n --argjson flowUserId "$1" --arg followUserType "${2:-user}" \
        '{flowUserId: $flowUserId, followUserType: $followUserType}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/unfollow/user" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Unfollowed $2 $1."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/follow/list - Get following list
# Usage: get_following <user_id> [page] [size]
get_following() {
    local params
    params=(--data-urlencode "userId=$1" \
            --data-urlencode "page=${2:-1}" \
            --data-urlencode "size=${3:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/follow/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Following (\(.total)):" , (.records[] | "  [\(.id)] \(.nickname)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/fans/list - Get fans list
# Usage: get_fans <user_id> [page] [size]
get_fans() {
    local params
    params=(--data-urlencode "userId=$1" \
            --data-urlencode "page=${2:-1}" \
            --data-urlencode "size=${3:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/fans/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Fans (\(.total)):" , (.records[] | "  [\(.id)] \(.nickname)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Blacklist ─────────────────────────────────────────────────────────────────

# GET /user/black/list - Get blacklist
get_blacklist() {
    local params
    params=(--data-urlencode "page=${1:-1}" --data-urlencode "size=${2:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/black/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Blocked (\(.total)):" , (.records[] | "  [\(.id)] \(.nickname) (\(.type))")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/black/add - Add to blacklist
# Usage: add_to_blacklist <id> "user|agent"
add_to_blacklist() {
    local payload
    payload=$(jq -n --argjson blackUserId "$1" --arg blackUserType "${2:-user}" \
        '{blackUserId: $blackUserId, blackUserType: $blackUserType}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/black/add" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$2 $1 blocked."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /user/black/del - Remove from blacklist by record IDs
# Usage: remove_from_blacklist <record_id1> [record_id2 ...]
remove_from_blacklist() {
    local ids_json; ids_json=$(printf '%s\n' "$@" | jq -R 'tonumber' | jq -s '.')
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/user/black/del" \
        "${HEADERS[@]}" -d "{\"ids\": $ids_json}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Removed from blacklist: $*"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Nearby / Same City ────────────────────────────────────────────────────────

# GET /user/recommend/same/city - Same-city recommendation
# Requires X-User-Location header with Base64(longitude|latitude|address)
# Usage: same_city_recommend [matchType: user|prompt|moment] [gender: 1|2] [distance_km] [isMatch: true|false]
same_city_recommend() {
    local params=()
    [[ -n "${1:-}" ]] && params+=(--data-urlencode "matchType=$1")
    [[ -n "${2:-}" ]] && params+=(--data-urlencode "gender=$2")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "distance=$3")
    [[ -n "${4:-}" ]] && params+=(--data-urlencode "isMatch=$4")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/recommend/same/city" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.type)] [\(.id)] \(.nickname) | dist: \(.dist)km")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
