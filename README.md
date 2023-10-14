# Protect-azure-web-app-and-azure-sql-with-app-gateway-waf
Deploy a data-driven ASP.NET Core app to Azure App Service and connect to an Azure SQL Database via integrating Azure Application gateway with WAF.

This guide provides step-by-step instructions for deploying an Azure Web App using Terraform. Ensure you follow the steps below to set up and deploy your infrastructure.

**Prerequisites**
To download and install Terraform, Visit the official Terraform website below,
https://developer.hashicorp.com/terraform/downloads

Download the appropriate version for your operating system (MAC or Windows).
Extract the downloaded archive to a directory included in your system's PATH.

**Install Terraform:**
**For MAC:**
Use Homebrew to install Terraform.
sh
brew install terraform

**For Windows:**
Add Terraform Path to System Environment Variables. Follow the below link,
https://phoenixnap.com/kb/how-to-install-terraform

**Open Terraform:**
Open a terminal or command prompt.
Verify the installation by running:

=> terraform --version

**Install Azure CLI & HashiCorp Terraform extensions:**

Install Azure CLI

=> az extension add --name terraform

# Modify terraform.tfvars file
Change the **Azure Subscription ID** from the below line in terraform.tfvars file

app_service_plan_id        = "/subscriptions/fd7a0e48-ef92-4ae6-b1a7-6a62c6dd318d/resourceGroups/amran-rg-web-sql-db-demo-project/providers/Microsoft.Web/serverFarms/amran-appserviceplan-web-21"

# Required Permission of Azure User Account to implement the infrastructure in Azure Portal. 

Assign the permission before running terraform commands.

Subscription level => Access Control (IAM) =>  Owner or Contributor

**Connect to your Azure Subscription:**
Run the following command to log in to your Azure account:

=> az version

=> az login

**Terraform Deployment Steps**
Navigate to the directory containing your Terraform configuration files.

**Run the below command to initialize the Terraform deployment. This command downloads the Azure provider required to manage your Azure resources.**

=> terraform init -upgrade

**Run the below command to create an execution plan.**

=> terraform plan -out main.tfplan

**Run the below command to apply the execution plan to your cloud infrastructure.**

=> terraform apply main.tfplan

Confirm the changes by typing "yes" when prompted.
**Note:** Be cautious when running Terraform Apply as it will make changes to your Azure infrastructure via creating a seperate resource group.

Once the deployment is complete, you should see an output indicating the resources that were created. You can access your Azure Web App based on the configurations provided in your Terraform scripts.

...................................................................................................................................................................................................................
# Deploy sample code to Azure Web App manually with Github Action

In this step, you'll configure GitHub deployment using GitHub Actions. It's just one of many ways to deploy to App Service, but also a great way to have continuous integration in your deployment process. By default, every git push to your GitHub repository will kick off the build and deploy action.

**Step 1:** In a new browser window:

Sign in to your GitHub account.
Navigate to https://github.com/Azure-Samples/msdocs-app-service-sqldb-dotnetcore.
Select **Fork**.
Select Create Fork.

**Step 2:** In the App Service page, in the left menu, select **Deployment Center**.

**Step 3:** In the **Deployment Center** page from Azure web app:

In Source, select GitHub. By default, GitHub Actions is selected as the build provider.
Sign in to your GitHub account and follow the prompt to authorize Azure.
In Organization, select your account.
In Repository, select msdocs-app-service-sqldb-dotnetcore.
In Branch, select main.
In the top menu, select Save. App Service commits a workflow file into the chosen GitHub repository, in the **.github/workflows** directory.

**Step 4:** Back to the GitHub page of the forked sample, and open Visual Studio Code in the browser by pressing the **.** key.

**Step 5:** In Visual Studio Code in the browser:

Open DotNetCoreSqlDb/appsettings.json in the explorer.
Change the connection string name **MyDbConnection** to **AZURE_SQL_CONNECTIONSTRING**, which matches the connection string created in App Service earlier.

**Step 6:** Open **DotNetCoreSqlDb/Program.cs** in the explorer.
In the options.UseSqlServer method, and change the connection string name **MyDbConnection** to **AZURE_SQL_CONNECTIONSTRING**. This is where the connection string is used by the sample application.
Remove the **builder.Services.AddDistributedMemoryCache()**; method and replace it with the following code. It changes your code from using an in-memory cache to the Redis cache in Azure, and it does so by using **AZURE_REDIS_CONNECTIONSTRING** from earlier.

**Code:**
builder.Services.AddStackExchangeRedisCache(options =>
{
options.Configuration = builder.Configuration["AZURE_REDIS_CONNECTIONSTRING"];
options.InstanceName = "SampleInstance";
});

**Step 7:** Open **.github/workflows/main_msdocs-core-sql-XYZ** in the explorer. This file was created by the App Service create wizard.
Under the **dotnet publish** step, add a step to install the Entity Framework Core tool with the command **dotnet tool install -g dotnet-ef**.
Under the new step, add another step to generate a database migration bundle in the deployment package: **dotnet ef migrations bundle --runtime linux-x64 -p DotNetCoreSqlDb/DotNetCoreSqlDb.csproj -o ${{env.DOTNET_ROOT}}/myapp/migrate**. The migration bundle is a self-contained executable that you can run in the production environment without needing the .NET SDK. The App Service linux container only has the .NET runtime and not the .NET SDK.

**Step 8:** Select the **Source Control** extension.
In the textbox, type a commit message like Configure DB & Redis & add migration bundle.
Select **Commit and Push**.

**Step 9:** Back in the Deployment Center page in the Azure portal:
Select **Logs** from web app in Azure Portal. A new deployment run is already started from your committed changes.
In the log item for the deployment run, select the **Build/Deploy** Logs entry with the latest timestamp.

**Step 10:** You're taken to your GitHub repository and see that the GitHub action is running. The workflow file defines two separate stages, build and deploy. Wait for the GitHub run to show a status of Complete. It takes a few minutes.

# Generate database schema
With the SQL Database protected by the virtual network, the easiest way to run Run dotnet database migrations is in an SSH session with the App Service container.

**Step 1:** Back in the App Service page, in the left menu, select **SSH**.
**Step 2:** In the SSH terminal:

Run **cd /home/site/wwwroot**. Here are all your deployed files.
Run the migration bundle that's generated by the GitHub workflow with **./migrate**. If it succeeds, App Service is connecting successfully to the SQL Database. Only changes to files in /home can persist beyond app restarts. Changes outside of /home aren't persisted.

...................................................................................................................................................................................................................

# Browse to the app
**Step 1:** In the Application Gateway from Azure Portal:

From the left menu, select **Overview**.
Select the Public IP of app gateway. Browse from the browser with the Public IP address.

**Step 2:** Add a few tasks to the list. Congratulations, you're running a secure data-driven ASP.NET Core app in Azure App Service.
