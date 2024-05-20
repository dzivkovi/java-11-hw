# SonarQube Analysis Setup for Java Projects

This README details the steps to set up SonarQube analysis for your Java project using SonarCloud from Google Cloud Build CI/CD pipelines.

## Prerequisites

- Java JDK 11 or later must be installed.
- Maven must be installed for building the project.
- Access to SonarCloud with a registered account.

## Configuration

1. **SonarCloud Project Setup**:
   - Create a project on [SonarCloud.io](https://sonarcloud.io) to obtain your unique project key and organization ID.
   - Navigate to your project's configuration page, typically under `https://sonarcloud.io/project/configuration?id=your_project_key`

2. **Local Environment Setup**:
   - Ensure Java and Maven are correctly installed and configured on your system.
   - Set up the `SONAR_TOKEN` environment variable with your SonarCloud token. In Windows:

     ```bash
     set SONAR_TOKEN=your_sonarqube_token
     ```

        or in Unix-based systems:

        ```bash
        export SONAR_TOKEN=your_sonarqube_token
        ```

   - Modify the path environment variable to include the location of your SonarScanner's `bin` directory if you are using SonarScanner.

## SonarQube Validation

### Direct Sonar-Scanner Method (Windows)

For direct analysis using SonarScanner, configure the scanner and execute the following in your project's root directory:

```bash
sonar-scanner -Dproject.settings=sonar-project.properties
```

### Using Maven

To run the analysis through Maven, use the following command:

```bash
mvn verify sonar:sonar -Dsonar.projectKey=your_sonarqube_project_key -Dsonar.organization=your_sonarqube_project -Dsonar.host.url='https://sonarcloud.io'
```

or

```bash
 mvn verify sonar:sonar -Dsonar.projectKey=$SONAR_PROJECTKEY -Dsonar.host.url=$SONAR_HOST -Dsonar.login=$SONAR_LOGIN
```

If you want Maven to use the same `sonar-project.properties` configuration file, you can use this custom script instead of having to map the properties manually to command line arguments:

```bash
sh ./run_sonar_analysis.sh
```

## Google Cloud Build CI/CD Integration

To integrate SonarQube analysis into Google Cloud Build, use the following command:

```bash
gcloud builds submit --config cloudbuild-sonar.yaml --substitutions=_SONAR_TOKEN="$SONAR_TOKEN"
```

## Final Notes

- Always ensure your `SONAR_TOKEN` is kept secure and not hardcoded in your configuration files.
- Regularly execute your SonarQube scanner to keep up with new features and security patches.
- In production, use Google Cloud's Secret Manager to store/access sensitive information like the SonarQube token.

### Community-contributed builders

You may run into the [community-contributed images for Google Cloud Build repo](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/sonarqube). Do not use them as they are not maintained and may not work as expected. Instead, running the official [Maven Cloud Builder](https://cloud.google.com/build/docs/cloud-builders) is much simpler and reliable for SonarQube analysis.
