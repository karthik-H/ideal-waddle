#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_2129182590_20261025055330/api/_infra.sh

cv_step Given "register a victim account" $LINENO
SUFFIX="$(date +%s%N)$RANDOM"
EMAIL="victim_${SUFFIX}@example.com"
PASSWORD="Correct-${SUFFIX: -8}"
cv_http POST /auth/register "$(jq -nc --arg e "$EMAIL" --arg p "$PASSWORD" '{email:$e,password:$p}')"
if [ "$CV_HTTP_STATUS" != "201" ]; then
  echo "setup failed: register returned $CV_HTTP_STATUS"
  exit 1
fi

cv_step When "28 rapid wrong-password logins" $LINENO
ATTEMPTS=28
C401=0; C429=0; COTHER=0
BAD=$(jq -nc --arg e "$EMAIL" '{email:$e,password:"wrong-password-guess"}')
for i in $(seq 1 $ATTEMPTS); do
  cv_http POST /auth/login "$BAD"
  case "$CV_HTTP_STATUS" in
    401) C401=$((C401+1)) ;;
    429) C429=$((C429+1)) ;;
    *) COTHER=$((COTHER+1)) ;;
  esac
  if grep -qi '^retry-after:' "$CV_HTTP_HEADERS_FILE" 2>/dev/null; then C429=$((C429+1)); fi
done

cv_step Then "check whether a correct login still succeeds right after" $LINENO
cv_http POST /auth/login "$(jq -nc --arg e "$EMAIL" --arg p "$PASSWORD" '{email:$e,password:$p}')"
FINAL="$CV_HTTP_STATUS"

TITLE="No rate limiting on /auth/login enables credential stuffing and brute-force attacks"
EVID="${ATTEMPTS} wrong-password POST /auth/login: ${C401}x401 ${C429}x429/retry-after ${COTHER}xother; correct login afterwards ${FINAL}"
if [ "$C429" -eq 0 ] && [ "$C401" -eq "$ATTEMPTS" ] && [ "$FINAL" = "200" ]; then
  printf 'CV_SECURITY|vulnerable|auth|serious|%s|%s\n' "$TITLE" "$EVID"
else
  printf 'CV_SECURITY|secure|auth|serious|%s|%s\n' "$TITLE" "$EVID"
fi
exit 0
