#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_8788352785_20261025055330/api/_infra.sh

# Given
cv_step Given "a registered customer with a known email and password" $LINENO
SUFFIX=$(cv_suffix)
EMAIL="login_${SUFFIX}@example.com"
PASSWORD="Passw0rd-${SUFFIX: -6}"
cv_prereq "register user $EMAIL" $LINENO
cv_register_user "$EMAIL" "$PASSWORD" $LINENO
REG_USER_ID="$CV_USER_ID"

# When
cv_step When "POST /auth/login with the correct email and password" $LINENO
cv_http POST /auth/login "$(cv_login_json "$EMAIL" "$PASSWORD")"
LOGIN_STATUS="$CV_HTTP_STATUS"
LOGIN_BODY="$CV_HTTP_BODY"

# Then
cv_step Then "200 with a token and the user, no password exposed, token usable on POST /products" $LINENO
[ "$LOGIN_STATUS" = "200" ] || cv_fail "expected HTTP 200 from POST /auth/login got $LOGIN_STATUS" $LINENO
TOKEN=$(printf '%s' "$LOGIN_BODY" | jq -r '.token // empty')
[ -n "$TOKEN" ] || cv_fail "expected token in login response got none" $LINENO
[ "$(printf '%s' "$LOGIN_BODY" | jq -r '.user.email')" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL got $(printf '%s' "$LOGIN_BODY" | jq -r '.user.email')" $LINENO
[ "$(printf '%s' "$LOGIN_BODY" | jq -r '.user.id')" = "$REG_USER_ID" ] || cv_fail "expected user.id $REG_USER_ID got $(printf '%s' "$LOGIN_BODY" | jq -r '.user.id')" $LINENO
if printf '%s' "$LOGIN_BODY" | grep -qiE 'password|passwordHash|\$2[aby]\$'; then
  cv_fail "expected no password or hash in login response got $LOGIN_BODY" $LINENO
fi
CODE="LOGIN-${SUFFIX}"
cv_http POST /products "$(cv_product_json "Login item ${SUFFIX}" "made with login token" 5 "$CODE")" -H "Authorization: Bearer $TOKEN"
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected HTTP 201 from POST /products with login token got $CV_HTTP_STATUS" $LINENO

# Cleanup
cv_step Cleanup "nothing to delete: in-memory store with no delete route; data uniquely suffixed" $LINENO
echo "created user $EMAIL and product $CODE (unique, left in in-memory store)"

echo "CODEVALID_TEST_ASSERTION_OK:successful_login_registered_customer"
