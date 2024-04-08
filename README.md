# Getting started with Google Cloud Build

Replace my username (dzivkovi), GitHub repo and Git project specific info by yours.

## Create initial source-code project

### Authenticate with GitHub

```bash
gh auth login

# or alternatively use the environment GITHUB_TOKEN

export GITHUB_TOKEN='ghp_xxx'
```

### Configure Git

```bash
git config --global user.email "your_email@example.com"
git config --global user.name "Your Name"
```

### Obtain the source code

#### Create it

```bash
gcloud storage cp -r gs://pls-resource-bucket/tldr-everything .
cd tldr-everything
```

#### Clone it

```bash
git clone https://c_dzivkovic@bitbucket.org/cogeco-it/hello-nodejs-typescript.git

cd hello-nodejs-typescript
rm -rf .git
```

### Initialize local Git repo

```bash
git init
git checkout -b main
git add .
git commit -m "Initial Cloud Build scripts"
```

### Create new private repository on GitHub

```bash
gh repo create hello-nodejs-typescript --private
```

### Push the new branch upstream ('-u') to the Remote Repository

```bash
git remote add origin https://github.com/dzivkovi/hello-nodejs-typescript.git
git branch -M main
git push -u origin main
```

## Define your Git Workflow

### Switch to the main branch, to ensure we're starting from the right place

```bash
git checkout main
```

### Create the Development branch for development work and push it to GitHub

```bash
git checkout -b dev
git push -u origin dev
```

### Create the branch for User Acceptance Testing and push it to GitHub

```bash
git checkout -b uat
git push -u origin uat
```

### Create the branch for the Staging environment and push it to GitHub

```bash
git checkout -b stg
git push -u origin stg
```

### Switch back to 'dev' to start development work

```bash
git checkout dev
```

### Committing Changes in Feature Branch

```bash
git checkout -b feature/my-new-feature
```

#### Add your changes to the staging area

```bash
git add .
git commit -m "Add my new feature"
git push origin feature/my-new-feature
```

### Creating a Pull Request from Feature Branch to `dev` using GUI or

```bash
gh pr create --base dev --head feature/my-new-feature --title "My New Feature" --body "Description of my new feature"
```

### Merging Pull Requests can be done via via Command Line

#### Ensure local repo is up to date with the latest changes from the remote

```bash
git pull origin dev
```

#### Switch to the base branch of the pull request

```bash
git checkout dev
```

#### Merge the head branch into the base branch

```bash
git merge feature/my-new-feature
```

#### Push the changes

```bash
git push -u origin dev
```

### Post Dev-merge cleanup

#### Deleting the local feature branch after merge

```bash
git branch -d feature/my-new-feature
```

#### Delete it remotely as well, so that Cloud Build trigger can clean up demo environment

```bash
git push origin --delete feature/my-new-feature
```

### Continue Development work

```bash
git checkout dev
```

## Prepare the GCP environment

One-off acrivites, that might have already been performed by you GCP or Project admins:

```bash
gcloud services enable cloudbuild.googleapis.com eventarc.googleapis.com run.googleapis.com logging.googleapis.com

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"

export REGION=$(gcloud config get-value compute/region || echo "us-central1")

gcloud config set compute/region $REGION
```

### Use Cloud Build Service account (SA)

Default coud build SA

```bash
SERVICE_ACCOUNT=cloudbuild

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member=serviceAccount:${PROJECT_NUMBER}@${SERVICE_ACCOUNT}.gserviceaccount.com --role=roles/artifactregistry.writer
```

#### Or create new SA

```bash
SERVICE_ACCOUNT=packt-cloudbuild-chp4-sa

gcloud iam service-accounts create ${SERVICE_ACCOUNT} \
--description="Temporary SA for chp 4 exercises" \
--display-name="${SERVICE_ACCOUNT}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/iam.serviceAccountUser" \
--role="roles/cloudasset.owner" \
--role="roles/storage.admin" \
--role="roles/logging.logWriter" \
--role="roles/artifactregistry.admin" \
--role="roles/compute.admin
```

### Artifact Registry

```bash
DOCKER_REPO=my-docker-repo

gcloud artifacts repositories create ${DOCKER_REPO} \
--repository-format=Docker \
--location ${REGION}
```
