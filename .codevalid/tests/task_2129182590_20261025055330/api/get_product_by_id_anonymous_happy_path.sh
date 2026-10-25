#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2129182590_20261025055330/api/_infra.sh

# Given
cv_step Given "a product added by a signed-in user" $LINENO
SUFFIX=$(cv_suffix)
cv_prereq "register seller" $LINENO
cv_register_user "seller_${SUFFIX}@example.com" "Passw0rd-${SUFFIX: -6}" $LINENO
NAME="Backpack ${SUFFIX}"
DESC="Waterproof backpack ${SUFFIX}"
PRICE=59.95
CODE="BAG_${SUFFIX}"
cv_prereq "create product $CODE" $LINENO
cv_create_product "$CV_TOKEN" "$NAME" "$DESC" "$PRICE" "$CODE" $LINENO
PID="$CV_PRODUCT_ID"

# When
cv_step When "anonymous GET /products/{id}" $LINENO
cv_http GET "/products/$PID"

# Then
cv_step Then "200 with the product's name, description, price and code" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected HTTP 200 from GET /products/$PID got $CV_HTTP_STATUS" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.id')" = "$PID" ] || cv_fail "expected id $PID got $(printf '%s' "$CV_HTTP_BODY" | jq -r '.id')" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.name')" = "$NAME" ] || cv_fail "expected name $NAME got $(printf '%s' "$CV_HTTP_BODY" | jq -r '.name')" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.description')" = "$DESC" ] || cv_fail "expected description $DESC got $(printf '%s' "$CV_HTTP_BODY" | jq -r '.description')" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e --argjson p "$PRICE" '.price == $p' >/dev/null || cv_fail "expected price $PRICE got $(printf '%s' "$CV_HTTP_BODY" | jq -c '.price')" $LINENO
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.productCode')" = "$CODE" ] || cv_fail "expected productCode $CODE got $(printf '%s' "$CV_HTTP_BODY" | jq -r '.productCode')" $LINENO

# Cleanup
cv_step Cleanup "nothing to delete: in-memory store, no delete route; data is uniquely suffixed" $LINENO
echo "left uniquely-coded product $CODE in in-memory store"

echo "CODEVALID_TEST_ASSERTION_OK:get_product_by_id_anonymous_happy_path"
