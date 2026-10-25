#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_8788352785_20261025055330/api/_infra.sh

CAT="auth"; SEV="serious"; TITLE="No brute-force protection on customer login"
cv_step Given "register a customer with a known email" $LINENO
SUFFIX=$(cv_suffix)
EMAIL="brute_${SUFFIX}@example.com"
PASSWORD="Passw0rd-${SUFFIX: -6}"
cv_http POST /auth/register "$(cv_login_json "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup failed: register got $CV_HTTP_STATUS"; exit 1; }

cv_step When "send 25 wrong-password logins then the correct one" $LINENO
N401=0; N429=0; OTHER=0
for i in $(seq 1 25); do
  cv_http POST /auth/login "$(cv_login_json "$EMAIL" "WrongGuess-$i-$SUFFIX")" >/dev/null
  case "$CV_HTTP_STATUS" in 401) N401=$((N401+1)) ;; 429) N429=$((N429+1)) ;; *) OTHER=$((OTHER+1)) ;; esac
done
cv_http POST /auth/login "$(cv_login_json "$EMAIL" "$PASSWORD")" >/dev/null
FINAL="$CV_HTTP_STATUS"

cv_step Then "decide verdict from observed statuses" $LINENO
EVIDENCE="25 wrong-password attempts gave 401x${N401} 429x${N429} otherx${OTHER}; correct password afterwards gave ${FINAL}"
if [ "$N429" -eq 0 ] && [ "$N401" -eq 25 ] && [ "$FINAL" = "200" ]; then
  printf 'CV_SECURITY|vulnerable|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
else
  printf 'CV_SECURITY|secure|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
fi
# Cleanup: in-memory store, no delete route; user email is uniquely suffixed.
exit 0
