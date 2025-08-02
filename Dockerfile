# Use an official lightweight Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables for Python and the application
ENV PYTHONUNBUFFERED True
ENV APP_HOME /app
WORKDIR $APP_HOME

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy local code to the container image
COPY main.py .

# Run the web service on container startup using Gunicorn
# Cloud Run automatically sets the PORT environment variable
CMD exec gunicorn --bind :${PORT:-8080} --workers 1 --threads 8 --timeout 0 main:app