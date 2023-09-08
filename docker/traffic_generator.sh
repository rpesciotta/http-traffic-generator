#!/usr/bin/env bash

# Check if SERVER environment variable is set
if [ -z "$SERVER" ]; then
  echo "Error: SERVER environment variable not set. Make sure you set the \$SERVER env var on your kubernetes deployment or single docker container."
  exit -1
fi

# Check if MAX_SLEEP environment variable is set otherwise apply default value
if [ -z "$MAX_SLEEP" ]; then
  MAX_SLEEP=5000
fi

# Flag to track if /cart/addToCart was called
CART_ADDED=false

# Continuously send requests to the server
while true; do
    # Generate an ISO-8601 compliant timestamp in local time
    TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S%z")

    URL="http://${SERVER}"

    # If cart has been added, then we can choose either endpoint, otherwise only /cart/addToCart
    if $CART_ADDED; then
        ENDPOINT=$(( RANDOM % 2 ))
    else
        ENDPOINT=0
    fi

    # If the selected endpoint is 0, then it's /cart/addToCart, otherwise it's /checkout
    if [ $ENDPOINT -eq 0 ]; then
        CODE=$(( RANDOM % 6 + 1 ))
        URL+="/cart/addToCart?code=${CODE}"
        CART_ADDED=true
    else
        URL+="/checkout"
        CART_ADDED=false
    fi

    # Make the REST call using curl
    RESPONSE_DATA=$(curl -s -o /dev/null -w '%{http_code}:%{errormsg}' -X POST $URL 2>&1)
    RESPONSE_CODE=$(echo $RESPONSE_DATA | cut -d':' -f1)
    ERROR_MESSAGE=$(echo $RESPONSE_DATA | cut -d':' -f2-)

    # Log error messages if present, otherwise just output url and response code
    if [[ $ERROR_MESSAGE == *"Could not resolve host"* ]]; then
        LOG_MESSAGE="${ERROR_MESSAGE}"
    else
        LOG_MESSAGE="[${RESPONSE_CODE}] ${URL}"
    fi

    echo "${TIMESTAMP} - ${LOG_MESSAGE}"

    # Sleep for a random time in fractional seconds
    SLEEP_TIME_SEC=$(echo "$(( RANDOM % MAX_SLEEP + 10 ))e-3" | awk '{printf "%.3f\n", $1}')
    sleep $SLEEP_TIME_SEC
done

