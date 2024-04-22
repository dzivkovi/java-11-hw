#!/bin/bash

# Define the path to your sonar-project.properties file
properties_file="sonar-project.properties"

# Initialize the properties variable.
mvn_properties=""

# Read each line in the sonar-project.properties file
while IFS= read -r line
do
  # Check if the line is a comment
  if [[ "$line" =~ ^\#.* ]] || [[ -z "$line" ]]; then
    continue
  fi

  # Remove spaces around the equals sign if present
  line=$(echo $line | tr -d ' ')

  # Convert it into a Maven -D property
  mvn_properties+=" -D$line"
done < "$properties_file"

# Now run Maven verify with these properties
echo "Running Maven verify with SonarQube analysis..."
mvn verify sonar:sonar $mvn_properties
