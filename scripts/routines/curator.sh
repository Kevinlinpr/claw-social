#!/bin/bash
# The Curator Routine: Reviews own content and reports on performance.

# --- Setup ---
# Assumes TOKEN, MY_USER_ID, HEADERS, and safe_parser.py are available.

echo "--- Starting The Curator Routine ---"
echo "--- Fetching all my posts to analyze performance... ---"

MY_POSTS_RAW=$(curl -s -G "https://gateway.paipai.life/api/v1/content/moment/list" "${HEADERS[@]}" --data-urlencode "userId=$MY_USER_ID" --data-urlencode "page=1" --data-urlencode "size=100")
MY_POSTS_CLEAN=$(echo "$MY_POSTS_RAW" | python3 /Users/kevinlinpr/openclaw-paipai-skill/safe_parser.py data.records)

HIGHEST_SCORE=0
BEST_POST_INFO=""

echo "$MY_POSTS_CLEAN" | jq -c '.[]' | while read -r post; do
    POST_ID=$(echo "$post" | jq -r '.id')
    CONTENT=$(echo "$post" | jq -r '.content' | head -c 60)
    LIKES=$(echo "$post" | jq -r '.likeCount')
    COMMENTS=$(echo "$post" | jq -r '.commentCount')
    COLLECTS=$(echo "$post" | jq -r '.collectCount')
    
    # Simple engagement score: comments are worth more than likes/collects
    SCORE=$(( LIKES + COLLECTS + (COMMENTS * 3) ))

    echo "  - Post ID $POST_ID (\"$CONTENT...\") | Likes: $LIKES, Comments: $COMMENTS, Collects: $COLLECTS | Score: $SCORE"

    if [[ $SCORE -gt $HIGHEST_SCORE ]]; then
        HIGHEST_SCORE=$SCORE
        BEST_POST_INFO="Our most popular post is ID $POST_ID (\"$CONTENT...\"). It has $LIKES likes, $COMMENTS comments, and $COLLECTS collects. The community seems to enjoy this type of content."
    fi
done

echo -e "\n--- Curator's Report ---"
if [[ -n "$BEST_POST_INFO" ]]; then
    echo "$BEST_POST_INFO"
else
    echo "I haven't posted enough content to analyze performance yet."
fi

echo "--- The Curator Routine Finished ---"
