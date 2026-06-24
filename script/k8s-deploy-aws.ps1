param(
  [string]$ProjectRoot = "C:\Users\user\Desktop\final_pj_aws",
  [string]$Region = "ap-northeast-2",
  [string]$ClusterName = "azsis-kbeauty-dr-eks",
  [string]$AccountId = "946775837287",
  [string]$ImageTag = "",
  [string]$VpcId = "",
  [string]$AlbPolicyArn = "arn:aws:iam::946775837287:policy/AWSLoadBalancerControllerIAMPolicy",
  [string]$AlbRoleName = "AmazonEKSLoadBalancerControllerRole",
  [string]$RdsIdentifier = "mysql-azsis-kbeauty-dr",
  [string]$RdsEndpoint = "",
  [string]$DbName = "kbeauty",
  [string]$DbUser = "azsis",
  [string]$DbPassword = "kbeauty123!",
  [switch]$SkipBuildPush,
  [switch]$SkipAlbController
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

function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $name"
  }
}

function Get-ImageTag() {
  if (-not [string]::IsNullOrWhiteSpace($ImageTag)) {
    return $ImageTag
  }

  try {
    $tag = git -C $ProjectRoot rev-parse --short HEAD
    if (-not [string]::IsNullOrWhiteSpace($tag)) {
      return $tag.Trim()
    }
  } catch {
  }

  return (Get-Date -Format "yyyyMMddHHmm")
}

function Ensure-AlbController() {
  Step "Install or upgrade AWS Load Balancer Controller"

  Run "eksctl utils associate-iam-oidc-provider --region $Region --cluster $ClusterName --approve"

  $createCommand = "eksctl create iamserviceaccount --cluster $ClusterName --region $Region --namespace kube-system --name aws-load-balancer-controller --role-name $AlbRoleName --attach-policy-arn $AlbPolicyArn --approve --override-existing-serviceaccounts"
  Run $createCommand

  if ([string]::IsNullOrWhiteSpace($VpcId)) {
    $script:VpcId = aws eks describe-cluster --region $Region --name $ClusterName --query "cluster.resourcesVpcConfig.vpcId" --output text
  }

  Run "helm repo add eks https://aws.github.io/eks-charts --force-update"
  Run "helm repo update"
  Run "helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$ClusterName --set region=$Region --set vpcId=$VpcId --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --wait --timeout 5m"
  Run "kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=5m"
}

function Build-And-Push($name, $dockerfile, $context, $remoteImage) {
  Step "Build and push $name"
  Run "docker build -t ${name}:latest -f `"$dockerfile`" `"$context`""
  Run "docker tag ${name}:latest $remoteImage"
  Run "docker push $remoteImage"
}

$K8sDir = Join-Path $ProjectRoot "k8s"
if (-not (Test-Path $K8sDir)) {
  throw "K8s directory not found: $K8sDir"
}

Require-Command aws
Require-Command kubectl
Require-Command docker
if (-not $SkipAlbController) {
  Require-Command eksctl
  Require-Command helm
}

$ResolvedImageTag = Get-ImageTag
$Ecr = "$AccountId.dkr.ecr.$Region.amazonaws.com"

$Images = @{
  WebBlue = "$Ecr/azsis-kbeauty-dr/web-blue:blue-$ResolvedImageTag"
  WebGreen = "$Ecr/azsis-kbeauty-dr/web-green:green-$ResolvedImageTag"
  WasBlue = "$Ecr/azsis-kbeauty-dr/was-blue:blue-$ResolvedImageTag"
  WasGreen = "$Ecr/azsis-kbeauty-dr/was-green:green-$ResolvedImageTag"
}

Step "Deployment image tag"
Write-Host "ImageTag: $ResolvedImageTag" -ForegroundColor Green
$Images.GetEnumerator() | Sort-Object Name | ForEach-Object {
  Write-Host "$($_.Name): $($_.Value)"
}

Step "Connect EKS kubeconfig"
Run "aws eks update-kubeconfig --region $Region --name $ClusterName"
Run "kubectl get nodes"

if (-not $SkipBuildPush) {
  Step "Login to ECR"
  Run "aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Ecr"

  Build-And-Push "final-pj-web-blue" `
    (Join-Path $ProjectRoot "k8s\web\image_build\blue\Dockerfile") `
    (Join-Path $ProjectRoot "app\web_blue") `
    $Images.WebBlue

  Build-And-Push "final-pj-web-green" `
    (Join-Path $ProjectRoot "k8s\web\image_build\green\Dockerfile") `
    (Join-Path $ProjectRoot "app\web_green") `
    $Images.WebGreen

  Build-And-Push "final-pj-was-blue" `
    (Join-Path $ProjectRoot "k8s\was\image_build\blue\Dockerfile") `
    $ProjectRoot `
    $Images.WasBlue

  Build-And-Push "final-pj-was-green" `
    (Join-Path $ProjectRoot "k8s\was\image_build\green\Dockerfile") `
    $ProjectRoot `
    $Images.WasGreen
}

Step "Apply namespaces first"
Run "kubectl apply -f `"$K8sDir\namespace.yaml`""

Step "Resolve RDS endpoint and apply DB secret"
if ([string]::IsNullOrWhiteSpace($RdsEndpoint)) {
  $RdsEndpoint = aws rds describe-db-instances --region $Region --db-instance-identifier $RdsIdentifier --query "DBInstances[0].Endpoint.Address" --output text
}

if ([string]::IsNullOrWhiteSpace($RdsEndpoint) -or $RdsEndpoint -eq "None") {
  throw "RDS endpoint was not found. Check RDS identifier: $RdsIdentifier"
}

$DbUrl = "jdbc:mysql://$RdsEndpoint`:3306/$DbName`?useSSL=false&serverTimezone=Asia/Seoul&allowPublicKeyRetrieval=true"
kubectl create secret generic db-secret `
  -n app-was `
  --from-literal=db-url="$DbUrl" `
  --from-literal=db-user="$DbUser" `
  --from-literal=db-password="$DbPassword" `
  --dry-run=client -o yaml | kubectl apply -f -

if (-not $SkipAlbController) {
  Ensure-AlbController
}

Step "Apply Kubernetes resources"
Run "kubectl apply -k `"$K8sDir`""

Step "Pin all deployment images"
Run "kubectl set image deployment/web-blue -n app-web web=$($Images.WebBlue)"
Run "kubectl set image deployment/web-green -n app-web web=$($Images.WebGreen)"
Run "kubectl set image deployment/was-blue -n app-was was=$($Images.WasBlue)"
Run "kubectl set image deployment/was-green -n app-was was=$($Images.WasGreen)"

Step "Wait for rollouts"
Run "kubectl rollout status deployment/web-blue -n app-web --timeout=5m"
Run "kubectl rollout status deployment/web-green -n app-web --timeout=5m"
Run "kubectl rollout status deployment/was-blue -n app-was --timeout=5m"
Run "kubectl rollout status deployment/was-green -n app-was --timeout=5m"

Step "Final status"
Run "kubectl get pods -n app-web -o wide"
Run "kubectl get pods -n app-was -o wide"
Run "kubectl get endpoints -n app-web"
Run "kubectl get endpoints -n app-was"
Run "kubectl get ingress -A"

Write-Host ""
Write-Host "Done. Deployed image tag: $ResolvedImageTag" -ForegroundColor Green
