#!/usr/bin/env bash
# Run the full stack locally with the same wiring the EC2 user-data uses, then smoke-test it.
# Usage: DOCKERHUB_USER=yourname [TAG=latest] ./scripts/test-local.sh   (images must already be built)
# Cleanup: ./scripts/test-local.sh down
set -euo pipefail

: "${DOCKERHUB_USER:?Set DOCKERHUB_USER}"
TAG="${TAG:-latest}"
NET=ecommerce-net-local
NAMES=(mongo-local user-service product-service cart-service order-service frontend)

down() { docker rm -f "${NAMES[@]}" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; }
if [ "${1:-}" = "down" ]; then down; echo "cleaned up"; exit 0; fi
down

docker network create "$NET" >/dev/null
# The services connect to host name "mongo", so give the container that alias
docker run -d --name mongo-local --network "$NET" --network-alias mongo mongo:6 >/dev/null

run() { # name port image [extra docker args...]
  local name=$1 port=$2 img=$3; shift 3
  docker run -d --name "$name" --network "$NET" -p "$port:$port" "$@" "$DOCKERHUB_USER/$img:$TAG" >/dev/null
}
run user-service 3001 ecommerce-user-service -e PORT=3001 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_users -e JWT_SECRET=local-test
run product-service 3002 ecommerce-product-service -e PORT=3002 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_products
run cart-service 3003 ecommerce-cart-service -e PORT=3003 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_carts -e PRODUCT_SERVICE_URL=http://product-service:3002
run order-service 3004 ecommerce-order-service -e PORT=3004 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_orders \
  -e CART_SERVICE_URL=http://cart-service:3003 -e PRODUCT_SERVICE_URL=http://product-service:3002 -e USER_SERVICE_URL=http://user-service:3001
docker run -d --name frontend --network "$NET" -p 8080:80 "$DOCKERHUB_USER/ecommerce-frontend:$TAG" >/dev/null

sleep 8
fail=0
check() { # label url expected-substring
  out=$(curl -s -m 5 "$2" || true)
  if [[ "$out" == *"$3"* ]]; then echo "PASS  $1 -> $out" | head -c 160; echo; else echo "FAIL  $1 ($2) -> '$out'"; fail=1; fi
}
check "user direct"      http://localhost:3001/            "User Service Running"
check "product direct"   http://localhost:3002/            "Product Service Running"
check "cart direct"      http://localhost:3003/            "Cart Service Running"
check "order direct"     http://localhost:3004/            "Order Service Running"
check "frontend health"  http://localhost:8080/healthz     "Frontend is Live"
check "frontend homepage" http://localhost:8080/           "<div id=\"root\">"
check "proxy -> user"    http://localhost:8080/svc/user/   "User Service Running"
check "proxy -> product" http://localhost:8080/svc/product/ "Product Service Running"
check "proxy -> cart"    http://localhost:8080/svc/cart/   "Cart Service Running"
check "proxy -> order"   http://localhost:8080/svc/order/  "Order Service Running"

echo; [ $fail -eq 0 ] && echo "ALL CHECKS PASSED (frontend at http://localhost:8080)" || { echo "SOME CHECKS FAILED"; docker ps -a; exit 1; }
echo "Run './scripts/test-local.sh down' to clean up."
