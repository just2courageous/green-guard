param(
  [Parameter(Mandatory=$true)] [string]$AccountId,
  [Parameter(Mandatory=$true)] [string]$RepoOwner,
  [Parameter(Mandatory=$true)] [string]$RepoName,
  [string]$Region = "us-east-2",
  [string]$EcrRepoName = "green-guard"
)

Write-Host "Using AccountId=$AccountId, Region=$Region, Repo=$RepoOwner/$RepoName, ECR Repo=$EcrRepoName" -ForegroundColor Cyan

# ---------- 1) Ensure the GitHub OIDC provider exists ----------
$oidc = aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text 2>$null
if ($oidc -notmatch "oidc-provider/token.actions.githubusercontent.com") {
  Write-Host "Creating IAM OIDC provider for GitHub…" -ForegroundColor Yellow
  aws iam create-open-id-connect-provider `
    --url "https://token.actions.githubusercontent.com" `
    --client-id-list "sts.amazonaws.com" `
    --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" | Out-Null
} else {
  Write-Host "OIDC provider already exists." -ForegroundColor Green
}

# ---------- 2) Trust policy for the role (NOTE: ${…} is required in PowerShell here-strings) ----------
$Trust = @"
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::${AccountId}:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:${RepoOwner}/${RepoName}:*"
      }
    }
  }]
}
"@
$Trust | Out-File -FilePath trust.json -Encoding ascii

# ---------- 3) Create role if missing ----------
$roleName = "gh-actions-ecr"
$roleExists = aws iam get-role --role-name $roleName 2>$null
if (-not $?) {
  Write-Host "Creating role $roleName…" -ForegroundColor Yellow
  aws iam create-role `
    --role-name $roleName `
    --assume-role-policy-document file://trust.json | Out-Null
} else {
  Write-Host "Role $roleName already exists. Updating trust policy…" -ForegroundColor Green
  aws iam update-assume-role-policy `
    --role-name $roleName `
    --policy-document file://trust.json | Out-Null
}

# ---------- 4) Minimal inline policy to allow pushing to this ECR repo ----------
$Policy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["ecr:GetAuthorizationToken"], "Resource": "*" },
    { "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "arn:aws:ecr:${Region}:${AccountId}:repository/${EcrRepoName}"
    }
  ]
}
"@
$Policy | Out-File -FilePath ecr-push-policy.json -Encoding ascii

aws iam put-role-policy `
  --role-name $roleName `
  --policy-name ecr-push-inline `
  --policy-document file://ecr-push-policy.json | Out-Null

# ---------- 5) Make sure the ECR repo exists ----------
$repo = aws ecr describe-repositories --repository-names $EcrRepoName --region $Region 2>$null
if (-not $?) {
  Write-Host "Creating ECR repository $EcrRepoName…" -ForegroundColor Yellow
  aws ecr create-repository --repository-name $EcrRepoName --region $Region | Out-Null
} else {
  Write-Host "ECR repository $EcrRepoName already exists." -ForegroundColor Green
}

# ---------- 6) Output values you need ----------
$roleArn = aws iam get-role --role-name $roleName --query "Role.Arn" --output text
$registry = aws ecr describe-registry --region $Region --query "registryId" --output text

Write-Host ""
Write-Host "RoleArn:     $roleArn" -ForegroundColor Cyan
Write-Host "ECR Registry: ${registry}.dkr.ecr.${Region}.amazonaws.com" -ForegroundColor Cyan
