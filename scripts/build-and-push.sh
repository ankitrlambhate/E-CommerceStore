#!/usr/bin/env bash
# Build the 5 images, then tag and push them to Docker Hub.
# Usage: DOCKERHUB_USER=yourname [TAG=latest] ./scripts/build-and-push.sh
set -euo pipefail

: "${DOCKERHUB_USER:?Set DOCKERHUB_USER to your Docker Hub username}"
TAG="${TAG:-latest}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# image-name -> build context
declare -A CONTEXTS=(
  [ecommerce-user-service]="$ROOT/backend/user-service"
  [ecommerce-product-service]="$ROOT/backend/product-service"
  [ecommerce-cart-service]="$ROOT/backend/cart-service"
  [ecommerce-order-service]="$ROOT/backend/order-service"
  [ecommerce-frontend]="$ROOT/frontend"
)

echo ">> Logging in to Docker Hub (skip if already logged in)"
docker login -u "$DOCKERHUB_USER"

for name in "${!CONTEXTS[@]}"; do
  image="$DOCKERHUB_USER/$name:$TAG"
  echo ">> Building $image"
  # --platform linux/amd64 so images built on Apple Silicon still run on the x86 EC2 instance
  docker build --platform linux/amd64 -t "$image" "${CONTEXTS[$name]}"
  echo ">> Pushing $image"
  docker push "$image"
done

echo ">> Done. Images pushed:"
for name in "${!CONTEXTS[@]}"; do echo "   $DOCKERHUB_USER/$name:$TAG"; done
echo ">> Make sure each repository is public on hub.docker.com (new repos are public by default on free accounts)."
