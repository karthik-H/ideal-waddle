#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_5500297573_20261025055330/api/_infra.sh

CAT="design"
SEV="serious"
TITLE="Unauthenticated registration endpoint lacks abuse controls"
PASSWORD="Probe-Pass-12345"

cv_step Given "app reachable and a single unauthenticated registration works" $LINENO
cv_http POST /auth/register "$(register_payload "$(cv_unique_email secprobe)" "$PASSWORD")"
if [ "$CV_HTTP_STATUS" = "000" ]; then
  echo "app unreachable at $(app_url /auth/register)"
  exit 1
fi
FIRST="$CV_HTTP_STATUS"
if [ "$FIRST" != "201" ]; then
  echo "baseline registration did not succeed (status $FIRST); cannot run probe"
  exit 1
fi
FIRST_TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')

cv_step When "send 25 rapid sequential registrations with distinct emails from one client" $LINENO
CREATED=1
BLOCKED=0
OTHER=0
LIMIT_HDR=0
for i in $(seq 1 25); do
  cv_http POST /auth/register "$(register_payload "$(cv_unique_email "secprobe$i")" "$PASSWORD")"
  case "$CV_HTTP_STATUS" in
    201) CREATED=$((CREATED + 1)) ;;
    429|403|503) BLOCKED=$((BLOCKED + 1)) ;;
    *) OTHER=$((OTHER + 1)) ;;
  esac
  if grep -qiE '^(x-)?ratelimit|^retry-after' "$CV_HTTP_HEADERS_FILE" 2>/dev/null; then
    LIMIT_HDR=1
  fi
done

cv_step Then "decide whether any throttling or abuse control kicked in" $LINENO
EVIDENCE="baseline 201 token=$([ -n "$FIRST_TOKEN" ] && echo yes || echo no); 26 unauthenticated registrations: ${CREATED}x201 ${BLOCKED}x429/403/503 ${OTHER}x other; ratelimit headers=${LIMIT_HDR}"

cv_step Cleanup "no delete route: probe accounts stay in app memory with unique emails" $LINENO

if [ "$BLOCKED" -eq 0 ] && [ "$LIMIT_HDR" -eq 0 ] && [ "$CREATED" -ge 26 ]; then
  printf 'CV_SECURITY|vulnerable|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
else
  printf 'CV_SECURITY|secure|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
fi
exit 0
