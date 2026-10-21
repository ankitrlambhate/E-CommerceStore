#!/bin/bash
# EC2 user-data: install Docker, pull the 5 images from Docker Hub, run everything.
# Rendered by Terraform's templatefile(); log is in /var/log/user-data.log
set -euo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "=== [1/5] Installing Docker ==="
apt-get update -y
apt-get install -y docker.io curl
systemctl enable --now docker

DH="${dockerhub_username}"
TAG="${image_tag}"
NET="ecommerce-net"

retry() { for i in 1 2 3 4 5; do "$@" && return 0; echo "retry $i: $*"; sleep 5; done; return 1; }

echo "=== [2/5] Pulling images ==="
retry docker pull mongo:6
for svc in user-service product-service cart-service order-service frontend; do
  retry docker pull "$DH/ecommerce-$svc:$TAG"
done

echo "=== [3/5] Creating network and MongoDB ==="
docker network inspect "$NET" >/dev/null 2>&1 || docker network create "$NET"
docker run -d --name mongo --network "$NET" --restart unless-stopped \
  -v mongo-data:/data/db mongo:6

echo "=== [4/5] Starting services ==="
docker run -d --name user-service --network "$NET" --restart unless-stopped -p 3001:3001 \
  -e PORT=3001 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_users \
  -e JWT_SECRET="${jwt_secret}" \
  "$DH/ecommerce-user-service:$TAG"

docker run -d --name product-service --network "$NET" --restart unless-stopped -p 3002:3002 \
  -e PORT=3002 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_products \
  "$DH/ecommerce-product-service:$TAG"

docker run -d --name cart-service --network "$NET" --restart unless-stopped -p 3003:3003 \
  -e PORT=3003 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_carts \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  "$DH/ecommerce-cart-service:$TAG"

docker run -d --name order-service --network "$NET" --restart unless-stopped -p 3004:3004 \
  -e PORT=3004 -e MONGODB_URI=mongodb://mongo:27017/ecommerce_orders \
  -e CART_SERVICE_URL=http://cart-service:3003 \
  -e PRODUCT_SERVICE_URL=http://product-service:3002 \
  -e USER_SERVICE_URL=http://user-service:3001 \
  "$DH/ecommerce-order-service:$TAG"

docker run -d --name frontend --network "$NET" --restart unless-stopped -p 80:80 \
  "$DH/ecommerce-frontend:$TAG"

echo "=== [5/5] Verifying ==="
sleep 10
{
  echo "Deployment check at $(date -u +%FT%TZ)"
  for p in 3001 3002 3003 3004; do
    echo "port $p -> $(curl -s -m 5 http://localhost:$p/ || echo FAILED)"
  done
  echo "frontend -> $(curl -s -m 5 http://localhost/healthz || echo FAILED)"
  docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
} | tee /var/log/deploy-status.txt

echo "=== user-data finished ==="
