#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_5500297573_20261025055330/api/_infra.sh

# Given
cv_step Given "a new unique email that has no account yet and a valid 8-72 char password" $LINENO
EMAIL=$(cv_unique_email register)
PASSWORD="Valid-Pass-$(cv_unique_suffix | tail -c 7)"
cv_prereq "check the email cannot log in yet (no account exists)" $LINENO
cv_http POST /auth/login "$(register_payload "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "401" ] || cv_fail "expected 401 for unregistered email before registration got $CV_HTTP_STATUS" $LINENO

# When
cv_step When "POST /auth/register with the new email and valid password" $LINENO
cv_http POST /auth/register "$(register_payload "$EMAIL" "$PASSWORD")"

# Then
cv_step Then "201 with a token and the created user carrying the registered email" $LINENO
[ "$CV_HTTP_STATUS" = "201" ] || cv_fail "expected 201 got $CV_HTTP_STATUS" $LINENO
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
[ -n "$TOKEN" ] || cv_fail "expected non-empty token got '$TOKEN'" $LINENO
[ "$(printf '%s' "$TOKEN" | awk -F. '{print NF}')" = "3" ] || cv_fail "expected JWT with 3 segments got '$TOKEN'" $LINENO
GOT_EMAIL=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.email // empty')
[ "$GOT_EMAIL" = "$EMAIL" ] || cv_fail "expected user.email $EMAIL got '$GOT_EMAIL'" $LINENO
USER_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ -n "$USER_ID" ] || cv_fail "expected non-empty user.id got '$USER_ID'" $LINENO
CREATED=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.createdAt // empty')
[ -n "$CREATED" ] || cv_fail "expected user.createdAt got '$CREATED'" $LINENO
HAS_HASH=$(printf '%s' "$CV_HTTP_BODY" | jq '(.user | has("passwordHash")) or (.user | has("password"))')
[ "$HAS_HASH" = "false" ] || cv_fail "expected no password/passwordHash in user got $HAS_HASH" $LINENO
cv_prereq "account exists: login with the same credentials succeeds" $LINENO
cv_http POST /auth/login "$(register_payload "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 on login after registration got $CV_HTTP_STATUS" $LINENO
LOGIN_ID=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.id // empty')
[ "$LOGIN_ID" = "$USER_ID" ] || cv_fail "expected login user.id $USER_ID got '$LOGIN_ID'" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: users live in app memory with no delete route; email is unique" $LINENO

echo "CODEVALID_TEST_ASSERTION_OK:register_success_new_email"
