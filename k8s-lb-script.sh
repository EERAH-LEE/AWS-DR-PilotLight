#!/usr/bin/env bash
set -euo pipefail

# Ubuntu/Linux execution:
#   cd ~/Desktop/final_pj_aws
#   bash ./k8s-lb-script.sh
#
# Common overrides:
#   PROJECT_ROOT="$HOME/Desktop/final_pj_aws" IMAGE_TAG="11d1934" bash ./k8s-lb-script.sh
#
# Values friends may need to change:
#   PROJECT_ROOT  - each person's project folder
#   IMAGE_TAG     - ECR tag suffix. If ECR tag is blue-11d1934, use 11d1934
#   RDS_ENDPOINT  - optional. Leave empty to auto-discover from RDS
#   DB_USER / DB_PASSWORD - only if DB credentials differ

PROJECT_ROOT="${PROJECT_ROOT:-/home/eerah/final_aws_based}"
REGION="${REGION:-ap-northeast-2}"
CLUSTER_NAME="${CLUSTER_NAME:-azsis-kbeauty-dr-eks}"
ACCOUNT_ID="${ACCOUNT_ID:-946775837287}"
VPC_ID="${VPC_ID:-}"
ALB_POLICY_ARN="${ALB_POLICY_ARN:-arn:aws:iam::946775837287:policy/AWSLoadBalancerControllerIAMPolicy}"
ALB_ROLE_NAME="${ALB_ROLE_NAME:-AmazonEKSLoadBalancerControllerRole}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
RDS_IDENTIFIER="${RDS_IDENTIFIER:-mysql-azsis-kbeauty-dr}"
RDS_ENDPOINT="${RDS_ENDPOINT:-}"
DB_NAME="${DB_NAME:-kbeauty}"
DB_USER="${DB_USER:-azsis}"
DB_PASSWORD="${DB_PASSWORD:-kbeauty123!}"

step() {
  echo
  echo "==> $1"
}

run() {
  echo "$*"
  "$@"
}

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_alb_service_account() {
  step "4. Ensure ALB Controller IAM ServiceAccount"

  run eksctl utils associate-iam-oidc-provider \
    --region "$REGION" \
    --cluster "$CLUSTER_NAME" \
    --approve

  local create_args=(
    create iamserviceaccount
    --cluster "$CLUSTER_NAME"
    --region "$REGION"
    --namespace kube-system
    --name aws-load-balancer-controller
    --role-name "$ALB_ROLE_NAME"
    --attach-policy-arn "$ALB_POLICY_ARN"
    --approve
    --override-existing-serviceaccounts
  )

  run eksctl "${create_args[@]}"

  local expected_role_arn="arn:aws:iam::${ACCOUNT_ID}:role/${ALB_ROLE_NAME}"
  local annotation=""
  annotation="$(kubectl get sa aws-load-balancer-controller -n kube-system -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}' 2>/dev/null || true)"

  if [[ "$annotation" != "$expected_role_arn" ]]; then
    echo "ServiceAccount annotation is missing or stale. Recreating iamserviceaccount..."
    eksctl delete iamserviceaccount \
      --cluster "$CLUSTER_NAME" \
      --region "$REGION" \
      --namespace kube-system \
      --name aws-load-balancer-controller \
      --wait || true

    run eksctl "${create_args[@]}"
  fi

  run kubectl describe sa -n kube-system aws-load-balancer-controller
}

ensure_alb_controller() {
  step "5. Install or upgrade ALB Controller"

  if [[ -z "$VPC_ID" ]]; then
    VPC_ID="$(aws eks describe-cluster \
      --region "$REGION" \
      --name "$CLUSTER_NAME" \
      --query 'cluster.resourcesVpcConfig.vpcId' \
      --output text)"
  fi

  echo "Using VPC ID: $VPC_ID"

  run helm repo add eks https://aws.github.io/eks-charts --force-update
  run helm repo update
  run helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set "clusterName=$CLUSTER_NAME" \
    --set "region=$REGION" \
    --set "vpcId=$VPC_ID" \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --wait \
    --timeout 5m

  run kubectl rollout restart deployment -n kube-system aws-load-balancer-controller
  run kubectl rollout status deployment -n kube-system aws-load-balancer-controller
  run kubectl get deployment -n kube-system aws-load-balancer-controller
}

for cmd in aws kubectl eksctl helm; do
  ensure_command "$cmd"
done

K8S_DIR="$PROJECT_ROOT/k8s"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
WEB_BLUE_IMAGE="${ECR}/azsis-kbeauty-dr/web-blue:${IMAGE_TAG}"
WAS_BLUE_IMAGE="${ECR}/azsis-kbeauty-dr/was-blue:${IMAGE_TAG}"

step "1. Check project path"
if [[ ! -d "$K8S_DIR" ]]; then
  echo "K8s directory not found: $K8S_DIR" >&2
  exit 1
fi
echo "Using K8s path: $K8S_DIR"

step "2. ECR 로그인 & 이미지 빌드/푸시"
aws ecr get-login-password --region "$REGION" | \
    docker login --username AWS --password-stdin "$ECR"

echo "  was-blue 빌드..."
run docker build \
    -f "$PROJECT_ROOT/k8s/was/image_build/blue/Dockerfile" \
    --build-arg APP_DIR=app/was_blue \
    -t "$ECR/azsis-kbeauty-dr/was-blue:$IMAGE_TAG" \
    "$PROJECT_ROOT"
run docker push "$ECR/azsis-kbeauty-dr/was-blue:$IMAGE_TAG"

echo "  was-green 빌드..."
run docker build \
    -f "$PROJECT_ROOT/k8s/was/image_build/green/Dockerfile" \
    --build-arg APP_DIR=app/was_green \
    -t "$ECR/azsis-kbeauty-dr/was-green:$IMAGE_TAG" \
    "$PROJECT_ROOT"
run docker push "$ECR/azsis-kbeauty-dr/was-green:$IMAGE_TAG"

echo "  web-blue 빌드..."
run docker build \
    -f "$PROJECT_ROOT/k8s/web/image_build/blue/Dockerfile" \
    -t "$ECR/azsis-kbeauty-dr/web-blue:$IMAGE_TAG" \
    "$PROJECT_ROOT/app/web_blue"
run docker push "$ECR/azsis-kbeauty-dr/web-blue:$IMAGE_TAG"

echo "  web-green 빌드..."
run docker build \
    -f "$PROJECT_ROOT/k8s/web/image_build/green/Dockerfile" \
    -t "$ECR/azsis-kbeauty-dr/web-green:$IMAGE_TAG" \
    "$PROJECT_ROOT/app/web_green"
run docker push "$ECR/azsis-kbeauty-dr/web-green:$IMAGE_TAG"

step "3. Connect EKS kubeconfig"
run aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
run kubectl get nodes

step "4. Resolve RDS endpoint and apply DB secret"
run kubectl apply -f "$K8S_DIR/namespace.yaml"
if [[ -z "$RDS_ENDPOINT" ]]; then
  RDS_ENDPOINT="$(aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier "$RDS_IDENTIFIER" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)"
fi

if [[ -z "$RDS_ENDPOINT" || "$RDS_ENDPOINT" == "None" ]]; then
  echo "RDS endpoint was not found. Check RDS identifier: $RDS_IDENTIFIER" >&2
  exit 1
fi

DB_URL="jdbc:mysql://${RDS_ENDPOINT}:3306/${DB_NAME}?useSSL=false&serverTimezone=Asia/Seoul&allowPublicKeyRetrieval=true"
echo "Using RDS endpoint: $RDS_ENDPOINT"

kubectl create secret generic db-secret \
  -n app-was \
  --from-literal="db-url=$DB_URL" \
  --from-literal="db-user=$DB_USER" \
  --from-literal="db-password=$DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

ensure_alb_service_account
ensure_alb_controller

step "7. Apply Kustomize resources"
run kubectl apply -k "$K8S_DIR"

step "8. Pin images to existing ECR tags"
run kubectl set image deployment/web-blue -n app-web "web=$WEB_BLUE_IMAGE"
run kubectl set image deployment/was-blue -n app-was "was=$WAS_BLUE_IMAGE"

step "9. Wait for rollout"
run kubectl rollout status deployment web-blue -n app-web
run kubectl rollout status deployment was-blue -n app-was

step "10. Check ingress"
run kubectl get ingress -A

echo
echo "Done. If ingress has ADDRESS and both active services have ENDPOINTS, the demo path is ready."