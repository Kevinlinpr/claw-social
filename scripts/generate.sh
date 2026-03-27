#!/bin/bash
# AI generation functions for paip.ai (/agent/generate/* endpoints)
#
# Requires environment variables:
# - TOKEN: authentication token
# - USER_ID: current user ID (used in some upload calls)

BASE_URL="https://gateway.paipai.life/api/v1"

HEADERS_JSON=(
  "-H" "Authorization: Bearer $TOKEN"
  "-H" "X-Requires-Auth: true"
  "-H" "X-DEVICE-ID: iOS"
  "-H" "X-User-Location: $(echo -n "" | base64)"
  "-H" "X-Response-Language: zh-cn"
  "-H" "X-App-Version: 1.0"
  "-H" "X-App-Build: 1"
  "-H" "Content-Type: application/json"
)

HEADERS_FORM=(
  "-H" "Authorization: Bearer $TOKEN"
  "-H" "X-Requires-Auth: true"
  "-H" "X-DEVICE-ID: iOS"
  "-H" "X-User-Location: $(echo -n "" | base64)"
  "-H" "X-Response-Language: zh-cn"
  "-H" "X-App-Version: 1.0"
  "-H" "X-App-Build: 1"
)

# ── Text ─────────────────────────────────────────────────────────────────────

# POST /agent/generate/beautify/text - AI-beautify a piece of text
# Usage: beautify_text "content" "scene"
beautify_text() {
    local payload
    payload=$(jq -n --arg content "$1" --arg scene "${2:-general}" \
        '{content: $content, scene: $scene}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/beautify/text" \
        "${HEADERS_JSON[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.text'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Image Generation ──────────────────────────────────────────────────────────

# POST /agent/generate/text/to-image - Generate image from text
# Usage: text_to_image "prompt text" "scene"
text_to_image() {
    local payload
    payload=$(jq -n --arg content "$1" --arg scene "${2:-general}" \
        '{content: $content, scene: $scene}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/text/to-image" \
        "${HEADERS_JSON[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.url'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/generate/image/to-text - Generate text description from an image file
# Usage: image_to_text "/path/to/image.jpg" "scene" ["extra description"]
image_to_text() {
    local file=$1; local scene=${2:-general}; local desc=${3:-""}
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/image/to-text" \
        "${HEADERS_FORM[@]}" \
        -F "scene=$scene" \
        -F "files=@$file" \
        -F "desc=$desc")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.text'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/generate/image/to-image - Generate a new image from an input image
# Usage: image_to_image "/path/to/image.jpg" "scene" ["description"]
image_to_image() {
    local file=$1; local scene=${2:-general}; local desc=${3:-""}
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/image/to-image" \
        "${HEADERS_FORM[@]}" \
        -F "scene=$scene" \
        -F "files=@$file" \
        -F "desc=$desc")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.url'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Chat Assistance ───────────────────────────────────────────────────────────

# POST /agent/generate/chat/summary - Summarize chat history
# Usage: chat_summary "roomImId" <historyCount> "zh|en|ja"
chat_summary() {
    local payload
    payload=$(jq -n \
        --arg roomImId "$1" \
        --argjson historyCount "$2" \
        --arg language "${3:-zh}" \
        '{roomImId: $roomImId, historyCount: $historyCount, language: $language}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/chat/summary" \
        "${HEADERS_JSON[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.text'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/generate/generate/chat/options - Generate quick-reply suggestions
# Usage: generate_chat_options <room_id> "current chat content"
generate_chat_options() {
    local payload
    payload=$(jq -n --argjson roomId "$1" --arg content "$2" \
        '{roomId: $roomId, content: $content}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/generate/chat/options" \
        "${HEADERS_JSON[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.options[]'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Agent Generation ──────────────────────────────────────────────────────────

# POST /agent/generate/generate-agent - Generate agent name & description from text
# Usage: generate_agent_info "description of the desired agent"
generate_agent_info() {
    local payload
    payload=$(jq -n --arg content "${1:-}" '{content: $content}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/generate-agent" \
        "${HEADERS_JSON[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq '.data | {title, desc}'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /agent/generate/generate-agent-style - List available agent image styles
get_agent_image_styles() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/agent/generate/generate-agent-style" \
        "${HEADERS_JSON[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.records[] | "  \(.style): \(.name) — \(.desc)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/generate/generate-agent-images - Generate agent avatar images
# Usage: generate_agent_images "desc" "style" ["/path/to/ref.jpg"]
generate_agent_images() {
    local desc=$1; local style=$2; local ref_file=${3:-""}
    local resp
    if [[ -n "$ref_file" ]]; then
        resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/generate-agent-images" \
            "${HEADERS_FORM[@]}" \
            -F "desc=$desc" \
            -F "style=$style" \
            -F "file=@$ref_file")
    else
        resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/generate-agent-images" \
            "${HEADERS_FORM[@]}" \
            -F "desc=$desc" \
            -F "style=$style")
    fi
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.files[]'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /agent/generate/photo/same-style - Generate same-style photo
# Usage: photo_same_style "background_url" ["/path/to/ref.jpg"]
photo_same_style() {
    local background=$1; local ref_file=${2:-""}
    local resp
    if [[ -n "$ref_file" ]]; then
        resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/photo/same-style" \
            "${HEADERS_FORM[@]}" \
            -F "background=$background" \
            -F "file=@$ref_file")
    else
        resp=$(curl --max-time 300 -s -X POST "$BASE_URL/agent/generate/photo/same-style" \
            "${HEADERS_FORM[@]}" \
            -F "background=$background")
    fi
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data.address'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
