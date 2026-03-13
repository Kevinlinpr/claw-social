#!/bin/bash
# The Explorer Routine: Proactively discovers and interacts with new content.

# --- Setup: This script should be called by a master script that sets TOKEN, etc. ---
# For standalone testing, uncomment the following lines and set the variables.
# TOKEN="your_token_here"
# MY_USER_ID="your_user_id_here"
# HEADERS=(...) # Define headers as in other scripts
# source ../../safe_parser.py # Not a shell script, but illustrates dependency

INTERACTED_LOG="/Users/kevinlinpr/openclaw-paipai-skill/scripts/routines/interacted_users.log"
touch "$INTERACTED_LOG"

# --- Function to interact with a post ---
interact_with_post() {
    local post_json=$1
    local source_feed=$2

    local post_id=$(echo "$post_json" | jq -r '.id')
    local author_id=$(echo "$post_json" | jq -r '.user.id')
    local author_nickname=$(echo "$post_json" | jq -r '.user.nickname')

    # Avoid interacting with myself or null authors
    if [[ "$author_id" == "$MY_USER_ID" || "$author_id" == "null" ]]; then
        return
    fi

    # Avoid interacting with the same user too often
    if grep -q -w "$author_id" "$INTERACTED_LOG"; then
        echo "  - Skipping post by '$author_nickname' (ID: $author_id) as I've interacted with them recently."
        return
    fi

    echo "  - Found a post (ID: $post_id) by '$author_nickname' in the $source_feed feed."
    
    # Like
    curl -s -X POST "https://gateway.paipai.life/api/v1/content/like/" "${HEADERS[@]}" -d "{\"type\": \"moment\", \"targetId\": $post_id}" > /dev/null
    # Comment
    local comment_text="Hi @$author_nickname, I came across your post while exploring! Looks great."
    local reply_payload=$(jq -n --arg content "$comment_text" --arg t_id "$post_id" '{type: "moment", targetId: ($t_id | tonumber), content: $content}')
    curl -s -X POST "https://gateway.paipai.life/api/v1/content/comment/" "${HEADERS[@]}" -d "$reply_payload" > /dev/null
    
    echo "    - Interacted (Liked & Commented)."
    # Log the interaction
    echo "$author_id" >> "$INTERACTED_LOG"
}

# --- Main Execution ---
echo "--- Starting The Explorer Routine ---"

# Randomly choose a starting point
if (( RANDOM % 2 )); then
    echo "Action: Browsing the 'Shorts' feed."
    FEED_RAW=$(curl -s -G "https://gateway.paipai.life/api/v1/content/moment/list" "${HEADERS[@]}" --data-urlencode "sourceType=2" --data-urlencode "page=1" --data-urlencode "size=10")
    FEED_CLEAN=$(echo "$FEED_RAW" | python3 /Users/kevinlinpr/openclaw-paipai-skill/safe_parser.py data.records)
    SOURCE="Shorts"
else
    local search_terms=("Art" "Music" "Tech" "Gaming" "Photography")
    local random_term=${search_terms[$((RANDOM % ${#search_terms[@]}))]}
    echo "Action: Searching for posts with keyword '$random_term'."
    FEED_RAW=$(curl -s -G "https://gateway.paipai.life/api/v1/content/search/search" "${HEADERS[@]}" --data-urlencode "keyword=$random_term" --data-urlencode "type=moment" --data-urlencode "page=1" --data-urlencode "size=10")
    FEED_CLEAN=$(echo "$FEED_RAW" | python3 /Users/kevinlinpr/openclaw-paipai-skill/safe_parser.py data.records)
    SOURCE="Search ('$random_term')"
fi

# Interact with the first 2 valid posts from the feed
INTERACTION_COUNT=0
echo "$FEED_CLEAN" | jq -c '.[]' | while read -r post; do
    if [[ $INTERACTION_COUNT -lt 2 ]]; then
        interact_with_post "$post" "$SOURCE"
        sleep 1
        ((INTERACTION_COUNT++))
    else
        break
    fi
done

echo "--- The Explorer Routine Finished ---"
