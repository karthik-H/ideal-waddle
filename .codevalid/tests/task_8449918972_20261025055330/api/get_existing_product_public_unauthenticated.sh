#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_8449918972_20261025055330/api/_infra.sh

# Given
cv_step Given "a product exists, created by a registered user" $LINENO
SFX=$(cv_suffix)
cv_register_user "detail_$SFX@example.com" "Passw0rd!$SFX"
cv_create_product "$CV_TOKEN" "Detail Gadget $SFX" "A gadget for detail view" 42.5 "DET-$SFX"
PID=$CV_PRODUCT_ID
CREATED=$CV_PRODUCT_JSON

# When
cv_step When "anonymous client GETs /products/{id} with no Authorization header" $LINENO
cv_http GET "/products/$PID"

# Then
cv_step Then "200 with the full product details matching the created product" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected 200 got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$PID" --arg s "$SFX" \
  '.id==$id and .name=="Detail Gadget \($s)" and .description=="A gadget for detail view" and .price==42.5 and .productCode=="DET-\($s)" and (.createdAt|type=="string")' >/dev/null \
  || cv_fail "expected full details of product $PID got $CV_HTTP_BODY" $LINENO
CREATED_AT=$(printf '%s' "$CREATED" | jq -r '.createdAt')
GOT_AT=$(printf '%s' "$CV_HTTP_BODY" | jq -r '.createdAt')
[ "$CREATED_AT" = "$GOT_AT" ] || cv_fail "expected createdAt $CREATED_AT got $GOT_AT" $LINENO

# Cleanup
cv_step Cleanup "nothing to remove: data is in-memory with no delete endpoint; values are unique per run" $LINENO
echo "CODEVALID_TEST_ASSERTION_OK:get_existing_product_public_unauthenticated"
