#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
REGION="${REGION:-ap-northeast-2}"
CLUSTER_NAME="${CLUSTER_NAME:-azsis-kbeauty-dr-eks}"
ACCOUNT_ID="${ACCOUNT_ID:-946775837287}"
IMAGE_TAG="${IMAGE_TAG:-}"
VPC_ID="${VPC_ID:-}"
ALB_POLICY_ARN="${ALB_POLICY_ARN:-arn:aws:iam::946775837287:policy/AWSLoadBalancerControllerIAMPolicy}"
ALB_ROLE_NAME="${ALB_ROLE_NAME:-AmazonEKSLoadBalancerControllerRole}"
RDS_IDENTIFIER="${RDS_IDENTIFIER:-mysql-azsis-kbeauty-dr}"
RDS_ENDPOINT="${RDS_ENDPOINT:-}"
DB_NAME="${DB_NAME:-kbeauty}"
DB_USER="${DB_USER:-azsis}"
DB_PASSWORD="${DB_PASSWORD:-kbeauty123!}"
SKIP_BUILD_PUSH="${SKIP_BUILD_PUSH:-false}"
SKIP_ALB_CONTROLLER="${SKIP_ALB_CONTROLLER:-false}"

step() {
  echo
  echo "==> $*"
}

run() {
  echo "+ $*"
  "$@"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

resolve_image_tag() {
  if [[ -n "$IMAGE_TAG" ]]; then
    echo "$IMAGE_TAG"
    return
  fi

  if git -C "$PROJECT_ROOT" rev-parse --short HEAD >/dev/null 2>&1; then
    git -C "$PROJECT_ROOT" rev-parse --short HEAD
    return
  fi

  date +"%Y%m%d%H%M"
}

ensure_alb_controller() {
  step "Install or upgrade AWS Load Balancer Controller"

  run eksctl utils associate-iam-oidc-provider \
    --region "$REGION" \
    --cluster "$CLUSTER_NAME" \
    --approve

  run eksctl create iamserviceaccount \
    --cluster "$CLUSTER_NAME" \
    --region "$REGION" \
    --namespace kube-system \
    --name aws-load-balancer-controller \
    --role-name "$ALB_ROLE_NAME" \
    --attach-policy-arn "$ALB_POLICY_ARN" \
    --approve \
    --override-existing-serviceaccounts

  if [[ -z "$VPC_ID" ]]; then
    VPC_ID="$(aws eks describe-cluster \
      --region "$REGION" \
      --name "$CLUSTER_NAME" \
      --query "cluster.resourcesVpcConfig.vpcId" \
      --output text)"
  fi

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

  run kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=5m
}

build_and_push() {
  local local_name="$1"
  local dockerfile="$2"
  local context="$3"
  local remote_image="$4"

  step "Build and push $local_name"
  run docker build -t "${local_name}:latest" -f "$dockerfile" "$context"
  run docker tag "${local_name}:latest" "$remote_image"
  run docker push "$remote_image"
}

K8S_DIR="$PROJECT_ROOT/k8s"
if [[ ! -d "$K8S_DIR" ]]; then
  echo "K8s directory not found: $K8S_DIR" >&2
  exit 1
fi

require_command aws
require_command kubectl
require_command docker
if [[ "$SKIP_ALB_CONTROLLER" != "true" ]]; then
  require_command eksctl
  require_command helm
fi

RESOLVED_IMAGE_TAG="$(resolve_image_tag)"
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

WEB_BLUE_IMAGE="${ECR}/azsis-kbeauty-dr/web-blue:blue-${RESOLVED_IMAGE_TAG}"
WEB_GREEN_IMAGE="${ECR}/azsis-kbeauty-dr/web-green:green-${RESOLVED_IMAGE_TAG}"
WAS_BLUE_IMAGE="${ECR}/azsis-kbeauty-dr/was-blue:blue-${RESOLVED_IMAGE_TAG}"
WAS_GREEN_IMAGE="${ECR}/azsis-kbeauty-dr/was-green:green-${RESOLVED_IMAGE_TAG}"

step "Deployment image tag"
echo "ImageTag: $RESOLVED_IMAGE_TAG"
echo "WEB_BLUE_IMAGE=$WEB_BLUE_IMAGE"
echo "WEB_GREEN_IMAGE=$WEB_GREEN_IMAGE"
echo "WAS_BLUE_IMAGE=$WAS_BLUE_IMAGE"
echo "WAS_GREEN_IMAGE=$WAS_GREEN_IMAGE"

step "Connect EKS kubeconfig"
run aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
run kubectl get nodes

if [[ "$SKIP_BUILD_PUSH" != "true" ]]; then
  step "Login to ECR"
  aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "$ECR"

  build_and_push "final-pj-web-blue" \
    "$PROJECT_ROOT/k8s/web/image_build/blue/Dockerfile" \
    "$PROJECT_ROOT/app/web_blue" \
    "$WEB_BLUE_IMAGE"

  build_and_push "final-pj-web-green" \
    "$PROJECT_ROOT/k8s/web/image_build/green/Dockerfile" \
    "$PROJECT_ROOT/app/web_green" \
    "$WEB_GREEN_IMAGE"

  build_and_push "final-pj-was-blue" \
    "$PROJECT_ROOT/k8s/was/image_build/blue/Dockerfile" \
    "$PROJECT_ROOT" \
    "$WAS_BLUE_IMAGE"

  build_and_push "final-pj-was-green" \
    "$PROJECT_ROOT/k8s/was/image_build/green/Dockerfile" \
    "$PROJECT_ROOT" \
    "$WAS_GREEN_IMAGE"
fi

step "Apply namespaces first"
run kubectl apply -f "$K8S_DIR/namespace.yaml"

step "Resolve RDS endpoint and apply DB secret"
if [[ -z "$RDS_ENDPOINT" ]]; then
  RDS_ENDPOINT="$(aws rds describe-db-instances \
    --region "$REGION" \
    --db-instance-identifier "$RDS_IDENTIFIER" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text)"
fi

if [[ -z "$RDS_ENDPOINT" || "$RDS_ENDPOINT" == "None" ]]; then
  echo "RDS endpoint was not found. Check RDS identifier: $RDS_IDENTIFIER" >&2
  exit 1
fi

DB_URL="jdbc:mysql://${RDS_ENDPOINT}:3306/${DB_NAME}?useSSL=false&serverTimezone=Asia/Seoul&allowPublicKeyRetrieval=true"
kubectl create secret generic db-secret \
  -n app-was \
  --from-literal="db-url=$DB_URL" \
  --from-literal="db-user=$DB_USER" \
  --from-literal="db-password=$DB_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ "$SKIP_ALB_CONTROLLER" != "true" ]]; then
  ensure_alb_controller
fi

step "Apply Kubernetes resources"
run kubectl apply -k "$K8S_DIR"

step "Pin all deployment images"
run kubectl set image deployment/web-blue -n app-web "web=$WEB_BLUE_IMAGE"
run kubectl set image deployment/web-green -n app-web "web=$WEB_GREEN_IMAGE"
run kubectl set image deployment/was-blue -n app-was "was=$WAS_BLUE_IMAGE"
run kubectl set image deployment/was-green -n app-was "was=$WAS_GREEN_IMAGE"

step "Wait for rollouts"
run kubectl rollout status deployment/web-blue -n app-web --timeout=5m
run kubectl rollout status deployment/web-green -n app-web --timeout=5m
run kubectl rollout status deployment/was-blue -n app-was --timeout=5m
run kubectl rollout status deployment/was-green -n app-was --timeout=5m

step "Final status"
run kubectl get pods -n app-web -o wide
run kubectl get pods -n app-was -o wide
run kubectl get endpoints -n app-web
run kubectl get endpoints -n app-was
run kubectl get ingress -A

echo
echo "Done. Deployed image tag: $RESOLVED_IMAGE_TAG"
