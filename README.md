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

`terraform init`
- It's the inception of all the providers, plugins, and modules that your Terraform code needs to create resources.
- And you won't be able to deploy anything without executing this command first.
- It initializes your Terraform project's working folder, and downloads the required plugins from the appropriate registry or repository. 
- As other stages of Terraform deployment require provider, plugins, and modules, this command needs to be run first! 
- And it is safe to run this command, as it doesn't modify, delete, or update any Terraform code. Though it does update plugins' providers which your Terraform code might be using.

`terraform fmt`
- A command to organize and beautify your Terraform template is Terraform format.
- As the name implies, it's going to format your code to keep it consistent by checking the formatting against compliance standards.
- And it is a good thing to run if your teams are working on the same project and pushing to version control systems, such as Git.
- This command is also safe to run at any stage of the project.
- It will only arrange your Terraform code in place, but will not modify the actual code.

`terraform validate`
- As the name implies, Terraform validate checks your Terraform code
for syntax mistakes and internal consistency, for example, typos and misconfigured resources, where a parameter might be wrong in a given resource.
- This command **depends on** Terraform init being run
at least once before it can execute. Otherwise, it'll give an error. And also, this command is safe to run at any time, as it only makes recommendations, warnings, and outputs errors in your Terraform code.

`terraform plan`
- This is the command you'll find yourself executing a lot.
- Terraform plan creates the plan of action for Terraform to act on.
- It tests connectivity to provider APIs using the credentials that you provide.
- It also refreshes the state of the resources.
- It does this by calculating the delta between the current and the desired state, which is defined in the Terraform code.
- This is kind of a fail-safe before you actually execute the code
to create real resources. So use it often.
- And finally, the execution plan can be saved to a file
using the `-out` flag.
- However, it will not hide any sensitive information
being passed in the code, and will store that in plain text.
- This execution plan can be directly passed to a Terraform apply command, as it helps save time, so that it doesn't go ahead and create the state of the resources defined in the code every single time.

`terraform apply` (Deploy)
- It applies the changes as suggested by the execution plan.
And by default, it will prompt you one last time before creating real resources, for which you'll need to type "Yes" explicitly,
or change the behavior by passing an optional flag so that you're not prompted.
- By default, Terraform apply will show the current execution strategy if it is not being passed a file containing the execution plan, which shows all the modifications.
- That is, creation, deletion, and update of resources that is needed to achieve the required state defined in the code.


## Terraform Backends
Terraform backends basically determine how the state is stored.
You can either store it locally or remotely in a solution such as AWS S3. By default, the state is stored on your local disk. However, that behavior can be changed. It can be changed via passing the backend configuration to a Terraform block in your Terraform project code.
However, one thing to note is that variables **cannot** be used
as input to the Terraform block.
Now this takes away from the flexibility of being able to interpolate variables inside this block, however this is a much requested feature and HashiCorp might enable this in the future.

Now lets create an AWS S3 bucket from the terminal under project folder with the following command: 
``` 
aws s3api create-bucket --bucket a_unique_bucket_name --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
``` 
*Note: The bucket name must be unique and you can change your region.*

Now copy the name you just gave the bucket and put it to bucket feature in the file `backend.tf`. Don't forget to give the region name you created the S3 bucket in to the feeature `region` in the same file.

Now remember, the very first command that we need to run to initialize the backend is Terraform init. So let's go ahead and do that.

Now let's go ahead and use Terraform format to make sure that our code is beautiful and consistent.

And we have successfully configured our S3 backend.
Now moving into the future, whenever you run Terraform apply, it's going to upload the state file to the S3 bucket.
And even if you lose your system or something goes bad, you'll still be able to get your state file and continue on with the project, knowing what the last state of your project was.
