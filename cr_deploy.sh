#!/bin/bash
# cr_deploy.sh script deploys an application to GCP Cloud Run.
# It leverages values from a Jenkins manifest.yml file to configure the deployment.
# It's intended to be run in a CI/CD pipeline, but can be run locally for "demo"s.

# Default Cloud Run settings
CPU="1"           # A higher CPU allocation relates to shorter cold starts
CONCURRENCY="80"
TIMEOUT="300"
AUTHENTICATION=   # Do not allow unauthenticated requests by default.
# Pass the authentication token in the header, instead:
# curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" https://your-service-url

# Target deployment environment
# Select the correct .env file based on deployment target (add more as needed)
if [[ "$DEPLOYMENT_TARGET" == "demo" ]]; then
  ENV_FILE=".env.dev"
  # Avoid GCP charges when 'demo' environment is not in use
  DEPLOYMENT_MININSTANCE=0
  AUTHENTICATION="--allow-unauthenticated"
elif [[ "$DEPLOYMENT_TARGET" == "dev" ]]; then
  ENV_FILE=".env.dev"
elif [[ "$DEPLOYMENT_TARGET" == "uat" ]]; then
  ENV_FILE=".env.uat"
elif [[ "$DEPLOYMENT_TARGET" == "stg" ]]; then
  ENV_FILE=".env.stg"
elif [[ "$DEPLOYMENT_TARGET" == "prod" ]]; then
  ENV_FILE=".env.prod"
else
  echo "Error: DEPLOYMENT_TARGET environment variable not set or invalid. Use one of: demo, dev, uat, stg, prod" >&2
  exit 1
fi
echo "Deployment target: $DEPLOYMENT_TARGET"

# Function to check required variables are set
check_required_vars() {
    local required_vars=("$@")  # Accepts an array of required variable names as arguments

    for var_name in "${required_vars[@]}"; do
        if [[ -z "${!var_name}" || "${!var_name}" == "null" ]]; then  # Check if variable is empty or null
            echo "Warning: Variable $var_name is missing or null. Skipping." >&2
            # Note: Changed from 'exit 1' to simply emit a warning to allow deployment to proceed without this variable
        else
            echo "Variable: $var_name=${!var_name}"
        fi
    done
}

# Extract Values from manifest.yml
echo "Parsing manifest.yml file..."

# Assuming yq is installed and configured correctly
TEAM=$(yq e '.team' manifest.yml)
APPLICATION_NAME=$(yq e '.application.name' manifest.yml)
DEPLOYMENT_MEMORY=$(yq e '.deployment.memory // "null"' manifest.yml) # Provide default value if null
DEPLOYMENT_MININSTANCE=$(yq e '.deployment.minInstance // "null"' manifest.yml) # Default to 0 if not specified
DEPLOYMENT_MAXINSTANCE=$(yq e '.deployment.maxInstance // "null"' manifest.yml) # Keep as null if not specified

APPLICATION_RUNTIME_VERSION=$(yq e '.application.runtime_version' manifest.yml)

# Assuming the REGION is set from gcloud config and PROJECT_ID is determined based on DEPLOYMENT_TARGET
# Assuming all deployments are in the same region
REGION=$(gcloud config get-value compute/region)

if [[ "$DEPLOYMENT_TARGET" == "demo" ]]; then
  PROJECT_ID=$(gcloud config get-value project)
else
  PROJECT_ID=$(./manifest_parser.sh $DEPLOYMENT_TARGET)
fi

# Check if required variables are set
required_vars=(TEAM APPLICATION_NAME DEPLOYMENT_MEMORY APPLICATION_RUNTIME_VERSION PROJECT_ID REGION)
check_required_vars "${required_vars[@]}"

# Echo out for debugging purposes
echo "Project ID: $PROJECT_ID, Region: $REGION"

# Initializing deploy command with mandatory flags
deploy_cmd="gcloud run deploy $APPLICATION_NAME $AUTHENTICATION \
    --platform managed \
    --project $PROJECT_ID \
    --region $REGION \
    --image gcr.io/$PROJECT_ID/$APPLICATION_NAME"

# Add optional flags only if variables are set and non-null
[[ -n "$CPU" && "$CPU" != "null" ]] && deploy_cmd+=" --cpu $CPU"
[[ -n "$CONCURRENCY" && "$CONCURRENCY" != "null" ]] && deploy_cmd+=" --concurrency $CONCURRENCY"
[[ -n "$TIMEOUT" && "$TIMEOUT" != "null" ]] && deploy_cmd+=" --timeout $TIMEOUT"
[[ -n "$DEPLOYMENT_MEMORY" && "$DEPLOYMENT_MEMORY" != "null" ]] && deploy_cmd+=" --memory $DEPLOYMENT_MEMORY"
[[ -n "$DEPLOYMENT_MININSTANCE" && "$DEPLOYMENT_MININSTANCE" != "null" ]] && deploy_cmd+=" --min-instances $DEPLOYMENT_MININSTANCE"
[[ -n "$DEPLOYMENT_MAXINSTANCE" && "$DEPLOYMENT_MAXINSTANCE" != "null" ]] && deploy_cmd+=" --max-instances $DEPLOYMENT_MAXINSTANCE"

# Execute deployment command
echo "Executing deployment command:"
echo $deploy_cmd
eval $deploy_cmd
