# Getting started with Google Cloud Build

Replace my username (dzivkovi), GitHub repo and Git project specific info by yours.

## Create initial source-code project

### Authenticate with GitHub

```sh
gh auth login

# or alternatively use the environment GITHUB_TOKEN

export GITHUB_TOKEN='ghp_xxx'
```

### Configure Git

```sh
git config --global user.email "your_email@example.com"
git config --global user.name "Your Name"
```

### Obtain the source code

#### Create it

```sh
gcloud storage cp -r gs://pls-resource-bucket/tldr-everything .
cd tldr-everything
```

#### Clone it

```sh
git clone https://github.com/larkintuckerllc/hello-nodejs-typescript.git

cd hello-nodejs-typescript
rm -rf .git
```

### Initialize local Git repo

```sh
git init
git checkout -b main
git add .
git commit -m "Initial commit"
```

### Create new private repository on GitHub

```sh
gh repo create hello-nodejs-typescript --private
```

### Push the new branch upstream ('-u') to the Remote Repository

```sh
git remote add origin https://github.com/dzivkovi/hello-nodejs-typescript.git
git branch -M main
git push -u origin main
```

## Define your Git Workflow

### Switch to the main branch, to ensure we're starting from the right place

```sh
git checkout main
```

### Create the Development branch for development work and push it to GitHub

```sh
git checkout -b dev
git push -u origin dev
```

~~### Create the branch for User Acceptance Testing and push it to GitHub~~

~~```sh~~
~~git checkout -b uat~~
~~git push -u origin uat~~
~~```~~

~~### Create the branch for the Staging environment and push it to GitHub~~

~~```sh~~
~~git checkout -b stg~~
~~git push -u origin stg~~
~~```~~

## Development Work

~~### Get the latest code from 'dev' branch~~

~~```sh~~
~~git checkout dev~~
~~git pull  # Ensure you have the latest changes~~
~~```~~

### Create a new branch for your feature

```sh
git checkout -b feature/my-new-feature
```

#### Note

This command is correct for creating a new feature branch from the current branch, which will be `dev` if the previous steps were followed correctly. However, if there is any concern about the user possibly not being on dev (due to manual errors or interruptions), explicitly specifying the parent branch can avoid such issues:

```sh
git checkout -b feature/my-new-feature dev
```

### Make sure you have the latest code from the 'dev' branch

Rebase option ensures you changes (if any) are kept on top:

```sh
git pull origin dev --rebase
```

### Do your work

### Committing changes in feature branch

Add your changes and commit them:

```sh
git add .
git commit -m "Add my new feature"
```

Push your feature branch to the remote repository:

```sh
git push -u origin feature/my-new-feature  # The '-u' flag sets the upstream branch
```

### Creating a Pull Request

Create a pull request from your feature branch to `dev` using the GitHub CLI or GUI:

```sh
gh pr create --base dev --head feature/my-new-feature --title "My New Feature" --body "Description of my new feature"
```

#### Review and Merge Pull Requests

After your pull request is reviewed and approved, merge it through the GitHub website. Choose the appropriate merge strategy (Merge commit, Squash and merge, Rebase and merge).

### Post-Merge Cleanup

After the pull request is merged:

1. **Update Your Local 'dev' Branch**:
   Switch to the `dev` branch and pull the latest changes.

    ```sh
    git checkout dev
    git pull
    ```

2. **Delete the Local and Remote Feature Branches**:
   Clean up your branches after the merge.

    ```sh
    # Delete the local branch
    git branch -d feature/my-new-feature

    # Delete the remote branch
    git push origin --delete feature/my-new-feature
    ```

Deleting the feature branch locally and remotely after the merge helps keep the repository clean and manageable. Ensure that the pull request is fully merged before attempting to delete the branches to avoid losing work.

### Continue Development Work

Ready to start on the next feature:

```sh
git checkout dev
git pull  # Ensure you have the latest changes
# Optionally start a new feature branch
git checkout -b feature/my-next-feature
```

## Build/Deploy Process

### Prepare the GCP environment

One-off acrivites, that might have already been performed by your GCP or Project admins:

```sh
# Enabled GCP Services
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com \
    run.googleapis.com eventarc.googleapis.com \
    logging.googleapis.com

# Create the repository for docker images 
export REPOSITORY=r2d2
gcloud artifacts repositories create ${REPOSITORY} --repository-format=Docker --location ${REGION}
```

### Set up the environment

```sh
# Set the project ID and region
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"

export REGION=$(gcloud config get-value compute/region)
if [ "$REGION" = "(unset)" ] || [ -z "$REGION" ]; then
  export REGION="us-central1"
  gcloud config set compute/region $REGION
fi
echo "Region set to: $REGION"

# See artifact registry repository content
export REPOSITORY=r2d2
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY --include-tags
```

### Use Cloud Build Service account (SA)

See the "Using minimal IAM permissions" section in the [Deploying to Cloud Run using Cloud Build](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run#continuous-iam) page.

#### Default SA

```sh
SERVICE_ACCOUNT=cloudbuild

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${PROJECT_NUMBER}@${SERVICE_ACCOUNT}.gserviceaccount.com --role=roles/artifactregistry.writer
```

#### Ceate a new SA

If you don't have permission to update Cloud Build Service Account, create a new one:

```sh
SERVICE_ACCOUNT=my-cloudbuild-sa

gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
--description="Temporary Service Account" \
--display-name="${SERVICE_ACCOUNT}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/iam.serviceAccountUser" \
--role="roles/cloudasset.owner" \
--role="roles/storage.admin" \
--role="roles/logging.logWriter" \
--role="roles/artifactregistry.admin" \
--role="roles/compute.admin"
```

## Enabling Branch Deployments

### Setup Branch Trigger

In this section, you enable developers with a unique URL for development branches in Git. Each branch is represented by a URL identified by the branch name. Commits to the branch trigger a deployment, and the updates are accessible at that same URL.  

- Set up the trigger:

```sh
gcloud builds triggers create github \
--name=branchtrigger \
--repository=$REPO_NAME \
--branch-pattern='[^(?!.*main)].*' \
--build-config=cloudbuild-branch.yaml \
--region=$REGION
```

- Review the trigger

by going to the [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers) in the Cloud Console:

## Learn more

- [Cloud Native Automation with Google Cloud Build](https://www.packtpub.com/product/cloud-native-automation-with-google-cloud-build/9781801816700)
- [Code examples used in the official Cloud Build documentation](https://github.com/GoogleCloudPlatform/cloud-build-samples)
