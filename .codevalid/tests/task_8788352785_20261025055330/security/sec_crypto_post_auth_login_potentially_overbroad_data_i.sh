#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_8788352785_20261025055330/api/_infra.sh

CAT="crypto"; SEV="warning"; TITLE="Potentially overbroad data in signed JWT via toPublicUser(publicUser)"
cv_step Given "register a customer" $LINENO
SUFFIX=$(cv_suffix)
EMAIL="jwt_${SUFFIX}@example.com"
PASSWORD="Passw0rd-${SUFFIX: -6}"
cv_http POST /auth/register "$(cv_login_json "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup failed: register got $CV_HTTP_STATUS"; exit 1; }

cv_step When "log in and decode the JWT payload" $LINENO
cv_http POST /auth/login "$(cv_login_json "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "200" ] || { echo "setup failed: login got $CV_HTTP_STATUS"; exit 1; }
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
[ -n "$TOKEN" ] || { echo "setup failed: no token"; exit 1; }
PAYLOAD=$(cv_jwt_payload "$TOKEN")
printf '%s' "$PAYLOAD" | jq -e . >/dev/null 2>&1 || { echo "setup failed: cannot decode JWT payload: $PAYLOAD"; exit 1; }
echo "JWT payload: $PAYLOAD"

cv_step Then "compare claims with the minimal expected set" $LINENO
KEYS=$(printf '%s' "$PAYLOAD" | jq -r 'keys | join(",")')
# Sensitive or non-essential claims beyond sub/iat/exp/email (email is used by verifyToken).
EXTRA=$(printf '%s' "$PAYLOAD" | jq -r '[keys[] | select(. != "sub" and . != "iat" and . != "exp" and . != "email" and . != "nbf" and . != "iss" and . != "aud" and . != "jti")] | join(",")')
SECRET=$(printf '%s' "$PAYLOAD" | jq -r '[.. | strings | select(test("^\\$2[aby]\\$"))] | length')
EVIDENCE="JWT claims [${KEYS}] extra=[${EXTRA}] hash-like values=${SECRET}"
if [ -n "$EXTRA" ] || [ "$SECRET" != "0" ]; then
  printf 'CV_SECURITY|vulnerable|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
else
  printf 'CV_SECURITY|secure|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
fi
# Cleanup: in-memory store, no delete route; user email is uniquely suffixed.
exit 0
