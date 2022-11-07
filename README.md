This repository includes AWS deployment by using [Terraform](https://www.terraform.io/).

## Setting Up Terraform

- Download and install the Terraform binary for your OS from [Hashicorp website](https://www.terraform.io/downloads).
- Place it in the `PATH` of the OS for ease of access.
- Test and verify the binary.

## Setting Up the Environment (AWS CLI and Ansible)

- Depending on the OS, install Python's `pip` (Pythons' package installer) using whatever method (yum, apt-get, dnf etc.) is available for the OS.
    - In my case, I am using Ubuntu: ```sudo apt-get install python3-pip```
- Use pip to install AWS CLI and Ansible.
    - ```pip3 install awscli --user``` (verify the installation: aws --version)
    - ```pip3 install ansible --user``` (sudo apt install ansible)(verify the installation: ansible --version)
- Create a preconfigured Ansible config file (you can find it as `ansible.cfg` file).
- Configure AWS CLI (aws configure).
    - ```aws configure``` and type your AWS Access Key ID, AWS Secret Access Key, Default region name (e.g eu-west-1), and Default output format (e.g json). If you don't have AWS Access Key ID and AWS Secret Access Key, please visit [here](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-appendix-sign-up.html) to learn how to have them.
    - To check if cli works type ```aws ec2 describe-instances```

## Setting Up the Environment (AWS IAM Permissions for Terraform)
- Terraform will need permissions to create, update, and delete various AWS resources such as EC2 instances, S3 buckets, load balancers etc.
- We can do either of the following depending on how we are deploying:
    - The very first thing is to create a separate IAM user within your AWS account with the required permissions and then using the access key and the secret access key of that IAM user with the AWS CLI to provide Terraform binary, the permissions to go about and deploy those resources.
    - The other method is to create an EC2 IAM role, which of course attaches to your EC2 instance and provide it with the permissions to go about and deploy the resources that Terraform needs.

**Lets pick the first option.** 
- We have to go to the AWS console, IAM, Policies, Create Policy, pick JSON tab, and paste the policy defined in `terraform_deployment_iam_policy.json` file in this repo. Name it as you wish. I named as `terraformUserPolicy`.
- Now go ahead to the Users, Create User, name it as you wish, I named as `terraformuser`. Check `Programmatic access` Access type. 
- Go ahead `Next: Permissions` and select `Attach existing policies directly`. Find `terraformUserPolicy` and select it.
- Go ahead `Next: Tags` and tag the user as you wish, I tagged as `Name` : `TFPolicy`.
- Go ahead `Next: Review` and create user.

**Lets pick the second option.** 
- We have to go to the AWS console, IAM, Roles, Create role, Select EC2 under AWS service tab.
- Go ahead `Next: Permissions` and search for same policy in first option which is `terraformUserPolicy` and select it.
- Go ahead `Next: Tags` and tag the role as you wish, I tagged as `Name` : `RoleEC2TF`.
- Go ahead `Next: Review`, name it as you wish, I named as `EC2TFRole` and click on `Create role`.

## Understanding Terraform `init`, `fmt`, `validate`, `plan`, and `apply`

`init`
It's the inception of all the providers, plugins, and modules that your Terraform code needs to create resources.
And you won't be able to deploy anything without executing this command first.
It initializes your Terraform project's working folder, and downloads the required plugins from the appropriate registry or repository. As other stages of Terraform deployment require provider, plugins, and modules, this command needs to be run first!