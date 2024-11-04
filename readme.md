## Required tools
### AWS
The AWS CLI is required to authenticate with the AWS account resources are being deployed. It can be downloaded from https://aws.amazon.com/cli/
### Terraform
If you dont have terraform installed on your machine, go to https://developer.hashicorp.com/terraform/install to get an installation. This repo was made with terraform v1.9.8, and will be the most stable using that version
## Setup
### Remote State
Before deploying, a remote state needs to be set up on the AWS account being used. This serves as a remote place to store the terraform state, which is used on each deployment to identify changes. The remote state only needs to be deployed once.  

To deploy the remote state, use the following script (relative to this repo's root directory)
```sh
sh scripts/deploy-remote-state.sh <project_name> [region]
```
(If region is not specified, it defaults to "us-east-1")
## Deploying
### Infrastructure
The `infrastructure` folder contains the terraform resource definitions for the actual infrastructure used by projects. It's a single set of files that gets used between different workspaces, terraform's way of isolating environments.
### Deploy workspace
In order to deploy the terraform infra, a workspace needs to be created, selected, and resource definitions applied to. The following script serves as convenience for creating scripts to facilitate these commands:
```sh
sh scripts/new-workspace.sh <workspace>
```
Using `dev` as the workspace - for example - will create a `deploy-dev.sh` in the root directory, which can be called to deploy to that respective environment. It will also create a tfvars file for that environment in the `infrastructure/environments/` folder, by making a copy of the `example.tfvars` in that same folder. The variables must be set before using the deploy script