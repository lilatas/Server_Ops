#!/bin/bash
#: Title        : Traffic driving
#: Date         : 20251216
#: Author       : lilatas
#: Version      : 0.1
#: Description  : We chose MSA as the architecture of the project.
#                 Because each structure is segmented, it becomes difficult to induce traffic.
#                 These traffic driving module can simultaneously load our individually developed systems.
#                 The traffic driving module follows the customer journey in the open market.


# Pls modify the values ​​to suit your environment.
LB_WEB_IP="http://localhosting"      # WEB load balancer IP or domain
CONCURRENCY=50                       # Number of virtual users (processes) running simultaneously
LOOP_COUNT=200                       # The number of times each virtual user will repeat the scenario
REQUEST_DELAY=0.1                    # Delay (in seconds) between each request
LOG_DIR="./traffic_logs"             # Log file storage directory

# A list of product IDs to use in the simulation (similar to real DB IDs)
ITEM_IDS=(1001 1002 1003 1004 1005 1006 1007 1008 1009 1010)
# -----------------------------------------------------------

mkdir -p $LOG_DIR
echo "=================================================="
echo " Start shopping mall traffic scenario simulation  "
echo "   Target LB: $LB_WEB_IP"
echo "   Number of concurrent users: $CONCURRENCY"
echo "=================================================="

run_scenario() {
    local USER_ID=$1
    local LOG_FILE="$LOG_DIR/user_${USER_ID}.log"
    local COOKIE_FILE="/tmp/cookie_session_${USER_ID}_$$.txt"       # process cookie file
    
    echo "[User $USER_ID] simulation activate. Log file: $LOG_FILE" > $LOG_FILE

    for i in $(seq 1 $LOOP_COUNT); do
        echo -e "\n--- [User $USER_ID, Loop $i] ---" >> $LOG_FILE
        
        # ----------------------------------------------------
        # item Search
        # ----------------------------------------------------
        SEARCH_URL="$LB_WEB_IP/search?q=latest_item&page=1"
        curl_request "1. item Search" "$SEARCH_URL" "GET" "" "200" $COOKIE_FILE $LOG_FILE

        if [ $? -ne 0 ]; then continue; fi
        sleep $REQUEST_DELAY

        # ----------------------------------------------------
        # item Search - Cart
        # ----------------------------------------------------
        
        # ramdomly select 1~3
        ITEM_COUNT=$(( 1 + RANDOM % 3 ))
        CART_DATA=""
        
        # Create POST data by selecting $ITEM_COUNT from the product ID list without duplication
        local SELECTED_INDICES=()
        while [ ${#SELECTED_INDICES[@]} -lt $ITEM_COUNT ]; do
            # Select a random index within the size of the product ID array.
            RAND_INDEX=$(( RANDOM % ${#ITEM_IDS[@]} ))
            # Duplicate check
            if ! [[ " ${SELECTED_INDICES[@]} " =~ " ${RAND_INDEX} " ]]; then
                SELECTED_INDICES+=($RAND_INDEX)
            fi
        done

        # Construct CART_DATA using selected indexes
        for index in "${SELECTED_INDICES[@]}"; do
            ITEM_ID=${ITEM_IDS[$index]}
            # Each product is randomly set to contain between 1 and 3.
            QUANTITY=$(( 1 + RANDOM % 3 ))
            
            if [ -z "$CART_DATA" ]; then
                CART_DATA="itemId=${ITEM_ID}&quantity=${QUANTITY}"
            else
                CART_DATA+="&itemId=${ITEM_ID}&quantity=${QUANTITY}"
            fi
        done
        
        CART_ADD_URL="$LB_WEB_IP/cart/add"
        echo "  [User $USER_ID] Cart $ITEM_COUNT item get. Data: $CART_DATA" >> $LOG_FILE

        curl_request "2. Cart ($ITEM_COUNT개)" "$CART_ADD_URL" "POST" "$CART_DATA" "200" $COOKIE_FILE $LOG_FILE

        if [ $? -ne 0 ]; then continue; fi
        sleep $REQUEST_DELAY

        # ----------------------------------------------------
        # item Search - Cart - Payment
        # ----------------------------------------------------
        ORDER_INFO_URL="$LB_WEB_IP/checkout/info"
        curl_request "3. Payment" "$ORDER_INFO_URL" "GET" "" "200" $COOKIE_FILE $LOG_FILE

        if [ $? -ne 0 ]; then continue; fi
        sleep $REQUEST_DELAY

        # ----------------------------------------------------
        # item Search - Cart - Payment - Delivery
        # ----------------------------------------------------
        SHIPPING_DATA="address=Seoul&payment=creditcard&cartToken=ABC123XYZ"
        SHIPPING_URL="$LB_WEB_IP/checkout/finalize"
        curl_request "4. Delivery" "$SHIPPING_URL" "POST" "$SHIPPING_DATA" "200" $COOKIE_FILE $LOG_FILE
        # ----------------------------------------------------
        
        sleep $REQUEST_DELAY
    done
    
    rm -f $COOKIE_FILE
}

# --- 3. curl 요청 공통 함수 (이전과 동일) ---
curl_request() {
    local STEP_NAME=$1
    local URL=$2
    local METHOD=$3
    local DATA=$4
    local EXPECTED_STATUS=$5
    local COOKIE_FILE=$6
    local LOG_FILE=$7

    # curl : Output HTTP status code and total response time separated by '|'
    # %{http_code} : HTTP response codes (200, 404, etc.)
    # %{time_total} : Total request/response processing time (in seconds)
    CURL_CMD="curl -s -o /dev/null -w '%{http_code}|%{time_total}'"
    CURL_CMD+=" -c $COOKIE_FILE -b $COOKIE_FILE"
    CURL_CMD+=" -X $METHOD"
    
    if [ "$METHOD" = "POST" ]; then
        CURL_CMD+=" -H 'Content-Type: application/x-www-form-urlencoded'"
        CURL_CMD+=" -d '$DATA'"
    fi
    CURL_CMD+=" '$URL'"
    
    # Execute commands and obtain results (예: 200|0.123456)
    RESPONSE=$(eval $CURL_CMD)
    
    # Separate the results into HTTP_STATUS and TOTAL_TIME
    HTTP_STATUS=$(echo "$RESPONSE" | awk -F'|' '{print $1}')
    TOTAL_TIME=$(echo "$RESPONSE" | awk -F'|' '{print $2}')
    
    # Log files: step name, URL, HTTP status code, response time
    echo "  [$STEP_NAME] $METHOD $URL -> HTTP $HTTP_STATUS, Time: ${TOTAL_TIME}s" >> $LOG_FILE

    if [ "$HTTP_STATUS" != "$EXPECTED_STATUS" ]; then
        echo "failure : $STEP_NAME unexpectable HTTP status code ($HTTP_STATUS) occur." >> $LOG_FILE
        return 1
    fi
    return 0
}

# --------- Main Looping ---------
for user in $(seq 1 $CONCURRENCY); do
    run_scenario $user &
done

wait

echo "=================================================="
echo "✅ simulation complete. log file: $LOG_DIR"
echo "=================================================="
