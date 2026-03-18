#!/bin/bash
# Points and rewards management functions for paip.ai
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

# ── Balance & Tasks ───────────────────────────────────────────────────────────

# GET /user/points/balance - Get current points balance
get_points_balance() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/points/balance" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Points Balance:\n  Task (free):  \(.taskBalance) (expires: \(.taskBalanceExpireAt))\n  Top-up:       \(.topUpBalance)\n  Total earned: \(.totalGetBalance)\n  Total spent:  \(.totalUseBalance)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/points/daily/task - Get daily task list
get_daily_tasks() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/points/daily/task" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Daily Tasks:"
        echo "$resp" | jq -r '.data[] | "  [\(.completedCount)/\(.dailyNumber)] \(.desc) (+\(.point) pts) | remaining: \(.remainingCount)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# GET /user/points/user/use/list - Points usage history
# Usage: get_points_history [page] [size]
get_points_history() {
    local params
    params=(--data-urlencode "page=${1:-1}" --data-urlencode "size=${2:-10}")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/points/user/use/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Total: \(.total)" , (.records[] | "  \(.createdAt) | \(.type) | \(if .point > 0 then "+" else "" end)\(.point) pts\(if .isFree then " (free)" else "" end)")'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Rules ─────────────────────────────────────────────────────────────────────

# GET /user/points/use/list - Get all points consumption rules
get_points_rules() {
    local resp
    resp=$(curl --max-time 300 -s "$BASE_URL/user/points/use/list" "${HEADERS[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Points Usage Rules:"
        echo "$resp" | jq -r '.data[] | "  [\(.code)] \(.desc) | cost: \(.point) pts | free/day: \(.dailyFreeNumber)\(if .dailyFreeIsUsed then " (used)" else "" end)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/points/buy/rule/number - Buy extra uses for a rule
# Usage: buy_rule_number "rule_code" <count>
buy_rule_number() {
    local payload
    payload=$(jq -n --arg ruleCode "$1" --argjson number "$2" \
        '{ruleCode: $ruleCode, number: $number}')
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/points/buy/rule/number" \
        "${HEADERS[@]}" -d "$payload")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Purchased $2 uses of '$1'. Remaining: $(echo "$resp" | jq -r '.data.count')"
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# ── Top-up ────────────────────────────────────────────────────────────────────

# GET /user/points/topup/list - Get available top-up packages
# Usage: get_topup_packages ["CN"|"US"] ["CNY"|"USD"]
get_topup_packages() {
    local params=()
    [[ -n "${1:-}" ]] && params+=(--data-urlencode "area=$1")
    [[ -n "${2:-}" ]] && params+=(--data-urlencode "currency=$2")
    local resp
    resp=$(curl --max-time 300 -s -G "$BASE_URL/user/points/topup/list" \
        "${HEADERS[@]}" "${params[@]}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "Top-up packages:"
        echo "$resp" | jq -r '.data[] | "  [\(.id)] \(.currency) \(.amount / 100) → \(.point) pts (+ \(.giftPoint) bonus)"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}

# POST /user/points/topup/order - Create a top-up order
# Usage: create_topup_order <package_id>
create_topup_order() {
    local resp
    resp=$(curl --max-time 300 -s -X POST "$BASE_URL/user/points/topup/order" \
        "${HEADERS[@]}" -d "{\"topUpId\": $1}")
    if [[ $(echo "$resp" | jq -r '.code') == "0" ]]; then
        echo "$resp" | jq -r '.data | "Order created:\n  No: \(.orderNo)\n  Amount: \(.currency) \(.amount / 100)\n  Points: \(.point) + \(.giftPoint) bonus"'
    else
        echo "Error: $(echo "$resp" | jq -r '.message')"; return 1
    fi
}
