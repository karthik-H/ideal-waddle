#!/usr/bin/env bash
set -uo pipefail
source .codevalid/tests/task_8788352785_20261025055330/api/_infra.sh

CAT="access"; SEV="serious"; TITLE="Any authenticated user can modify catalog due to missing authorization checks"
cv_step Given "register a plain customer with no elevated role" $LINENO
SUFFIX=$(cv_suffix)
EMAIL="plain_${SUFFIX}@example.com"
PASSWORD="Passw0rd-${SUFFIX: -6}"
cv_http POST /auth/register "$(cv_login_json "$EMAIL" "$PASSWORD")"
[ "$CV_HTTP_STATUS" = "201" ] || { echo "setup failed: register got $CV_HTTP_STATUS"; exit 1; }
TOKEN=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.token // empty')
[ -n "$TOKEN" ] || { echo "setup failed: no token"; exit 1; }
ROLE=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.user.role // "none"')

cv_step When "POST /products as the plain customer" $LINENO
CODE="ACC-${SUFFIX}"
cv_http POST /products "$(cv_product_json "Probe ${SUFFIX}" "access probe" 1.5 "$CODE")" -H "Authorization: Bearer $TOKEN"
STATUS="$CV_HTTP_STATUS"
cv_http GET /products
LISTED=$(printf '%s' "$CV_HTTP_BODY" | jq -r --arg c "$CODE" '[.products[]? | select(.productCode==$c)] | length' 2>/dev/null || echo "?")

cv_step Then "decide verdict" $LINENO
EVIDENCE="customer with role=${ROLE} got POST /products ${STATUS}; product listed in catalog count=${LISTED}"
if [ "$STATUS" = "201" ] || [ "$LISTED" = "1" ]; then
  printf 'CV_SECURITY|vulnerable|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
else
  printf 'CV_SECURITY|secure|%s|%s|%s|%s\n' "$CAT" "$SEV" "$TITLE" "$EVIDENCE"
fi
# Cleanup: in-memory store, no delete route; product code is uniquely suffixed.
exit 0
