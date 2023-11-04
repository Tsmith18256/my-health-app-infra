#!/bin/bash

# Update the package repository and upgrade installed packages
sudo apt-get update

# Decode the Base64 authfile and store the result in a variable
decoded_string=$(echo "${auth_file}" | base64 --decode)

# Write auth details to file
echo $decoded_string | tee /tmp/authfile.json

# Set the project ID
PROJECT_ID="my-health-app-402819"


# Authenticate gcloud using the service account key file
gcloud auth activate-service-account ${service_account_name} --key-file="/tmp/authfile.json" --project="$PROJECT_ID"

# Fetch the secret payload using gcloud
SSH_KEY=$(gcloud secrets versions access latest --secret="admin-ssh-key-public" --project="$PROJECT_ID")
ADMIN_USER=$(gcloud secrets versions access latest --secret="admin-user-name" --project="$PROJECT_ID")
ADMIN_PASSWORD=$(gcloud secrets versions access latest --secret="admin-user-password" --project="$PROJECT_ID")

if id "$ADMIN_USER" &>/dev/null; then
    echo "User '$ADMIN_USER' exists."
else
    # Create a non-root user and add it to the sudo group
    sudo /sbin/useradd -m -s /bin/bash $ADMIN_USER
    sudo /sbin/usermod -aG sudo $ADMIN_USER
    # TODO: refactor to pull from google secrets
    echo "$ADMIN_USER:$ADMIN_PASSWORD" | sudo /sbin/chpasswd
fi

# Publish SSH key
if [ -d "/home/$ADMIN_USER/.ssh" ]; then
    # do nothing
    :
else
    mkdir /home/$ADMIN_USER/.ssh
    # TODO: refactor to pull from google secrets
    echo $SSH_KEY >> /home/$ADMIN_USER/.ssh/authorized_keys 
fi

# Clean up authfile
rm -f /tmp/authfile.json

# Optional: Install additional packages or perform other custom configurations
# sudo apt-get install -y <package-name>
