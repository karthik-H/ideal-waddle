#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_8788352785_20261025055330/api/_infra.sh

# Given
cv_step Given "a registered customer signed in via POST /auth/login and a unique product payload" $LINENO
SUFFIX=$(cv_suffix)
EMAIL="prodcust_${SUFFIX}@example.com"
PASSWORD="Passw0rd-${SUFFIX: -6}"
cv_prereq "register user $EMAIL" $LINENO
cv_register_user "$EMAIL" "$PASSWORD" $LINENO
cv_prereq "sign in as $EMAIL" $LINENO
cv_http POST /auth/login "$(cv_login_json "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected HTTP 200 from POST /auth/login got $CV_HTTP_STATUS" $LINENO
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
[ -n "$TOKEN" ] || cv_fail "expected token from POST /auth/login got none" $LINENO
NAME="Gadget ${SUFFIX}"
DESC="Signed-in customer gadget ${SUFFIX}"
PRICE=12.5
CODE="GAD-${SUFFIX}"
BODY=$(cv_product_json "$NAME" "$DESC" "$PRICE" "$CODE")

# When
cv_step When "POST /products with the bearer token, and once without any token" $LINENO
cv_http POST /products "$(cv_product_json "$NAME" "$DESC" "$PRICE" "NOAUTH-${SUFFIX}")"
NOAUTH_STATUS="$CV_HTTP_STATUS"
cv_http POST /products "$BODY" -H "Authorization: Bearer $TOKEN"
CREATE_STATUS="$CV_HTTP_STATUS"
CREATE_BODY="$CV_HTTP_BODY"

# Then
cv_step Then "authorized request returns 201 with the product, unauthenticated one 401, no password exposed" $LINENO
[ "$NOAUTH_STATUS" = "401" ] || cv_fail "expected HTTP 401 from POST /products without token got $NOAUTH_STATUS" $LINENO
[ "$CREATE_STATUS" = "201" ] || cv_fail "expected HTTP 201 from POST /products got $CREATE_STATUS" $LINENO
PID=$(printf '%s' "$CREATE_BODY" | jq -r '.id // empty')
[ -n "$PID" ] || cv_fail "expected product id in create response got none" $LINENO
printf '%s' "$CREATE_BODY" | jq -e --arg n "$NAME" --arg d "$DESC" --argjson p "$PRICE" --arg c "$CODE" \
  '.name==$n and .description==$d and .price==$p and .productCode==$c' >/dev/null \
  || cv_fail "expected created product fields to match request got $CREATE_BODY" $LINENO
if printf '%s' "$CREATE_BODY" | grep -qiE "password|\\\$2[aby]\\\$"; then
  cv_fail "expected no password data in product response got $CREATE_BODY" $LINENO
fi
cv_http GET "/products/$PID" 200
[ "$(printf '%s' "$CV_HTTP_BODY" | jq -r '.productCode')" = "$CODE" ] || cv_fail "expected GET /products/$PID productCode $CODE got $CV_HTTP_BODY" $LINENO
cv_http GET /products 200
printf '%s' "$CV_HTTP_BODY" | jq -e --arg c "NOAUTH-${SUFFIX}" '[.products[] | select(.productCode==$c)] | length == 0' >/dev/null \
  || cv_fail "expected unauthenticated product NOAUTH-${SUFFIX} not in catalog" $LINENO

# Cleanup
cv_step Cleanup "nothing to delete: in-memory store with no delete route; data uniquely suffixed" $LINENO
echo "created user $EMAIL and product $CODE (unique, left in in-memory store)"

echo "CODEVALID_TEST_ASSERTION_OK:create_product_with_valid_signed_in_customer"
