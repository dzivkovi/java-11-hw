#!/bin/bash

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 DEPLOYMENT_TARGET" >&2
    exit 1
fi

# The first argument is the deployment target
DEPLOYMENT_TARGET="$1"

find_project_id_for_target() {
    local deployment_target="$1"
    local project_ids=$(yq e '.deployment.project.id | keys' manifest.yml | sed 's/^- //')

    # Convert string of project IDs into an array
    IFS=$'\n' read -r -d '' -a project_ids_array <<< "$project_ids"

    # Iterate over project IDs
    for project_id in "${project_ids_array[@]}"; do
        
        # Extract environments for the current project ID
        local environments=$(yq e ".deployment.project.id.${project_id}[]" manifest.yml | sed 's/^- //')
        
        # Convert string of environments into an array
        IFS=$'\n' read -r -d '' -a environments_array <<< "$environments"
        
        # Check if deployment_target is in environments
        for environment in "${environments_array[@]}"; do
            if [[ "$environment" == "$deployment_target" ]]; then
                echo "$project_id"
                return
            fi
        done
    done

    # If we get here, no project ID matched the deployment target
    echo "No project ID found for target '$DEPLOYMENT_TARGET'." >&2
    exit 1
}

# Direct function output to the variable
project=$(find_project_id_for_target "$DEPLOYMENT_TARGET")

# Check if function found a project ID or terminated with an error
if [ $? -eq 0 ]; then
    echo $project
else
    exit 1
fi
