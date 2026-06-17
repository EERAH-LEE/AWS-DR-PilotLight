#!/usr/bin/env bash
set -euo pipefail

# Azure Container Registry 이름입니다.
# 실행할 때 `ACR_NAME=다른acr ./push_acr.sh`처럼 덮어쓸 수 있습니다.
ACR_NAME="${ACR_NAME:-azsiskbeautyacr}"

# Docker push 대상 registry 주소입니다.
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-${ACR_NAME}.azurecr.io}"

# ACR 안에 저장될 repository/image 이름입니다.
IMAGE_NAME="${IMAGE_NAME:-final-pj-web}"

# 로컬에 이미 만들어져 있어야 하는 원본 이미지입니다.
SOURCE_IMAGE="${SOURCE_IMAGE:-final-pj-web-blue:latest}"

# ACR에 올릴 태그입니다. blue, green, canary, v1 등으로 바꿔 사용할 수 있습니다.
TARGET_TAG="${TARGET_TAG:-blue}"

# 최종 push 대상 이미지 전체 이름입니다.
TARGET_IMAGE="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${TARGET_TAG}"

# push할 로컬 이미지가 없으면 먼저 빌드하도록 안내하고 중단합니다.
if ! docker image inspect "${SOURCE_IMAGE}" >/dev/null 2>&1; then
  echo "Source image not found: ${SOURCE_IMAGE}" >&2
  echo "Build it first:" >&2
  echo "  docker compose up --build -d" >&2
  exit 1
fi

# Azure CLI 인증 정보로 ACR에 Docker login을 수행합니다.
echo "[1/3] Login to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

# 로컬 이미지에 ACR 주소 형식의 태그를 추가합니다.
echo "[2/3] Tag image"
docker tag "${SOURCE_IMAGE}" "${TARGET_IMAGE}"

# 태그가 붙은 이미지를 ACR로 업로드합니다.
echo "[3/3] Push image"
docker push "${TARGET_IMAGE}"

echo
echo "Pushed: ${TARGET_IMAGE}"
