FROM debian:bullseye-20230320-slim

# Add image information
LABEL \
    category="pythonbash-exporter" \
    maintainers="Hetimop"


# Install required packages
RUN apt-get update && \
    apt-get install -y python3 python3-pip nano curl ldap-utils jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Python script into container
COPY entrypoint.py /usr/src/entrypoint.py

# Copy requirements.txt and install Python modules
RUN mkdir /app/scripts -p

# Set entrypoint to run Python script
ENTRYPOINT ["python3", "/usr/src/entrypoint.py"]