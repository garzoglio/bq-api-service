# Load environment variables from a .env file.
set dotenv-load
# Use bash, and exit if any command fails, a variable is unset, or a command in a pipeline fails.

# --- Configuration ---
# Load required variables from the environment (provided by the .env file).
# This makes dependencies explicit and provides clearer error messages if a variable is missing.
PROJECT_ID             := env("PROJECT_ID")
REGION                 := env("REGION")
SERVICE_NAME           := env("SERVICE_NAME")
SERVICE_ACCOUNT_NAME   := env("SERVICE_ACCOUNT_NAME")
ARTIFACT_REGISTRY_REPO := env("ARTIFACT_REGISTRY_REPO")
SERVICE_ACCOUNT_EMAIL  := SERVICE_ACCOUNT_NAME + "@" + PROJECT_ID + ".iam.gserviceaccount.com"

# Default recipe to run when you just type `just`
default: deploy

# --- One-Time Setup ---

# Run this once to provision and configure all necessary GCP resources.
setup:
    echo "==> Running one-time setup for project {{PROJECT_ID}}..."
    PROJECT_NUMBER=$$(gcloud projects describe "{{PROJECT_ID}}" --format='value(projectNumber)')
    CLOUDBUILD_SA="$${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

    echo "==> 1. Setting up service account '{{SERVICE_ACCOUNT_NAME}}' for the Cloud Run service..."
    (gcloud iam service-accounts create "{{SERVICE_ACCOUNT_NAME}}" --display-name="BigQuery API Service Account" --project="{{PROJECT_ID}}" || echo "--> Service account may already exist.")

    echo -e "\n==> 2. Granting BigQuery User role to the service account..."
    gcloud projects add-iam-policy-binding "{{PROJECT_ID}}" --member="serviceAccount:{{SERVICE_ACCOUNT_EMAIL}}" --role="roles/bigquery.user"

    echo -e "\n==> 3. Allowing Cloud Build ($$CLOUDBUILD_SA) to impersonate the service account for deployment..."
    gcloud iam service-accounts add-iam-policy-binding "{{SERVICE_ACCOUNT_EMAIL}}" --member="serviceAccount:$$CLOUDBUILD_SA" --role="roles/iam.serviceAccountUser"

    echo -e "\n==> 4. Creating Artifact Registry repo '{{ARTIFACT_REGISTRY_REPO}}' and granting permissions..."
    (gcloud artifacts repositories create "{{ARTIFACT_REGISTRY_REPO}}" --project="{{PROJECT_ID}}" --repository-format=docker --location="{{REGION}}" --description="Repository for Cloud Run source deployments" || echo "--> Repository may already exist.")
    echo "   --> Granting Artifact Registry Writer to Cloud Build SA"
    (gcloud artifacts repositories add-iam-policy-binding "{{ARTIFACT_REGISTRY_REPO}}" --project="{{PROJECT_ID}}" --location="{{REGION}}" --member="serviceAccount:$$CLOUDBUILD_SA" --role="roles/artifactregistry.writer" --condition=None > /dev/null || echo "--> Permissions may already be set.")

    echo -e "\n==> 5. Ensuring Cloud Build has necessary permissions (usually enabled by default)..."
    gcloud projects add-iam-policy-binding "{{PROJECT_ID}}" --member="serviceAccount:$$CLOUDBUILD_SA" --role="roles/storage.objectViewer" --condition=None > /dev/null
    gcloud projects add-iam-policy-binding "{{PROJECT_ID}}" --member="serviceAccount:$$CLOUDBUILD_SA" --role="roles/logging.logWriter" --condition=None > /dev/null

    echo -e "\n✅ Setup complete."

# --- Deployment ---

# Build and deploy the application to Cloud Run using source
deploy:
    echo "==> Deploying service {{SERVICE_NAME}} to project {{PROJECT_ID}} in region {{REGION}} ..."
    gcloud run deploy {{SERVICE_NAME}} \
        --source=. \
        --project={{PROJECT_ID}} \
        --region={{REGION}} \
        --allow-unauthenticated \
        --service-account={{SERVICE_ACCOUNT_EMAIL}} \
        --labels=app=bq-api-passthrough

# --- Local Development ---

# Run the container locally for testing
local-run:
    echo "==> Running container locally on port 8080..."
    docker build -t {{SERVICE_NAME}} .
    docker run --rm -p 8080:8080 \
      -e GOOGLE_CLOUD_PROJECT={{PROJECT_ID}} \
      --name bq-api {{SERVICE_NAME}}