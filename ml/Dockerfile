# Use a public Python base image
FROM python:3.10-slim

# Install system dependencies if needed (none are strictly needed here)
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY train.py .
COPY data/ data/


CMD ["python", "train.py"]