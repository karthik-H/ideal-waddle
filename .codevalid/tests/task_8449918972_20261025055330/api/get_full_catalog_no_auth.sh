#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_8449918972_20261025055330/api/_infra.sh

# Given
cv_step Given "two products exist in the catalog, created by a registered user" $LINENO
SFX=$(cv_suffix)
cv_register_user "catalog_$SFX@example.com" "Passw0rd!$SFX"
TOKEN=$CV_TOKEN
cv_create_product "$TOKEN" "Catalog Widget A $SFX" "First test widget" 19.99 "CAT-A-$SFX"
ID_A=$CV_PRODUCT_ID
cv_create_product "$TOKEN" "Catalog Widget B $SFX" "Second test widget" 5 "CAT-B-$SFX"
ID_B=$CV_PRODUCT_ID

# When
cv_step When "anonymous client GETs /products with no Authorization header" $LINENO
cv_http GET /products

# Then
cv_step Then "200 with a products array containing both created products with full details" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
TYPE=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.products | type')
[ "$TYPE" = "array" ] || cv_fail "expected .products to be an array got $TYPE" $LINENO
COUNT=$(printf '%s' "$CV_HTTP_BODY" | jq '.products | length')
[ "$COUNT" -ge 2 ] || cv_fail "expected at least 2 products got $COUNT" $LINENO
A=$(printf '%s' "$CV_HTTP_BODY" | jq -c --arg id "$ID_A" '.products[] | select(.id==$id)')
B=$(printf '%s' "$CV_HTTP_BODY" | jq -c --arg id "$ID_B" '.products[] | select(.id==$id)')
[ -n "$A" ] || cv_fail "expected product $ID_A in catalog got none" $LINENO
[ -n "$B" ] || cv_fail "expected product $ID_B in catalog got none" $LINENO
printf '%s' "$A" | jq -e --arg s "$SFX" '.name=="Catalog Widget A \($s)" and .description=="First test widget" and .price==19.99 and .productCode=="CAT-A-\($s)" and (.createdAt|type=="string")' >/dev/null \
  || cv_fail "expected product A full details got $A" $LINENO
printf '%s' "$B" | jq -e --arg s "$SFX" '.name=="Catalog Widget B \($s)" and .description=="Second test widget" and .price==5 and .productCode=="CAT-B-\($s)"' >/dev/null \
  || cv_fail "expected product B full details got $B" $LINENO
if printf '%s' "$CV_HTTP_BODY" | jq -e '[.products[] | has("passwordHash")] | any' >/dev/null; then
  cv_fail "expected no passwordHash in catalog got one" $LINENO
fi

# Cleanup
cv_step Cleanup "nothing to remove: data is in-memory with no delete endpoint; values are unique per run" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:get_full_catalog_no_auth"
