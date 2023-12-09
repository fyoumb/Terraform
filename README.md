# Two-Tier Architecture with Terraform

This Terraform project deploys a two-tier infrastructure on Amazon Web Services (AWS) using Terraform. The architecture consists of a public subnet with a web server and a private subnet with a database server. The web server can communicate with the database server, but the database server is not directly accessible from the internet. The database server can access the internet for patching. 

## Prerequisites

Before you begin, ensure that you have the following prerequisites in place:

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- AWS account credentials configured on your machine with the necessary permissions.
- A configured AWS CLI profile (you can use `aws configure` to set this up).

## Usage

1. Clone this repository to your local machine:

   ```shell
   git clone https://github.com/yourusername/terraform-two-tier-architecture.git
   cd terraform-two-tier-architecture

2. Initialize the Terraform workspace: terraform init
3. Format the code: terraform fmt
4. Validate the configuration: terraform validate
5. Review and customize the terraform.tfvars file to set your desired values such as region, VPC CIDR blocks, and instance types.
6. Create an execution plan to review the changes that Terraform will make: terraform plan
7. Apply the Terraform configuration to create the infrastructure: terraform apply
8. Confirm the execution by typing yes when prompted or add "--auto-approve" to the command
9. Once the deployment is complete, Terraform will display the public IP of the web server and the private IP of the database server.

## Cleaning Up

To destroy the created infrastructure and release AWS resources, run: terraform destroy

## Customization

Feel free to customize the Terraform code to fit your specific requirements. You can modify variables, security groups, instance types, and other settings as needed.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

Make sure to replace the placeholder URLs and paths with the actual repository URL and file paths, and customize the prerequisites, usage instructions, and other sections as needed for your specific project.

This `README.md` provides users with essential information about the Terraform project, including how to use it, prerequisites, customization options, and license details.

