#!/usr/bin/env bash
set -euo pipefail
source .codevalid/tests/task_2129182590_20261025055330/api/_infra.sh

# Given
cv_step Given "signed-in users have added several products" $LINENO
SUFFIX=$(cv_suffix)
cv_prereq "register first seller" $LINENO
cv_register_user "seller1_${SUFFIX}@example.com" "Passw0rd-${SUFFIX: -6}" $LINENO
TOKEN1="$CV_TOKEN"
cv_prereq "register second seller" $LINENO
cv_register_user "seller2_${SUFFIX}@example.com" "Passw0rd-${SUFFIX: -6}" $LINENO
TOKEN2="$CV_TOKEN"

N1="Lamp ${SUFFIX}";  D1="Desk lamp ${SUFFIX}";  P1=24.5;  C1="LAMP-${SUFFIX}"
N2="Mug ${SUFFIX}";   D2="Ceramic mug ${SUFFIX}"; P2=8;    C2="MUG-${SUFFIX}"
N3="Chair ${SUFFIX}"; D3="Office chair ${SUFFIX}"; P3=149.99; C3="CHAIR-${SUFFIX}"
cv_prereq "create product $C1" $LINENO
cv_create_product "$TOKEN1" "$N1" "$D1" "$P1" "$C1" $LINENO; ID1="$CV_PRODUCT_ID"
cv_prereq "create product $C2" $LINENO
cv_create_product "$TOKEN1" "$N2" "$D2" "$P2" "$C2" $LINENO; ID2="$CV_PRODUCT_ID"
cv_prereq "create product $C3" $LINENO
cv_create_product "$TOKEN2" "$N3" "$D3" "$P3" "$C3" $LINENO; ID3="$CV_PRODUCT_ID"

# When
cv_step When "anonymous GET /products" $LINENO
cv_http GET /products

# Then
cv_step Then "200 with every added product and its name, description, price and code" $LINENO
[ "$CV_HTTP_STATUS" = "200" ] || cv_fail "expected HTTP 200 from GET /products got $CV_HTTP_STATUS" $LINENO
printf '%s' "$CV_HTTP_BODY" | jq -e '.products | type == "array"' >/dev/null || cv_fail "expected products array in response got $CV_HTTP_BODY" $LINENO
check() {
  printf '%s' "$CV_HTTP_BODY" | jq -e --arg id "$1" --arg n "$2" --arg d "$3" --argjson p "$4" --arg c "$5" \
    '[.products[] | select(.id==$id and .name==$n and .description==$d and .price==$p and .productCode==$c)] | length == 1' >/dev/null \
    || cv_fail "expected product $5 ($1) with name/description/price/productCode in catalog" "$6"
}
check "$ID1" "$N1" "$D1" "$P1" "$C1" $LINENO
check "$ID2" "$N2" "$D2" "$P2" "$C2" $LINENO
check "$ID3" "$N3" "$D3" "$P3" "$C3" $LINENO
COUNT=$(printf '%s' "$CV_HTTP_BODY" | jq '.products | length')
[ "$COUNT" -ge 3 ] || cv_fail "expected at least 3 products in catalog got $COUNT" $LINENO

# Cleanup
cv_step Cleanup "nothing to delete: in-memory store, no delete route; data is uniquely suffixed" $LINENO
echo "left uniquely-coded products $C1 $C2 $C3 in in-memory store"

echo "CODEVALID_TEST_ASSERTION_OK:get_products_happy_path_browse_full_catalog_with_items"
