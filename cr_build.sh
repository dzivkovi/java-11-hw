#!/bin/bash
# cr_build.sh script builds an application for deployments in GCP Cloud Run.
# It uses Cloud Native Buildpacks to transform your source code into container images
# that can run on any cloud. Benefits of this approach include:
#  1. Buildpacks automatically detect the language the application is written in,
#  2. Removing the burden of writing Dockerfiles,
#  3. Tight integration into the GCP tooling,
#  4. Reusing values from a Jenkins manifest.yml file.
#
#  For more information:
#  - Cloud Native Buildpacks: https://buildpacks.io/
#  - Google Cloud Build: https://cloud.google.com/docs/buildpacks/build-application
# 
# This script is intended to be run in a CI/CD pipeline, but
# developers can run it locally to create "demo" deployments.

# Target deployment environment
# Select the correct .env file based on deployment target (add more as needed)
if [[ "$DEPLOYMENT_TARGET" == "demo" ]]; then
  ENV_FILE=".env.dev"
elif [[ "$DEPLOYMENT_TARGET" == "dev" ]]; then
  ENV_FILE=".env.dev"
elif [[ "$DEPLOYMENT_TARGET" == "uat" ]]; then
  ENV_FILE=".env.uat"
elif [[ "$DEPLOYMENT_TARGET" == "stg" ]]; then
  ENV_FILE=".env.stg"
elif [[ "$DEPLOYMENT_TARGET" == "prod" ]]; then
  ENV_FILE=".env.prod"
else
  echo "Error: DEPLOYMENT_TARGET environment variable not set or invalid. Use one of: demo, dev, uat, stg, prod"
  exit 1
fi
echo "Target environment: $DEPLOYMENT_TARGET"

# Function to check required variables are set
check_required_vars() {
    local required_vars=("$@")  # Accepts an array of required variable names as arguments

    for var_name in "${required_vars[@]}"; do
        if [[ -z "${!var_name}" ]]; then  # Indirect expansion to check if the variable is empty
            echo "Error: Variable $var_name is missing. Please ensure it's defined." >&2
            exit 1
        else
            echo "Variable: $var_name=${!var_name}"
        fi
    done
}

# Extract Values from manifest.yaml
echo "Parsing manifest.yml file..."

# Function to read a value from the manifest.yaml file
# using https://github.com/mikefarah/yq to parse YAML 
get_manifest_value() {
  yq eval ".$1" manifest.yml
}

TEAM=$(get_manifest_value team)
APPLICATION_NAME=$(get_manifest_value application.name)

APPLICATION_RUNTIME_VERSION=$(get_manifest_value application.runtime_version)
# TODO: Use for container build process:
# $ gcloud builds submit --pack image=${IMAGE_URI},env="GOOGLE_RUNTIME_VERSION=$APPLICATION_RUNTIME_VERSION" --project=$PROJECT_ID

# Required Variables (add any others you need)
required_vars=(TEAM APPLICATION_NAME APPLICATION_RUNTIME_VERSION)

check_required_vars "${required_vars[@]}"

echo "Finding GCP Project ID and Region..."

# Assuming all deployments are in the same region
REGION=$(gcloud config get-value compute/region)

if [[ "$DEPLOYMENT_TARGET" == "demo" ]]; then
  PROJECT_ID=$(gcloud config get-value project)
else
  PROJECT_ID=$(./manifest_parser.sh $DEPLOYMENT_TARGET)
fi

# If we reach here, all required variables have values
echo "All required variables are present."

# NOTE: Using TEAM name for organizing container artifacts 
IMAGE_URI="gcr.io/${PROJECT_ID}/${TEAM}/${APPLICATION_NAME}"

# Build the gcloud run deploy command 
build_cmd="gcloud builds submit --project=$PROJECT_ID \
     --pack image=${IMAGE_URI},env=\"GOOGLE_RUNTIME_VERSION=$APPLICATION_RUNTIME_VERSION\""

echo "Build application \(remotely\) with buildpacks..."
echo "$build_cmd"
eval $build_cmd
