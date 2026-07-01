#!/bin/bash
# dr-deploy.sh
# 사용법: bash /home/eerah/final_aws_based/dr-deploy.sh

set -e

ROOT="/home/eerah/final_aws_based"

ECR="946775837287.dkr.ecr.ap-northeast-2.amazonaws.com"
REPO="azsis-kbeauty-dr"
REGION="ap-northeast-2"
CLUSTER="azsis-kbeauty-dr-eks"
TAG="latest"

# ── 1. ECR 로그인 ──────────────────────────────────────────────────────────────
echo -e "\n[1] ECR 로그인"
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $ECR

# ── 2. 이미지 빌드 & 푸시 ─────────────────────────────────────────────────────
echo -e "\n[2] 이미지 빌드 & 푸시"

echo "  was-blue 빌드..."
docker build \
    -f "$ROOT/k8s/was/image_build/blue/Dockerfile" \
    --build-arg APP_DIR=app/was_blue \
    -t "$ECR/$REPO/was-blue:$TAG" \
    "$ROOT"
docker push "$ECR/$REPO/was-blue:$TAG"

echo "  was-green 빌드..."
docker build \
    -f "$ROOT/k8s/was/image_build/green/Dockerfile" \
    --build-arg APP_DIR=app/was_green \
    -t "$ECR/$REPO/was-green:$TAG" \
    "$ROOT"
docker push "$ECR/$REPO/was-green:$TAG"

echo "  web-blue 빌드..."
docker build \
    -f "$ROOT/k8s/web/image_build/blue/Dockerfile" \
    -t "$ECR/$REPO/web-blue:$TAG" \
    "$ROOT/app/web_blue"
docker push "$ECR/$REPO/web-blue:$TAG"

echo "  web-green 빌드..."
docker build \
    -f "$ROOT/k8s/web/image_build/green/Dockerfile" \
    -t "$ECR/$REPO/web-green:$TAG" \
    "$ROOT/app/web_green"
docker push "$ECR/$REPO/web-green:$TAG"

# ── 3. kubectl 컨텍스트 설정 ───────────────────────────────────────────────────
echo -e "\n[3] kubectl 컨텍스트 설정"
aws eks update-kubeconfig --region $REGION --name $CLUSTER

# ── 4. ALB Controller 설치 ────────────────────────────────────────────────────
echo -e "\n[4] ALB Controller 설치"
eksctl utils associate-iam-oidc-provider \
    --region $REGION \
    --cluster $CLUSTER \
    --approve

eksctl delete iamserviceaccount \
    --cluster $CLUSTER \
    --region $REGION \
    --namespace kube-system \
    --name aws-load-balancer-controller \
    --wait 2>/dev/null || true

eksctl create iamserviceaccount \
    --cluster $CLUSTER \
    --region $REGION \
    --namespace kube-system \
    --name aws-load-balancer-controller \
    --role-name AmazonEKSLoadBalancerControllerRole \
    --attach-policy-arn arn:aws:iam::946775837287:policy/AWSLoadBalancerControllerIAMPolicy \
    --approve \
    --override-existing-serviceaccounts

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=$CLUSTER \
    --set region=$REGION \
    --set vpcId=vpc-0edcede2943a173a4 \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

kubectl rollout status deployment/aws-load-balancer-controller \
    -n kube-system --timeout=180s

# ── 5. DB Secret ───────────────────────────────────────────────────────────────
echo -e "\n[4] DB Secret 적용"
kubectl apply -f "$ROOT/k8s/was/db-secret.example.yaml"

# ── 6. 앱 배포 ─────────────────────────────────────────────────────────────────
echo -e "\n[6] 앱 배포"
kubectl apply -k "$ROOT/k8s"

# ── 7. 최신 이미지 반영 ────────────────────────────────────────────────────────
echo -e "\n[7] Rollout Restart"
kubectl rollout restart deployment -n app-web
kubectl rollout restart deployment -n app-was
kubectl rollout status  deployment -n app-web --timeout=180s
kubectl rollout status  deployment -n app-was --timeout=180s

# ── 8. ALB DNS 대기 ────────────────────────────────────────────────────────────
echo -e "\n[8] ALB DNS 대기 중... (최대 10분)"
ALB_DNS=""
for i in $(seq 1 20); do
    ALB_DNS=$(kubectl get ingress -A \
        -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$ALB_DNS" ]; then
        echo "  ALB DNS 확인: $ALB_DNS"
        break
    fi
    echo "  대기 중... ($i/20)"
    sleep 30
done

if [ -z "$ALB_DNS" ]; then
    echo "ALB DNS가 생성되지 않았습니다. 수동 확인: kubectl get ingress -A"
    exit 1
fi

# ── 9. CloudFront에 ALB 등록 ───────────────────────────────────────────────────
echo -e "\n[9] CloudFront 업데이트"
terraform -chdir="$ROOT/infra/core" init -reconfigure
terraform -chdir="$ROOT/infra/core" apply -auto-approve -var="eks_alb_dns=$ALB_DNS"

echo -e "\n=== DR 배포 완료 ==="
echo "ALB 접속 주소: http://$ALB_DNS"
