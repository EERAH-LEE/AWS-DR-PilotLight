# AWS DR Architecture Memo

## Existing AWS Base

The remote `main` branch already contains the AWS DR foundation:

- VPC and EKS/RDS subnets in `modules/network`
- RDS and DMS security groups in `modules/security`
- RDS, DMS, Route53, S3, and CloudFront modules

This branch adds ECR and EKS without removing the existing DR modules.

## Azure Main Baseline

The AWS work follows the Azure main project naming and workload layout:

| Item | Azure main |
| --- | --- |
| org | `azsis` |
| project | `kbeauty` |
| environment | `dev` |
| Azure namespace | `azsis-kbeauty-dev` |
| AWS DR namespace in this repo | `azsis-kbeauty-dr` |
| Azure region | `koreacentral` |
| AWS region | `ap-northeast-2` |

## Added AWS Resources

| Azure resource | AWS DR addition |
| --- | --- |
| ACR | ECR repositories |
| AKS | EKS cluster |
| AKS node pool `mgmtnp` | EKS node group `mgmtnp` |
| AKS node pool `appnp` | EKS node group `appnp` |
| AKS node pool `monnp` | EKS node group `monnp` |
| Azure NSG for AKS | EKS security groups in `modules/security` |

## Node Group Mapping

| Node group | Purpose | Size |
| --- | --- | --- |
| `mgmtnp` | `workload=system`, `purpose=core` | min 2, max 3 |
| `appnp` | `workload=app`, `purpose=web-was` | min 2, max 8 |
| `monnp` | `workload=monitoring`, `purpose=observability` | min 1, max 3 |

## Next Steps

1. Run Terraform formatting and validation after Terraform is installed.
2. Run `terraform plan` from `infra`.
3. Review existing CloudFront/S3 module wiring before apply.
4. After EKS is created, configure kubectl and install Whatap.
