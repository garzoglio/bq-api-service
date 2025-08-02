# Set the variables for your service
. .env

# 1. Get the URL of your deployed Cloud Run service
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format='value(status.url)')

# 2. Call the endpoint with an auth token and verbose output
echo "--> Testing endpoint: ${SERVICE_URL}/query"
curl --fail -v -X POST "${SERVICE_URL}/query" \
  -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"SELECT preferred_name FROM \`test-project-26133-466015.EA_Assistant_Data.EA_info\`\"}"
  # -d "{\"query\": \"SELECT name FROM \`bigquery-public-data.usa_names.usa_1910_2013\` WHERE state = 'TX' LIMIT 10\"}"
