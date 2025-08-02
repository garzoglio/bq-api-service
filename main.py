import os
import logging
from flask import Flask, request, jsonify
from google.cloud import bigquery
from google.api_core import exceptions

# Configure logging. In Cloud Run, these logs are automatically sent to Cloud Logging.
logging.basicConfig(
    level=os.environ.get("LOGLEVEL", "INFO"),
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)

# For security and scalability, it's best to initialize clients outside of
# request-handling functions.
client = None
try:
    client = bigquery.Client()
    logging.info("BigQuery client initialized successfully.")
except Exception as e:
    # Handle exceptions for cases where the environment might not be configured,
    # e.g., missing credentials.
    logging.exception("Could not initialize BigQuery client.")

@app.route("/")
def index():
    """A simple health check endpoint to confirm the service is running."""
    logging.info("Health check endpoint was called.")
    return "OK", 200
@app.route("/query", methods=["POST"])
def handle_query():
    """
    Executes a BigQuery SQL query from a POST request.
    The request body must be a JSON object with a "query" key.
    e.g., {"query": "SELECT name FROM \`bigquery-public-data.usa_names.usa_1910_2013\` WHERE state = 'TX' LIMIT 10"}
    """
    if not client:
        logging.error("Query attempted, but BigQuery client is not available.")
        return jsonify({"error": "Server is not configured to connect to BigQuery."}), 500

    data = request.get_json()
    if not data or "query" not in data:
        logging.warning("Bad request: Missing 'query' key in JSON payload.")
        return jsonify({"error": "Request body must be JSON with a 'query' key"}), 400

    sql_query = data["query"]
    # Log the query, but truncate it to avoid excessively long log entries.
    logging.info(f"Executing query: {sql_query[:200]}...")

    try:
        query_job = client.query(sql_query)
        results = query_job.result()  # Waits for the job to complete.
        records = [dict(row) for row in results]
        logging.info(f"Query successful. Returning {len(records)} records.")
        return jsonify(records), 200
    except exceptions.GoogleAPICallError as e:
        logging.error(f"BigQuery API error for query '{sql_query[:200]}...': {e.message}")
        return jsonify({"error": f"BigQuery API error: {e.message}"}), 400
    except Exception as e:
        # Using logging.exception will automatically include the stack trace.
        logging.exception(f"An unexpected error occurred while executing query '{sql_query[:200]}...'.")
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500