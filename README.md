Make these code changes?
README.md

md
# Terraform Multi-Environment CI/CD Pipeline

## Overview

The `terraform.yml` workflow is a **multi-environment infrastructure-as-code (IaC) pipeline** that automatically manages Terraform deployments across three environments: **dev**, **qa**, and **prod**. It intelligently routes your Terraform code to the correct environment folder based on which Git branch you're working on.

---

## How the Pipeline Works: Branch → Environment → Folder Mapping

### The Dynamic Environment Selection

The pipeline uses **conditional logic** to automatically select the correct environment and working directory based on the branch name:

```yaml
environment:
  name: ${{ (github.ref == 'refs/heads/main' && 'prod') || 
           (startsWith(github.ref, 'refs/heads/release/') && 'qa') || 
           'dev' }}

defaults:
  run:
    working-directory: ${{ (github.ref == 'refs/heads/main' && 'environments/prod') || 
                          (startsWith(github.ref, 'refs/heads/release/') && 'environments/qa') || 
                          'environments/dev' }}
Branch-to-Environment Routing Table
Git Branch	Environment	Working Directory	Purpose
develop	dev	environments/dev	Development/Testing environment
release/*	qa	environments/qa	Quality Assurance & Staging
main	prod	environments/prod	Production environment
Example Scenarios
Scenario 1: Feature Branch → Dev Environment
Code
Developer pushes to: develop branch
↓
Pipeline automatically selects: dev environment
↓
Works with: environments/dev/ folder
↓
Terraform manages: dev infrastructure
Scenario 2: Release Preparation → QA Environment
Code
Developer pushes to: release/v1.2.0 branch
↓
Pipeline automatically selects: qa environment
↓
Works with: environments/qa/ folder
↓
Terraform manages: qa infrastructure
Scenario 3: Production Deployment → Prod Environment
Code
Developer pushes to: main branch
↓
Pipeline automatically selects: prod environment
↓
Works with: environments/prod/ folder
↓
Terraform manages: prod infrastructure
Pipeline Trigger Events
The pipeline is triggered in two scenarios:

1. On Push Events (Automatic Execution)
YAML
on:
  push:
    branches:
      - main
      - release/*
      - develop
Triggers automatically when code is pushed to these branches:

main → Produces a plan AND applies changes (Merge to production)
release/ → Produces a plan AND applies changes (Release to QA)
develop → Produces a plan AND applies changes (Development)
2. On Pull Request Events (Plan Only - No Apply)
YAML
on:
  pull_request:
    branches:
      - main
      - release/*
      - develop
Triggers when a PR is opened targeting these branches:

Produces a Terraform plan showing what will change
Does NOT apply the changes
Plan is posted as a comment on the PR for review
Changes only apply AFTER the PR is merged
The Two-Phase Workflow: Plan vs Apply
Phase 1: Terraform Plan (Always Runs)
YAML
- name: Terraform Plan
  id: plan
  run: terraform plan -no-color -out=tfplan
  env:
    TF_VAR_environment: ${{ vars.ENVIRONMENT }}
    TF_VAR_cpu: ${{ vars.CPU }}
What happens:

Reads your Terraform configuration
Queries the current AWS infrastructure state
Compares desired state (.tf files) vs actual state (AWS)
Generates a tfplan file showing exactly what will change
When it runs:

✅ On every PR (reviewable before merge)
✅ On every Push to main/release/develop
Output:

Shows resources to be created, modified, or destroyed
Allows team review before anything is changed
Phase 2: Terraform Apply (Only on Push, Not on PR)
YAML
- name: Terraform Apply
  if: github.event_name == 'push' && 
      (github.ref == 'refs/heads/main' || 
       startsWith(github.ref, 'refs/heads/release/') || 
       github.ref == 'refs/heads/develop')
  run: terraform apply -auto-approve tfplan
  env:
    TF_VAR_environment: ${{ vars.ENVIRONMENT }}
    TF_VAR_cpu: ${{ vars.CPU }}
What happens:

Takes the tfplan file generated from the plan phase
Applies the infrastructure changes to AWS
Creates, modifies, or destroys actual resources
Critical Condition:

Code
IF: github.event_name == 'push'
This means:

✅ Apply runs on direct pushes to main/release/develop
❌ Apply DOES NOT run on Pull Requests
Complete Workflow Example: Creating a New Resource
Step 1: Developer Creates a Feature Branch
bash
git checkout -b feature/new-vpc develop
# Modify: environments/dev/main.tf
# Add: New VPC resource
git add .
git commit -m "Add new VPC to dev"
Step 2: Push and Create Pull Request
bash
git push origin feature/new-vpc
# Open Pull Request → feature/new-vpc → develop
Pipeline Action:

✅ Triggers on PR creation
✅ Runs Terraform Plan
✅ Shows new VPC will be created
❌ Does NOT apply changes yet
💬 Posts plan as PR comment for review
Code
Plan: 1 to add, 0 to change, 0 to destroy
+ aws_vpc.main
    cidr_block = "10.0.0.0/16"
    ...
Step 3: Code Review and Approval
Team reviews the Terraform plan
Confirms the changes are correct
Approves the PR
Step 4: Merge to Develop
bash
# PR merged into develop branch
Pipeline Action:

✅ Triggers on merge (push event)
✅ Runs Terraform Plan again (double-check)
✅ Runs Terraform Apply (ACTUAL RESOURCES CREATED)
✅ New VPC is now created in AWS dev environment
Step 5: Promotion to QA (Release Branch)
bash
git checkout -b release/v1.0 develop
git push origin release/v1.0
Pipeline Action:

✅ Runs against environments/qa/ folder
✅ Creates the SAME infrastructure in QA
✅ Applies immediately (because it's a push)
Step 6: Production Deployment
bash
git checkout main
git merge release/v1.0
git push origin main
Pipeline Action:

✅ Runs against environments/prod/ folder
✅ Creates the infrastructure in production
✅ Applies immediately
Why This Two-Phase Approach?
Benefits of Plan → Review → Apply
Aspect	Benefit
Safety	Prevents accidental infrastructure changes
Visibility	Everyone sees what will change before it happens
Auditability	Changes are reviewed and approved
Rollback Friendly	If plan looks wrong, just don't merge the PR
Multi-Env Consistency	Same code deployed to dev, qa, and prod
File Structure and Environment Isolation
Code
your-repo/
├── .github/
│   └── workflows/
│       ├── terraform.yml              # Main CI/CD pipeline
│       ├── destroy.yml                # Destroy all resources workflow
│       └── destroy_single_resource.yml # Destroy specific resource workflow
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars           # Dev-specific values
│   ├── qa/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars           # QA-specific values
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars           # Production-specific values
└── modules/
    ├── vpc/
    ├── security_group/
    └── rds/                           # Shared Terraform modules
How Each Environment is Isolated
Each environment folder has its own terraform.tfvars:

environments/dev/terraform.tfvars

HCL
environment = "dev"
instance_type = "t2.micro"        # Cheap for testing
instance_count = 1
environments/qa/terraform.tfvars

HCL
environment = "qa"
instance_type = "t2.small"        # Better specs
instance_count = 2
environments/prod/terraform.tfvars

HCL
environment = "prod"
instance_type = "t3.medium"       # High performance
instance_count = 3                # High availability
backup_enabled = true
Understanding the Pipeline Steps
1. Checkout Code
YAML
- name: Checkout
  uses: actions/checkout@v4
Downloads the repository code to the GitHub Actions runner.

2. Debug Environment Variables
YAML
- name: Debug Environment Variables
  run: |
    echo "The selected AWS Region is: ${{ vars.AWS_REGION }}"
    echo "The selected Environment is: ${{ vars.ENVIRONMENT }}"
Displays which environment was selected (helpful for troubleshooting).

3. Verify Dynamic Selections
YAML
- name: Verify Dynamic Selections
  run: |
    echo "Current Branch: ${{ github.ref_name }}"
    echo "Selected Environment Name: ${{ ... }}"
Confirms the branch-to-environment mapping is working correctly.

4. Configure AWS Credentials
YAML
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}
Authenticates to AWS using credentials stored in GitHub Environment Secrets.

5. Setup Terraform
YAML
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
Installs Terraform on the runner.

6. Terraform Init
YAML
- name: Terraform Init
  run: terraform init
Initializes the Terraform working directory, downloads providers and modules.

7. Terraform Plan
YAML
- name: Terraform Plan
  run: terraform plan -no-color -out=tfplan
Generates execution plan without applying changes. Output saved to tfplan file.

8. Terraform Apply (Only on Push)
YAML
- name: Terraform Apply
  if: github.event_name == 'push' && (...)
  run: terraform apply -auto-approve tfplan
Applies the plan from step 7, but only if triggered by a push event (not on PR).

Key Configuration Details
Permissions
YAML
permissions:
  contents: read
  pull-requests: write
contents: read → Pipeline can read the repository code
pull-requests: write → Pipeline can write plan output to PR comments
Environment Configuration
YAML
environment:
  name: ${{ ... }}
Specifies which GitHub Environment is used. This is where you store:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
ENVIRONMENT (dev/qa/prod)
CPU (resource specifications)
Each environment should have its own secrets configured in GitHub Settings.

Common Scenarios
Scenario A: Bug Fix in Development
Code
1. git checkout feature/fix-bug develop
2. Make changes to environments/dev/main.tf
3. git push → triggers plan on dev
4. Review plan
5. Create PR
6. Team reviews
7. Merge PR → triggers apply on dev
8. Dev environment updated ✓
Scenario B: Scaling Production
Code
1. git checkout feature/scale-prod main
2. Modify environments/prod/main.tf (increase instance count)
3. Create PR against main
4. Plan shows: +2 new EC2 instances
5. Infrastructure team reviews
6. If approved → merge → apply automatically runs
7. Production is scaled up ✓
Scenario C: Rolling Update Across Environments
Code
1. Feature developed and tested in dev
2. Merge to develop → auto-deploys to dev
3. Create release/v2.0 from develop
4. Push release/v2.0 → auto-deploys to qa
5. Test in qa
6. Merge release/v2.0 into main
7. Push main → auto-deploys to prod
Troubleshooting
Plan shows more changes than expected?
Check if you're on the correct branch
Verify the terraform.tfvars file for your environment
Run terraform plan locally to compare
Apply didn't run?
Verify you pushed to a tracked branch (main/release/develop)
Check that the push event was triggered (not a PR)
Verify AWS credentials in GitHub Environment Secrets
Wrong environment selected?
Check the branch name matches the pattern (release/* for QA)
Verify the conditional logic in the workflow
Use the "Debug Environment Variables" step output
Security Best Practices
Never commit secrets → Use GitHub Environment Secrets
Use separate AWS accounts for dev/qa/prod
Review all plans before merging PRs
Enable branch protection on main/release branches
Require approvals for PRs into production branches
Rotate AWS access keys regularly
Setting Up the Pipeline
Prerequisites
GitHub repository with branch protection rules
AWS account(s) for dev, qa, and prod environments
Terraform configuration in environments/ folder
GitHub Environments configured (dev, qa, prod)
Steps to Configure
Create GitHub Environments

Go to Settings → Environments
Create three environments: dev, qa, prod
Add protection rules (optional but recommended for prod)
Add Secrets to Each Environment

For each environment, add:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
Add Variables to Each Environment

For each environment, add:
ENVIRONMENT (dev/qa/prod)
CPU (t2.micro/t2.small/t3.medium)
Verify Terraform Folder Structure

Code
environments/ ├── dev/ ├── qa/ └── prod/

Code

5. **Test the Pipeline**
   - Create a feature branch from develop
   - Make a small change to `environments/dev/main.tf`
   - Create a PR
   - Verify the plan appears in PR comments

---

## Next Steps

1. Set up separate GitHub Environments (dev, qa, prod)
2. Configure AWS credentials for each environment
3. Create your Terraform code in `environments/dev/`, `environments/qa/`, `environments/prod/`
4. Push to the appropriate branch and watch the magic happen!

---

## Additional Workflows

This repository also includes two additional destruction workflows:

### 1. **destroy.yml** - Destroy All Resources in an Environment
Manual workflow to completely destroy all resources in a selected environment. Useful for cleanup or testing.

### 2. **destroy_single_resource.yml** - Destroy a Specific Resource
Manual workflow to destroy only a single resource in a selected environment. Useful for removing specific infrastructure without affecting others.

---

## Support

For issues or questions about this pipeline setup, please refer to:
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
