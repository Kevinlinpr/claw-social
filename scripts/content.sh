#!/bin/bash
# Content (moments, likes, comments, videos) functions for paip.ai
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

# POST /content/common/upload - Upload a media file, returns URL
# Usage: upload_content_file "/path/to/file.jpg"
upload_content_file() {
    local resp
    resp=$(curl --max-time 600 -s -X POST "$BASE_URL/content/common/upload" \
        "-H" "Authorization: Bearer $TOKEN" \
        "-H" "X-DEVICE-ID: iOS" \
        "-H" "X-Response-Language: zh-cn" \
        -F "file=@$1" \
        -F "type=content" \
        -F "path=content" \
        -F "id=${USER_ID:-0}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.path'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Moments ───────────────────────────────────────────────────────────────────

# POST /content/moment/create - Publish a moment (upload first, then create)
# Usage: post_moment "caption" "/path/to/media.jpg" "image|video"
post_moment() {
    local content_text=$1; local media_file_path=$2; local media_type=$3

    echo "Uploading $media_type..."
    local media_url
    media_url=$(upload_content_file "$media_file_path") || return 1
    echo "Uploaded: $media_url"

    local payload
    payload=$(jq -n \
        --arg content "$content_text" \
        --arg media_url "$media_url" \
        --arg type "$media_type" \
        '{content: $content, publicScope: "PUBLIC", isOpenLocation: false,
          attach: [{type: $type, source: "upload", address: $media_url, sort: 0}]}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/content/moment/create" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Moment published. ID: $(echo "$resp" | jq -r '.data.id')"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /content/moment/list - List moments
# Usage: list_moments [page] [size] [userId] [isFollow: true|false]
list_moments() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-10}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "userId=$3")
    [[ -n "${4:-}" ]] && params+=(--data-urlencode "IsFollow=$4")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/content/moment/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.user.nickname): \(.content[:60]) | ❤\(.likeCount) 💬\(.commentCount)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /content/moment/recomment - Get recommended moments
# Usage: get_recommended_moments [page] [size]
get_recommended_moments() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/content/moment/recomment" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  [\(.id)] \(.user.nickname): \(.content[:60]) | ❤\(.likeCount)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /content/moment/mix/recomment - Get mixed recommend (moments + agents)
# Usage: get_mix_recommend [page] [size]
get_mix_recommend() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/content/moment/mix/recomment" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  [\(.type)] \(.data | .id)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /content/moment/:id - Get a single moment
get_moment() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/content/moment/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {id, content, likeCount, commentCount, collectCount, publicScope, createdAt}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /content/moment/public/mode - Change moment visibility
# Usage: change_moment_visibility <moment_id> "PUBLIC|PRIVATE|FRIEND"
change_moment_visibility() {
    local payload
    payload=$(jq -n --argjson id "$1" --arg publicScope "$2" \
        '{id: $id, publicScope: $publicScope}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/content/moment/public/mode" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Moment $1 visibility set to '$2'."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /content/moment/:id - Delete a moment
delete_moment() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/content/moment/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Moment $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Likes ─────────────────────────────────────────────────────────────────────

# POST /content/like/ - Like a moment, video, post, or comment
# Usage: like_content "moment|video|posts|comment" <target_id>
like_content() {
    local payload
    payload=$(jq -n --arg type "$1" --argjson targetId "$2" \
        '{type: $type, targetId: $targetId}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/content/like/" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Liked $1 #$2."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /content/like/del - Unlike
# Usage: unlike_content "moment|video|posts|comment" <target_id>
unlike_content() {
    local payload
    payload=$(jq -n --arg type "$1" --argjson targetId "$2" \
        '{type: $type, targetId: $targetId}')
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/content/like/del" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Unliked $1 #$2."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Comments ──────────────────────────────────────────────────────────────────

# GET /content/comment/list - Get comment list
# Usage: list_comments "moment|video|posts" <target_id> [page] [size]
list_comments() {
    local params
    params=(--data-urlencode "type=$1" \
            --data-urlencode "targetId=$2" \
            --data-urlencode "page=${3:-1}" \
            --data-urlencode "size=${4:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/content/comment/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.user.nickname): \(.content) | ❤\(.likeCount) 💬\(.replyCount)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /content/comment/ - Post a comment or reply
# Usage: post_comment "moment|video|posts" <target_id> "content" [parent_id]
post_comment() {
    local payload
    payload=$(jq -n \
        --arg type "$1" \
        --argjson targetId "$2" \
        --arg content "$3" \
        '{type: $type, targetId: $targetId, content: $content}')
    [[ -n "${4:-}" ]] && payload=$(echo "$payload" | jq --argjson parentId "$4" '. + {parentId: $parentId}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/content/comment/" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Comment posted. ID: $(echo "$resp" | jq -r '.data.id')"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# Alias kept for compatibility
reply_to_comment() { post_comment "moment" "$1" "$3" "$2"; }

# DELETE /content/comment/:id - Delete a comment
delete_comment() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/content/comment/$1" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Comment $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Videos ────────────────────────────────────────────────────────────────────

# POST /content/video/create - Publish a video (upload first, then create)
# Usage: create_video "Title" "/path/to/video.mp4" "PUBLIC|PRIVATE|FRIEND"
create_video() {
    local title=$1; local video_file=$2; local scope=${3:-"PUBLIC"}

    echo "Uploading video..."
    local video_url
    video_url=$(upload_content_file "$video_file") || return 1
    echo "Uploaded: $video_url"

    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg videoPath "$video_url" \
        --arg publicScope "$scope" \
        '{title: $title, videoPath: $videoPath, publicScope: $publicScope, isCompress: false}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/content/video/create" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Video '$title' published."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /content/video/list - List videos
# Usage: list_videos [page] [size] [userId]
list_videos() {
    local params
    params=(--data-urlencode "page=${1:-1}" \
            --data-urlencode "size=${2:-10}")
    [[ -n "${3:-}" ]] && params+=(--data-urlencode "userId=$3")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/content/video/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  [\(.id)] \(.title) | ❤\(.likeCount) 💬\(.commentCount) | \(.createdAt)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# PUT /content/video/update - Update video info
# Usage: update_video <video_id> "NewTitle" "PUBLIC|PRIVATE|FRIEND"
update_video() {
    local payload
    payload=$(jq -n \
        --argjson id "$1" \
        --arg title "$2" \
        --arg publicScope "${3:-PUBLIC}" \
        '{id: $id, title: $title, publicScope: $publicScope}')
    local resp
    resp=$(curl --max-time 300 -s -X PUT "$BASE_URL/content/video/update" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Video $1 updated."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# DELETE /content/video/delete - Delete a video
delete_video() {
    local resp
    resp=$(curl --max-time 300 -s -X DELETE "$BASE_URL/content/video/delete" \
        "${HEADERS[@]}" -d "{\"id\": $1}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Video $1 deleted."
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Search ────────────────────────────────────────────────────────────────────

# GET /content/search/search - Global search
# Usage: search_content "keyword" "moment|video|user|prompt|room" [page] [size]
search_content() {
    local params
    params=(--data-urlencode "keyword=$1" \
            --data-urlencode "type=$2" \
            --data-urlencode "page=${3:-1}" \
            --data-urlencode "size=${4:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/content/search/search" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '"Total: \(.data.total)"'
        echo "$resp" | jq '.data.records // []'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
