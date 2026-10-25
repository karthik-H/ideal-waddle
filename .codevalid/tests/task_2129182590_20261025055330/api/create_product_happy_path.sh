#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2129182590_20261025055330/api/_infra.sh

# Given
cv_step Given "a signed-in user and a unique product payload" $LINENO
SUFFIX=$(cv_suffix)
EMAIL="creator_${SUFFIX}@example.com"
PASSWORD="Passw0rd-${SUFFIX: -6}"
cv_prereq "register user $EMAIL" $LINENO
cv_register_user "$EMAIL" "$PASSWORD" $LINENO
TOKEN="$CV_TOKEN"
NAME="Widget ${SUFFIX}"
DESC="A sturdy test widget ${SUFFIX}"
PRICE=19.99
CODE="WID-${SUFFIX}"
BODY=$(cv_product_json "$NAME" "$DESC" "$PRICE" "$CODE")

# When
cv_step When "POST /products with a bearer token" $LINENO
cv_http POST /products "$BODY" -H "Authorization: Bearer $TOKEN"
CREATE_STATUS="$CV_HTTP_STATUS"
CREATE_BODY="$CV_HTTP_BODY"

# Then
cv_step Then "product is created and browseable in list and by id" $LINENO
[ "$CREATE_STATUS" = "201" ] || cv_fail "expected HTTP 201 from POST /products got $CREATE_STATUS" $LINENO
PID=$(printf '%s' "$CREATE_BODY" | jq -r '.id // empty')
[ -n "$PID" ] || cv_fail "expected product id in create response got none" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r '.name')" = "$NAME" ] || cv_fail "expected name $NAME in create response got $(printf '%s' "$CREATE_BODY" | jq -r '.name')" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r '.description')" = "$DESC" ] || cv_fail "expected description $DESC in create response" $LINENO
printf '%s' "$CREATE_BODY" | jq -e --argjson p "$PRICE" '.price == $p' >/dev/null || cv_fail "expected price $PRICE in create response got $(printf '%s' "$CREATE_BODY" | jq -c '.price')" $LINENO
[ "$(printf '%s' "$CREATE_BODY" | jq -r '.productCode')" = "$CODE" ] || cv_fail "expected productCode $CODE in create response" $LINENO

cv_http GET /products 200
printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$PID" --arg n "$NAME" --arg d "$DESC" --argjson p "$PRICE" --arg c "$CODE" \
  '[.products[] | select(.id==$id and .name==$n and .description==$d and .price==$p and .productCode==$c)] | length == 1' >/dev/null \
  || cv_fail "expected product $PID with matching fields in GET /products listing" $LINENO

cv_http GET "/products/$PID" 200
printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$PID" --arg n "$NAME" --arg d "$DESC" --argjson p "$PRICE" --arg c "$CODE" \
  '.id==$id and .name==$n and .description==$d and .price==$p and .productCode==$c' >/dev/null \
  || cv_fail "expected GET /products/$PID to return the created product fields got $CV_HTTP_BODY" $LINENO

# Cleanup
cv_step Cleanup "nothing to delete: in-memory store, no delete route; data is uniquely suffixed" $LINENO
echo "created user $EMAIL and product $CODE (unique, left in in-memory store)"

echo "CODEVALID_TEST_ASSERTION_OK:create_product_happy_path"
