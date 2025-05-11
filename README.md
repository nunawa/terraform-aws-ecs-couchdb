# Terraform AWS ECS CouchDB

This Terraform module deploys an Apache CouchDB instance on AWS ECS (EC2 launch type).

## Prerequisites

* [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
* [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials and region.
* An S3 bucket for storing Terraform state. The default configuration in `main.tf` expects a bucket named `ecs-couchdb-tfstate` in the `ap-northeast-1` region. You may need to create this bucket manually or update the `backend "s3"` configuration in `main.tf`.

## Configuration

Clone the repository:

```bash
git clone <repository_url>
cd terraform-aws-ecs-couchdb
```

Create `terraform.tfvars`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

You **must** set the following variables in `terraform.tfvars`:

* `ssh_access_cidr`
  * CIDR block(s) allowed for SSH access to the EC2 instance.
* `couchdb_access_cidr`
  * CIDR block(s) allowed to access CouchDB.
* `couchdb_admin_user`
  * Administrator username for CouchDB.
* `couchdb_admin_password`
  * Administrator password for CouchDB.

Refer to `variables.tf` for other configurable variables and their descriptions.

## Deployment

Initialize Terraform:

```bash
terraform init
```

Plan the deployment:

```bash
terraform plan
```

Review the plan to ensure it matches your expectations.

Apply the configuration:

```bash
terraform apply
```

Enter `yes` when prompted to confirm the deployment.

## Outputs

After successful deployment, Terraform will output the following:

* `ecs_instance_public_ip`
  * The public IP address of the EC2 instance hosting the ECS tasks.

You can access these outputs anytime using:

```bash
terraform output
```

## Accessing CouchDB

Once deployed, CouchDB will be accessible via the public IP of the ECS instance on port `5984`.

* CouchDB URL
  * `http://<ecs_instance_public_ip>:5984/`
* Admin Username
  * The value you set for `couchdb_admin_user`.
* Admin Password
  * The value you set for `couchdb_admin_password`.

## Cleanup

To remove the resources created by this Terraform module, run:

```bash
terraform destroy
```

Enter `yes` when prompted.

## License

This project is licensed under the [MIT License](LICENSE).
