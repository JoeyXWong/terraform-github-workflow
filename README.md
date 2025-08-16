# Terraform MongoDB Atlas with GitHub Workflows

This repository provisions a MongoDB Atlas free tier cluster using Terraform with automated CI/CD through GitHub Actions. The Terraform state is stored in an S3 backend for team collaboration.

## Architecture

- **MongoDB Atlas**: Free tier M0 cluster
- **Terraform Backend**: AWS S3 bucket with DynamoDB state locking
- **CI/CD**: GitHub Actions for automated planning and deployment
- **State Management**: Remote state stored in S3 with versioning enabled

## Prerequisites

Before using this repository, ensure you have:

1. **MongoDB Atlas Account**: Sign up at [cloud.mongodb.com](https://cloud.mongodb.com)
2. **AWS Account**: For S3 backend storage
3. **GitHub Repository**: With proper secrets configured

## Required Secrets

Configure the following secrets in your GitHub repository settings:

### MongoDB Atlas
- `MONGODB_ATLAS_PUBLIC_KEY`: Your MongoDB Atlas public API key
- `MONGODB_ATLAS_PRIVATE_KEY`: Your MongoDB Atlas private API key
- `MONGODB_ATLAS_ORG_ID`: Your MongoDB Atlas organization ID

### AWS (for S3 backend)
- `AWS_ACCESS_KEY_ID`: AWS access key with S3 and DynamoDB permissions
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key

## Setup Instructions

### 1. MongoDB Atlas API Keys

1. Log into MongoDB Atlas
2. Go to **Access Manager** → **Organization Access** → **API Keys**
3. Create a new API key with **Organization Project Creator** permissions
4. Note down the public and private keys
5. Add your IP address to the API key whitelist

### 2. AWS Setup

Create an S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket (replace with your unique bucket name)
aws s3 mb s3://your-terraform-state-bucket

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

### 3. Configuration

Update the following files with your specific values:

- `backend.tf`: Update S3 bucket name and region
- `variables.tf`: Modify default values as needed
- `terraform.tfvars`: Create this file with your specific values (not tracked in git)

## File Structure

```
.
├── README.md
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── backend.tf              # S3 backend configuration
├── terraform.tfvars.example # Example variables file
└── .github/
    └── workflows/
        ├── terraform-plan.yml  # PR plan workflow
        └── terraform-apply.yml # Merge apply workflow
```

## Workflows

### Pull Request Workflow
- Triggers on pull requests to main branch
- Runs `terraform plan`
- Comments the plan output on the PR
- Validates Terraform configuration

### Merge Workflow
- Triggers on push to main branch (after PR merge)
- Runs `terraform apply`
- Updates infrastructure automatically

## Usage

1. **Fork/Clone** this repository
2. **Configure** GitHub secrets as described above
3. **Update** `backend.tf` with your S3 bucket details
4. **Create** a `terraform.tfvars` file with your values
5. **Create** a pull request to trigger the plan workflow
6. **Merge** the PR to apply changes

## MongoDB Atlas Resources Created

- **Project**: A new project in your MongoDB Atlas organization
- **Cluster**: M0 free tier cluster with MongoDB 7.0
- **Database User**: Admin user for database access
- **Network Access**: IP whitelist entry (0.0.0.0/0 for development)

## Security Considerations

- The default configuration allows access from any IP (0.0.0.0/0)
- In production, restrict network access to specific IPs
- Use strong passwords for database users
- Enable Atlas security features like encryption at rest

## Customization

Modify `variables.tf` to customize:
- Cluster name and configuration
- AWS region for resources
- Database user credentials
- Network access rules

## Troubleshooting

### Common Issues

1. **API Key Permissions**: Ensure your MongoDB Atlas API key has sufficient permissions
2. **S3 Backend**: Verify bucket exists and AWS credentials have proper permissions
3. **Network Access**: Check MongoDB Atlas network access list configuration

### Logs

Check GitHub Actions logs for detailed error information:
- Go to **Actions** tab in your GitHub repository
- Click on the failed workflow run
- Expand the failed step to see detailed logs

## Cost Estimation

- **MongoDB Atlas M0**: Free tier (no cost)
- **AWS S3**: Minimal cost for state storage (~$0.01-0.05/month)
- **AWS DynamoDB**: Free tier covers state locking for small projects

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Create a pull request
5. Review the Terraform plan output
6. Merge after approval

## License

This project is licensed under the MIT License - see the LICENSE file for details.