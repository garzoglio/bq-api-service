# BigQuery API Passthrough on Cloud Run

This repository contains a sample application and infrastructure automation to deploy a secure API passthrough service on Google Cloud Run. The service is configured to interact with the Google BigQuery API using a dedicated, least-privilege service account.

The project uses [`just`](https://github.com/casey/just) as a command runner to simplify setup, deployment, and local development.

## Features

*   **Automated Setup**: [WIP] A single command (`just setup`) provisions all necessary GCP resources (Service Account, Artifact Registry, IAM policies).
*   **One-Command Deployment**: Deploy the application directly from source to Cloud Run with `just deploy`.
*   **Secure by Default**: Follows the principle of least privilege by creating a dedicated service account for the Cloud Run service with only the necessary permissions (`roles/bigquery.user`).
*   **Configuration as Code**: All commands are defined in a `justfile`, making the process transparent and repeatable.
*   **Local Development**: Build and run the service locally using Docker for testing.

## Prerequisites

Before you begin, ensure you have the following tools installed:

1.  **Google Cloud SDK**
2.  **just**
3.  **Docker**

You will also need:
*   An active Google Cloud project with billing enabled.
*   The `cloud-build.googleapis.com` and `run.googleapis.com` APIs enabled in your project.

## Setup

1.  **Clone the Repository**
    ```sh
    git clone <your-repo-url>
    cd <your-repo-directory>
    ```

2.  **Configure Environment**

    The project uses a `.env` file for configuration. Copy the example file and update it with your specific values.

    ```sh
    cp .env.example .env
    ```

    Now, edit `.env` and set the following variables:

    ```dotenv
    # .env
    PROJECT_ID="your-gcp-project-id"
    REGION="your-gcp-region" # e.g., us-central1
    SERVICE_NAME="bq-api-passthrough"
    SERVICE_ACCOUNT_NAME="bq-api-passthrough-sa"
    ARTIFACT_REGISTRY_REPO="cloud-run-source-deploy"
    ```

3.  **Authenticate with Google Cloud**

    Log in with your user account and set up Application Default Credentials.
    ```sh
    gcloud auth login
    gcloud auth application-default login
    ```

4.  **Set Your Project**

    Configure the `gcloud` CLI to use your project.
    ```sh
    gcloud config set project your-gcp-project-id
    ```

## Usage

All commands are run using `just`.

### 1. One-Time Infrastructure Setup

This command provisions all the necessary GCP resources. You only need to run this once per project.
NOTE: THIS SCRIPT IS WORK IN PROGRESS AND MAY NOT FULLY SET UP THE ENVIRONMENT.

```sh
just setup
```

This will:
*   Create an IAM Service Account for the Cloud Run service.
*   Grant the `roles/bigquery.user` role to the service account.
*   Create an Artifact Registry repository for storing container images built from source.
*   Grant the Cloud Build service account permissions to impersonate the Cloud Run service account and write to the Artifact Registry.

### 2. Deploy to Cloud Run

This command builds your application from the current source code and deploys it as a public-facing Cloud Run service.

```sh
just deploy
```

### 3. Run Locally

To test the service on your local machine, you can build and run it in a Docker container.

```sh
just local-run
```

The service will be available at `http://localhost:8080`.

### 4. Test the Service

To test the service you can connect to it with the curl command. Use / modify the script at test_service.sh


```sh
chmod 755 test_service.sh
./test_service.sh
```

## Cleanup

To avoid incurring future costs, you can remove the GCP resources created by this project.

1.  **Delete the Cloud Run Service**
    ```sh
    gcloud run services delete {{SERVICE_NAME}} --project={{PROJECT_ID}} --region={{REGION}}
    ```

2.  **Delete the Artifact Registry Repository**
    ```sh
    gcloud artifacts repositories delete {{ARTIFACT_REGISTRY_REPO}} --project={{PROJECT_ID}} --location={{REGION}}
    ```

3.  **Delete the Service Account**
    ```sh
    gcloud iam service-accounts delete {{SERVICE_ACCOUNT_EMAIL}} --project={{PROJECT_ID}}
    ```

*Note: You may also want to remove the IAM policy bindings added during the `setup` step if you are not deleting the project.*