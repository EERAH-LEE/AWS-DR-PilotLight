# 실행:
# powershell -ExecutionPolicy Bypass -File "C:\Users\user\Desktop\k8s-lb-script.ps1"
#
# 주로 바꿔야 하는 값:
# 1. ProjectRoot  : 각자 PC의 final_pj_aws 폴더 경로
# 2. ImageTag     : ECR에 실제 존재하는 이미지 태그. 예: blue-11d1934라면 ImageTag는 11d1934
# 3. RdsEndpoint  : 자동 조회가 안 될 때만 직접 입력
# 4. DbUser/DbPassword : DB 계정이 다를 때만 변경

param(
  # [개인별 변경] 각자 프로젝트 폴더 경로
  [string]$ProjectRoot = "C:\Users\user\Desktop\final_pj_aws",

  # [공통] AWS 리전
  [string]$Region = "ap-northeast-2",

  # [공통] EKS 클러스터 이름
  [string]$ClusterName = "azsis-kbeauty-dr-eks",

  # [공통] AWS 계정 ID
  [string]$AccountId = "946775837287",

  # [자동 조회] 비워두면 EKS에서 자동 조회
  [string]$VpcId = "",

  # [공통] AWS Load Balancer Controller IAM Policy ARN
  [string]$AlbPolicyArn = "arn:aws:iam::946775837287:policy/AWSLoadBalancerControllerIAMPolicy",

  # [공통] AWS Load Balancer Controller IAM Role 이름
  [string]$AlbRoleName = "AmazonEKSLoadBalancerControllerRole",

  # [상황별 변경] ECR 이미지 태그. ECR 태그가 blue-11d1934이면 여기는 11d1934만 입력
  [string]$ImageTag = "11d1934",

  # [공통] RDS 인스턴스 ID
  [string]$RdsIdentifier = "mysql-azsis-kbeauty-dr",

  # [자동 조회] 비워두면 RDS에서 자동 조회
  [string]$RdsEndpoint = "",

  # [상황별 변경] DB 이름
  [string]$DbName = "kbeauty",

  # [상황별 변경] DB 사용자
  [string]$DbUser = "azsis",

  # [상황별 변경] DB 비밀번호
  [string]$DbPassword = "kbeauty123!"
)

$ErrorActionPreference = "Stop"

function Step($message) {
  Write-Host ""
  Write-Host "==> $message" -ForegroundColor Cyan
}

function Run($command) {
  Write-Host $command -ForegroundColor DarkGray
  Invoke-Expression $command
}

function RunAllowFail($command) {
  Write-Host $command -ForegroundColor DarkGray
  Invoke-Expression $command
  return $LASTEXITCODE
}

function EnsureAlbServiceAccount() {
  Step "4. Ensure ALB Controller IAM ServiceAccount"

  Run "eksctl utils associate-iam-oidc-provider --region $Region --cluster $ClusterName --approve"

  $createCommand = "eksctl create iamserviceaccount --cluster $ClusterName --region $Region --namespace kube-system --name aws-load-balancer-controller --role-name $AlbRoleName --attach-policy-arn $AlbPolicyArn --approve --override-existing-serviceaccounts"
  Run $createCommand

  $roleArn = "arn:aws:iam::$AccountId`:role/$AlbRoleName"
  $annotation = ""
  try {
    $annotation = kubectl get sa aws-load-balancer-controller -n kube-system -o jsonpath="{.metadata.annotations.eks\.amazonaws\.com/role-arn}" 2>$null
  } catch {
    $annotation = ""
  }

  if ($annotation -ne $roleArn) {
    Write-Host "ServiceAccount annotation is missing or stale. Recreating iamserviceaccount..." -ForegroundColor Yellow
    RunAllowFail "eksctl delete iamserviceaccount --cluster $ClusterName --region $Region --namespace kube-system --name aws-load-balancer-controller --wait"
    Run $createCommand
  }

  Run "kubectl describe sa -n kube-system aws-load-balancer-controller"
}

function EnsureAlbController() {
  Step "5. Install or upgrade ALB Controller"

  if ([string]::IsNullOrWhiteSpace($VpcId)) {
    $script:VpcId = aws eks describe-cluster --region $Region --name $ClusterName --query "cluster.resourcesVpcConfig.vpcId" --output text
  }

  Write-Host "Using VPC ID: $VpcId"

  Run "helm repo add eks https://aws.github.io/eks-charts --force-update"
  Run "helm repo update"
  Run "helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$ClusterName --set region=$Region --set vpcId=$VpcId --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --wait --timeout 5m"
  Run "kubectl rollout restart deployment -n kube-system aws-load-balancer-controller"
  Run "kubectl rollout status deployment -n kube-system aws-load-balancer-controller"
  Run "kubectl get deployment -n kube-system aws-load-balancer-controller"
}

$K8sDir = Join-Path $ProjectRoot "k8s"
$Ecr = "$AccountId.dkr.ecr.$Region.amazonaws.com"
$WebBlueImage = "$Ecr/azsis-kbeauty-dr/web-blue:blue-$ImageTag"
$WasBlueImage = "$Ecr/azsis-kbeauty-dr/was-blue:blue-$ImageTag"

Step "1. Check project path"
if (-not (Test-Path $K8sDir)) {
  throw "K8s directory not found: $K8sDir"
}
Set-Location $K8sDir
Write-Host "Using K8s path: $K8sDir"

Step "2. Connect EKS kubeconfig"
Run "aws eks update-kubeconfig --region $Region --name $ClusterName"
Run "kubectl get nodes"

Step "3. Resolve RDS endpoint and apply DB secret"
if ([string]::IsNullOrWhiteSpace($RdsEndpoint)) {
  $RdsEndpoint = aws rds describe-db-instances --region $Region --db-instance-identifier $RdsIdentifier --query "DBInstances[0].Endpoint.Address" --output text
}

if ([string]::IsNullOrWhiteSpace($RdsEndpoint) -or $RdsEndpoint -eq "None") {
  throw "RDS endpoint was not found. Check RDS identifier: $RdsIdentifier"
}

$DbUrl = "jdbc:mysql://$RdsEndpoint`:3306/$DbName`?useSSL=false&serverTimezone=Asia/Seoul&allowPublicKeyRetrieval=true"
Write-Host "Using RDS endpoint: $RdsEndpoint"

kubectl create secret generic db-secret `
  -n app-was `
  --from-literal=db-url="$DbUrl" `
  --from-literal=db-user="$DbUser" `
  --from-literal=db-password="$DbPassword" `
  --dry-run=client -o yaml | kubectl apply -f -

EnsureAlbServiceAccount
EnsureAlbController

Step "6. Apply Kustomize resources"
Run "kubectl apply -k ."

Step "7. Pin images to existing ECR tags"
Run "kubectl set image deployment/web-blue -n app-web web=$WebBlueImage"
Run "kubectl set image deployment/was-blue -n app-was was=$WasBlueImage"

Step "8. Wait for rollout"
Run "kubectl rollout status deployment web-blue -n app-web"
Run "kubectl rollout status deployment was-blue -n app-was"

Step "9. Check pods"
Run "kubectl get pods -n app-web"
Run "kubectl get pods -n app-was"

Step "10. Check service endpoints"
Run "kubectl get endpoints -n app-web web-active"
Run "kubectl get endpoints -n app-was was-active"

Step "11. Check ingress"
Run "kubectl get ingress -A"

Write-Host ""
Write-Host "Done. If ingress has ADDRESS and both active services have ENDPOINTS, the demo path is ready." -ForegroundColor Green
