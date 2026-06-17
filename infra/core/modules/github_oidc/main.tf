#------------------------------------------------------
# GitHub OIDC Provider
# AWS가 GitHub Actions의 신원을 검증하는 신뢰 기관 등록
# 계정당 한 번만 만들면 됨
#------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # GitHub Actions가 사용하는 클라이언트 ID
  client_id_list = ["sts.amazonaws.com"]

  # GitHub OIDC 인증서 thumbprint (고정값)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

#------------------------------------------------------
# IAM Role - GitHub Actions용
# GitHub Actions 워크플로우가 이 Role을 임시로 가져다 씀
#------------------------------------------------------
resource "aws_iam_role" "github_actions" {
  name = "role-${var.namespace}-github-actions-dr"

  # 신뢰 정책: 누가 이 Role을 Assume 할 수 있는지
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        # GitHub OIDC Provider만 허용
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # GitHub Actions 토큰 발급처 확인
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # 특정 레포의 main 브랜치에서만 Assume 가능
          # pr이나 다른 브랜치에서는 사용 불가
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

#------------------------------------------------------
# IAM Policy - DR 실행에 필요한 권한
# terraform apply로 EKS, ECR, NAT GW 생성하는 권한
#------------------------------------------------------
resource "aws_iam_role_policy_attachment" "power_user" {
  role       = aws_iam_role.github_actions.name
  # PowerUserAccess: IAM 제외한 대부분의 AWS 서비스 권한
  # IAM 관련 작업(EKS node role 등)도 필요하면 AdministratorAccess로 변경
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# EKS node group용 IAM Role 생성 권한 추가
# PowerUserAccess에 IAM 권한이 없어서 별도 추가
resource "aws_iam_role_policy" "iam_for_eks" {
  role = aws_iam_role.github_actions.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:TagRole"
      ]
      Resource = "*"
    }]
  })
}
