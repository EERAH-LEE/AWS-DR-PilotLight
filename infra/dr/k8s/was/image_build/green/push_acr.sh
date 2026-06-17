#!/usr/bin/env bash
set -euo pipefail

ACR_NAME="${ACR_NAME:-azsiskbeautyacr}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-${ACR_NAME}.azurecr.io}"
IMAGE_NAME="${IMAGE_NAME:-final-pj-was}"
SOURCE_IMAGE="${SOURCE_IMAGE:-final-pj-was-green:latest}"
TARGET_TAG="${TARGET_TAG:-green}"
TARGET_IMAGE="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${TARGET_TAG}"

if ! docker image inspect "${SOURCE_IMAGE}" >/dev/null 2>&1; then
  echo "Source image not found: ${SOURCE_IMAGE}" >&2
  echo "Build it first:" >&2
  echo "  docker compose up --build -d" >&2
  exit 1
fi

echo "[1/3] Login to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

echo "[2/3] Tag image"
docker tag "${SOURCE_IMAGE}" "${TARGET_IMAGE}"

echo "[3/3] Push image"
docker push "${TARGET_IMAGE}"

echo
echo "Pushed: ${TARGET_IMAGE}"