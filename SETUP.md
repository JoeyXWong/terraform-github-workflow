# Setup Guide

This guide walks you through setting up the MongoDB Atlas Terraform repository with GitHub Actions.

## Step 1: MongoDB Atlas Setup

### 1.1 Create MongoDB Atlas Account
1. Go to [cloud.mongodb.com](https://cloud.mongodb.com)
2. Sign up for a free account
3. Create an organization (or use existing)

### 1.2 Generate API Keys
1. In MongoDB Atlas, go to **Access Manager** → **Organization Access** → **API Keys**
2. Click **Create API Key**
3. Set description: "Terraform GitHub Actions"
4. Select permissions: **Organization Project Creator**
5. Copy the **Public Key** and **Private Key** (you won't see the private key again!)
6. Add your IP address to the API key access list (or use 0.0.0.0/0 for testing)

### 1.3 Get Organization ID
1. In MongoDB Atlas, go to **Settings**
2. Copy the **Organization ID**

## Step 2: AWS Setup

### 2.1 Create S3 Bucket
```bash
# Replace 'your-unique-bucket-name' with your chosen bucket name
aws s3 mb s3://terraform-mdb

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket-unique-name \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket-unique-name \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

### 2.2 Create OIDC Provider and IAM Role

#### Create OIDC Identity Provider
```bash
# Create OIDC provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

#### Create IAM Role for GitHub Actions
```bash
# Get your GitHub username/organization and repository name
# Replace YOUR_GITHUB_USERNAME and YOUR_REPO_NAME below

cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::770021000383:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:JoeyXWong/terraform-github-workflow:*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name GitHubActionsTerraformRole \
  --assume-role-policy-document file://trust-policy.json

# Create permissions policy
cat > permissions-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::terraform-mdb",
        "arn:aws:s3:::terraform-mdb/*"
      ]
    }
  ]
}
EOF

# Create and attach the policy
aws iam create-policy \
  --policy-name TerraformGitHubActionsPolicy \
  --policy-document file://permissions-policy.json

aws iam attach-role-policy \
  --role-name GitHubActionsTerraformRole \
  --policy-arn arn:aws:iam::770021000383:policy/TerraformGitHubActionsPolicy

# Get the role ARN (save this for GitHub secrets)
aws iam get-role --role-name GitHubActionsTerraformRole --query 'Role.Arn' --output text
```

## Step 3: GitHub Repository Setup

### 3.1 Configure Repository Secrets
Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these repository secrets:

#### AWS OIDC Secret:
- `AWS_ROLE_ARN`: The role ARN from the previous step (e.g., `arn:aws:iam::770021000383:role/GitHubActionsTerraformRole`)

#### MongoDB Atlas Secrets:
- `MONGODB_ATLAS_PUBLIC_KEY`: Your MongoDB Atlas public API key
- `MONGODB_ATLAS_PRIVATE_KEY`: Your MongoDB Atlas private API key  
- `MONGODB_ATLAS_ORG_ID`: Your MongoDB Atlas organization ID

#### Database Passwords:
- `DATABASE_PASSWORD`: Secure password for admin user (generate a strong password)
- `APP_PASSWORD`: Secure password for app user (if using)
- `READONLY_PASSWORD`: Secure password for readonly user (if using)

### 3.2 Configure Environments
1. Go to **Settings** → **Environments**
2. Create environment: `development`
3. Create environment: `production`
4. For production environment, add protection rules:
   - Required reviewers: Add team members
   - Wait timer: 5 minutes (optional)

## Step 4: Update Configuration Files

### 4.1 Update backend.tf
Replace the S3 bucket name in `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket  = "your-terraform-state-bucket-unique-name"  # Update this
    key     = "mongodb-atlas/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

### 4.2 Create terraform.tfvars
Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your values:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

**Note**: `terraform.tfvars` is in `.gitignore` and should never be committed!

## Step 5: Test the Setup

### 5.1 Local Testing (Optional)
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan (requires environment variables)
export TF_VAR_mongodb_atlas_public_key="your-key"
export TF_VAR_mongodb_atlas_private_key="your-key"
export TF_VAR_mongodb_atlas_org_id="your-org-id"
export TF_VAR_database_password="secure-password"

terraform plan
```

### 5.2 GitHub Actions Testing
1. Create a new branch: `git checkout -b test-setup`
2. Make a small change to `main.tf` (add a comment)
3. Commit and push: `git add . && git commit -m "Test setup" && git push origin test-setup`
4. Create a pull request
5. Check that the **Terraform Plan** workflow runs successfully
6. Merge the pull request
7. Check that the **Terraform Apply** workflow runs successfully

## Step 6: Security Considerations

### 6.1 Network Access
The default configuration allows access from any IP (`0.0.0.0/0`). For production:

1. Update `ip_access_cidr` in your `terraform.tfvars`:
```hcl
ip_access_cidr = "YOUR.OFFICE.IP.RANGE/24"
```

2. Or add multiple IP ranges by modifying `main.tf` to create multiple `mongodbatlas_project_ip_access_list` resources.

### 6.2 Passwords
- Use strong, unique passwords for all database users
- Consider using AWS Secrets Manager or similar for password management
- Rotate passwords regularly

### 6.3 API Keys
- Regularly rotate MongoDB Atlas API keys
- Use principle of least privilege for all access

## Troubleshooting

### Common Issues

1. **S3 Backend Access Denied**
   - Verify IAM role has S3 permissions
   - Check bucket name in `backend.tf`
   - Ensure bucket exists in the correct region
   - Verify OIDC provider is correctly configured

2. **OIDC Authentication Errors**
   - Check `AWS_ROLE_ARN` secret is correctly set
   - Verify trust policy allows your GitHub repository
   - Ensure OIDC provider thumbprints are current

3. **MongoDB Atlas API Errors**
   - Verify API keys are correct
   - Check organization ID
   - Ensure IP whitelist includes GitHub Actions IPs (or use 0.0.0.0/0)

3. **GitHub Actions Failures**
   - Check all secrets are configured correctly
   - Verify environment permissions
   - Review action logs for specific error messages

### Getting Help

- MongoDB Atlas: [docs.atlas.mongodb.com](https://docs.atlas.mongodb.com)
- Terraform MongoDB Atlas Provider: [registry.terraform.io/providers/mongodb/mongodbatlas](https://registry.terraform.io/providers/mongodb/mongodbatlas)
- GitHub Actions: [docs.github.com/en/actions](https://docs.github.com/en/actions)

## Next Steps

After successful setup:

1. **Customize**: Modify variables and configuration for your specific needs
2. **Scale**: Add additional clusters or databases as needed
3. **Monitor**: Set up MongoDB Atlas alerts and monitoring
4. **Backup**: Configure backup policies (free tier has limited options)
5. **Security**: Implement additional security measures as needed