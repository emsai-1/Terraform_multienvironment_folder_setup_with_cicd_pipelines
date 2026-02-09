❌ Dangerous - removes entire environment

Targeted Destroy (This Workflow)
bash
terraform destroy -target=aws_s3_bucket.my_bucket  # Destroys ONLY specified resource
✅ Safe - removes only what you specify

How the Workflow Triggers
Workflow Type: Manual Dispatch
YAML
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Select the environment where the resource exists'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - qa
        - prod
      resource_address:
        description: 'The full address of the single resource to destroy'
        required: true
        type: string
How to Trigger:

Go to GitHub Repository → Actions tab
Select "Terraform Single Resource Destroy" workflow
Click "Run workflow"
Select environment (dev/qa/prod)
Enter the resource address to destroy
Click "Run workflow"
Understanding Resource Addresses
The resource address is how Terraform uniquely identifies a resource in your configuration. The format depends on whether the resource is:

Directly in your Terraform code
Inside a module
Inside a module with multiple instances
Basic Resource Address Format
Code
resource_type.resource_name
Examples:

Resource	Address
S3 Bucket	aws_s3_bucket.main
EC2 Instance	aws_instance.web_server
RDS Database	aws_db_instance.postgres
VPC	aws_vpc.main
Security Group	aws_security_group.app
Scenario 1: Destroying a Simple (Non-Module) Resource
Configuration Example
environments/dev/main.tf

HCL
resource "aws_s3_bucket" "logs" {
  bucket = "my-logs-bucket"
}

resource "aws_s3_bucket" "backups" {
  bucket = "my-backups-bucket"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "WebServer"
  }
}
Step 1: Identify the Resource to Destroy
Let's say you want to destroy the logs S3 bucket.

Resource Address:

Code
aws_s3_bucket.logs
Step 2: Trigger the Workflow
Go to Actions → "Terraform Single Resource Destroy"
Click "Run workflow"
Environment: Select dev
Resource Address: Enter aws_s3_bucket.logs
Click "Run workflow"
Step 3: What Happens
The workflow executes:

bash
terraform destroy -auto-approve -target=aws_s3_bucket.logs
Result:

✅ S3 bucket logs is destroyed
✅ S3 bucket backups remains
✅ EC2 instance web remains
✅ All other resources unaffected
Scenario 2: Destroying a Resource Inside a Module
When resources are created through modules, you need to include the module path in the address.

Configuration Example
environments/dev/main.tf

HCL
module "storage" {
  source = "../../modules/s3_storage"
  
  bucket_name = "my-storage-bucket"
  environment = "dev"
}

module "compute" {
  source = "../../modules/ec2_instance"
  
  instance_type = "t2.micro"
  environment   = "dev"
}
modules/s3_storage/main.tf

HCL
resource "aws_s3_bucket" "storage" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
Identifying Resources in Modules
The resource address must include the module path:

Code
module.MODULE_NAME.RESOURCE_TYPE.RESOURCE_NAME
Example Resource Addresses
What to Destroy	Address
S3 bucket inside storage module	module.storage.aws_s3_bucket.storage
Versioning config inside storage module	module.storage.aws_s3_bucket_versioning.storage
EC2 instance inside compute module	module.compute.aws_instance.instance
Destroy S3 Bucket from Module
Environment: dev
Resource Address: module.storage.aws_s3_bucket.storage
Result:

✅ S3 bucket inside storage module destroyed
✅ Versioning configuration remains (depends on Terraform state)
✅ Compute module untouched
Scenario 3: Multiple Resources from Same Module (Critical!)
This is the most complex scenario. When a module creates multiple resources of the same type (e.g., multiple S3 buckets), you need to identify which one to destroy.

Configuration Example
environments/dev/main.tf

HCL
# Using the same module multiple times
module "data_bucket" {
  source = "../../modules/s3_bucket"
  
  bucket_name = "data-bucket"
  environment = "dev"
}

module "logs_bucket" {
  source = "../../modules/s3_bucket"
  
  bucket_name = "logs-bucket"
  environment = "dev"
}

module "archive_bucket" {
  source = "../../modules/s3_bucket"
  
  bucket_name = "archive-bucket"
  environment = "dev"
}
modules/s3_bucket/main.tf

HCL
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.bucket.id
  
  rule {
    id     = "archive-old-versions"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
The Problem: Multiple Instances
When you call the same module multiple times, how do you target a specific instance?

Solution: Use Module Instance Names
Resource Address Format:

Code
module.MODULE_INSTANCE_NAME.RESOURCE_TYPE.RESOURCE_NAME
Example: Destroy Only the Logs Bucket
Address: module.logs_bucket.aws_s3_bucket.bucket

This tells Terraform:

Look inside the logs_bucket module instance
Find the aws_s3_bucket resource
Named bucket
Destroy ONLY that one
Complete Example: Multiple Buckets Scenario
Scenario: You have 3 S3 buckets created by modules. You want to delete the logs bucket, but keep data and archive buckets.

Bucket	Module Instance	Resource Address	Action
Data	data_bucket	module.data_bucket.aws_s3_bucket.bucket	Keep
Logs	logs_bucket	module.logs_bucket.aws_s3_bucket.bucket	Destroy
Archive	archive_bucket	module.archive_bucket.aws_s3_bucket.bucket	Keep
Workflow Inputs:

Environment: dev
Resource Address: module.logs_bucket.aws_s3_bucket.bucket
Result:

✅ Logs bucket destroyed
✅ Data bucket untouched
✅ Archive bucket untouched
Scenario 4: Nested Modules (Module Calling Another Module)
When modules call other modules, the path gets longer.

Configuration Example
environments/dev/main.tf

HCL
module "infrastructure" {
  source = "../../modules/infrastructure"
}
modules/infrastructure/main.tf

HCL
module "storage" {
  source = "../storage"
}
modules/storage/main.tf

HCL
resource "aws_s3_bucket" "data" {
  bucket = "data-bucket"
}
Resource Address for Nested Module
Address: module.infrastructure.module.storage.aws_s3_bucket.data

The path follows the nesting hierarchy:

Code
module.PARENT_MODULE.module.CHILD_MODULE.RESOURCE_TYPE.RESOURCE_NAME
Scenario 5: Module with count or for_each
When modules use count or for_each to create multiple instances, the syntax changes.

Using count
environments/dev/main.tf

HCL
module "buckets" {
  count  = 3
  source = "../../modules/s3_bucket"
  
  bucket_name = "bucket-${count.index}"
}
Resource Address with count
Format:

Code
module.MODULE_NAME[INDEX].RESOURCE_TYPE.RESOURCE_NAME
Examples:

First bucket: module.buckets[0].aws_s3_bucket.bucket
Second bucket: module.buckets[1].aws_s3_bucket.bucket
Third bucket: module.buckets[2].aws_s3_bucket.bucket
Using for_each
environments/dev/main.tf

HCL
module "buckets" {
  for_each = {
    data    = "data-bucket"
    logs    = "logs-bucket"
    archive = "archive-bucket"
  }
  
  source      = "../../modules/s3_bucket"
  bucket_name = each.value
}
Resource Address with for_each
Format:

Code
module.MODULE_NAME["KEY"].RESOURCE_TYPE.RESOURCE_NAME
Examples:

Data bucket: module.buckets["data"].aws_s3_bucket.bucket
Logs bucket: module.buckets["logs"].aws_s3_bucket.bucket
Archive bucket: module.buckets["archive"].aws_s3_bucket.bucket
Finding the Correct Resource Address
Method 1: Check Terraform State
bash
cd environments/dev
terraform state list
Output:

Code
module.storage.aws_s3_bucket.storage
module.storage.aws_s3_bucket_versioning.storage
module.compute.aws_instance.instance
aws_vpc.main
Copy the exact address from the state list.

Method 2: Check terraform.tfstate File
bash
cat terraform.tfstate | grep -i "resource_address"
Method 3: Look at Configuration Files
Review your .tf files and trace:

The module instance name
The resource type
The resource name
Step-by-Step Examples
Example 1: Delete a Specific S3 Bucket from Multiple Buckets
Situation: You have 3 S3 buckets created by separate module calls. You want to delete only the logs bucket.

Configuration:

HCL
module "data_bucket" {
  source = "../../modules/s3_bucket"
  bucket_name = "my-data-bucket"
}

module "logs_bucket" {
  source = "../../modules/s3_bucket"
  bucket_name = "my-logs-bucket"
}

module "archive_bucket" {
  source = "../../modules/s3_bucket"
  bucket_name = "my-archive-bucket"
}
Steps:

Open GitHub Actions
Select "Terraform Single Resource Destroy"
Run workflow with:
Environment: dev
Resource Address: module.logs_bucket.aws_s3_bucket.bucket
Logs bucket is deleted, others remain
Example 2: Delete One RDS Instance from Multiple Instances Created by count
Situation: You have 3 RDS database instances created using count. You want to delete the second one.

Configuration:

HCL
module "databases" {
  count  = 3
  source = "../../modules/rds_instance"
  
  db_name = "db-${count.index}"
}
Steps:

Open GitHub Actions
Select "Terraform Single Resource Destroy"
Run workflow with:
Environment: qa
Resource Address: module.databases[1].aws_db_instance.database
Second database instance is deleted
Example 3: Delete a Nested Resource from a Module
Situation: A module creates both a security group and a security group rule. You want to delete only the rule.

Configuration:

HCL
# environments/dev/main.tf
module "network" {
  source = "../../modules/network"
}

# modules/network/main.tf
resource "aws_security_group" "app" {
  name = "app-sg"
}

resource "aws_security_group_ingress" "app_http" {
  security_group_id = aws_security_group.app.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
Steps:

Run workflow with:
Environment: dev
Resource Address: module.network.aws_security_group_ingress.app_http
Only the HTTP ingress rule is deleted, security group remains
Workflow Execution
What Happens During Execution
Checkout: Repository code is downloaded
AWS Authentication: Using environment secrets
Terraform Init: Initializes Terraform working directory
Terraform Destroy: Executes targeted destroy
YAML
- name: Destroy SINGLE Targeted Resource
  run: terraform destroy -auto-approve -target=${{ github.event.inputs.resource_address }}
Output
The workflow shows:

Code
module.logs_bucket.aws_s3_bucket.bucket: Destroying... [id=my-logs-bucket]
module.logs_bucket.aws_s3_bucket.bucket: Destroyed successfully
Important Considerations
1. Dependencies Matter
If resource A depends on resource B, you cannot delete A without first handling B.

Example:

HCL
resource "aws_security_group" "app" {
  name = "app-sg"
}

resource "aws_security_group_ingress" "app" {
  security_group_id = aws_security_group.app.id  # Depends on security group
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}
❌ Wrong: You cannot delete aws_security_group.app while the ingress rule exists ✅ Right: First delete ingress rule, then delete security group

2. State File is Critical
The workflow reads your terraform.tfstate file. If state is out of sync with actual AWS resources:

Terraform might try to destroy resources that don't exist (harmless error)
Terraform might not destroy resources that exist in state but not AWS
To sync state:

bash
cd environments/dev
terraform refresh
3. Backup Your State
Before destroying resources, backup your Terraform state:

bash
cp terraform.tfstate terraform.tfstate.backup
4. Dry Run (Plan First)
To see what will be destroyed without actually destroying:

bash
terraform destroy -target=resource_address  # Don't use -auto-approve
# Review the plan, then type 'yes' to confirm
Preventing Accidental Deletions
1. Use Terraform Lifecycle Rules
HCL
resource "aws_s3_bucket" "critical" {
  bucket = "critical-bucket"
  
  lifecycle {
    prevent_destroy = true  # Prevents accidental deletion
  }
}
When you try to destroy this, Terraform will error:

Code
Error: Resource has lifecycle.prevent_destroy set, but the plan calls for this resource to be destroyed.
2. Enable GitHub Branch Protection
Require approvals before allowing workflow execution on production.

3. Use separate AWS credentials
Use least-privilege IAM policies for different environments.

4. Document Critical Resources
Keep a list of resources that should never be deleted.

Troubleshooting
Problem: "Resource not found in state"
Cause: The resource address doesn't match the state file

Solution:

bash
terraform state list  # Find correct address
Problem: "Resource has dependencies"
Cause: Other resources depend on this resource

Solution:

Destroy dependent resources first
Use -target flag to destroy in correct order
Problem: Workflow fails with AWS auth error
Cause: AWS credentials in GitHub secrets are incorrect or expired

Solution:

Go to Settings → Environments → [environment]
Verify AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
Generate new credentials if needed
Problem: State file out of sync
Cause: Resources were deleted manually in AWS without Terraform

Solution:

bash
terraform refresh  # Update state to match actual AWS
terraform state rm module.x.aws_s3_bucket.y  # Remove from state if needed
Best Practices
✅ Always test in dev first - Delete in dev, then qa, then prod
✅ Use terraform state list - Verify address before destroying
✅ Document reasons - Comment PR when destroying production resources
✅ Review dependencies - Check what depends on the resource
✅ Backup state - Keep backups before major operations
✅ Use lifecycle rules - Protect critical resources from deletion
✅ Require approvals - For production environment changes
✅ Tag resources properly - Makes identification easier
Common Resource Addresses Reference
Direct Resources (Non-Module)
Code
aws_s3_bucket.my_bucket
aws_instance.web_server
aws_rds_cluster.main
aws_vpc.main
aws_security_group.app
aws_security_group_ingress.ssh
aws_lambda_function.processor
aws_api_gateway_rest_api.api
Module Resources (Single Instance)
Code
module.storage.aws_s3_bucket.bucket
module.compute.aws_instance.server
module.database.aws_rds_cluster.main
module.network.aws_vpc.vpc
Module Resources (with count)
Code
module.buckets[0].aws_s3_bucket.bucket
module.instances[1].aws_instance.server
module.databases[2].aws_rds_cluster.main
Module Resources (with for_each)
Code
module.buckets["data"].aws_s3_bucket.bucket
module.instances["web"].aws_instance.server
module.databases["postgres"].aws_rds_cluster.main
Nested Module Resources
Code
module.infrastructure.module.storage.aws_s3_bucket.bucket
module.platform.module.database.aws_rds_cluster.main
Summary
The destroy_single_resource.yml workflow provides surgical-precision resource deletion in your Terraform-managed infrastructure. By understanding resource addresses—especially for modules and multiple instances—you can safely remove specific resources without affecting the rest of your environment.

Remember: Always verify the resource address, understand dependencies, and test in dev before destroying production resources!

Code

This comprehensive guide covers:

1. **How the workflow works** - Manual dispatch, selecting environment and resource
2. **Resource address formats** - Simple, module, nested module, count, for_each
3. **5 detailed scenarios** with examples:
   - Simple non-module resources
   - Resources inside modules
   - Multiple resources from same module (most important!)
   - Nested modules
   - Modules with count/for_each
4. **Real-world step-by-step examples** for common tasks
5. **Finding correct resource addresses** - Methods to identify what to destroy
6. **Important considerations** - Dependencies, state, backups
7. **Preventing accidental deletions** - Best practices
8. **Troubleshooting guide** - Common problems and solutions
9. **Reference material** - Common resource address patterns

This is specifically tailored to answering your question about destroying single resource
