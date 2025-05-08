#!/bin/bash

# Ask user for domain name and app name
read -p "Enter your domain name (e.g., myapp.com): " DOMAIN
read -p "Enter your app name: " APP_NAME

# Define SSL paths for Nginx
CRT_PATH="/etc/nginx/ssl/$APP_NAME.crt"
KEY_PATH="/etc/nginx/ssl/$APP_NAME.key"

# Install crtforge if not exists
if ! command -v crtforge &> /dev/null; then
    echo "Installing crtforge..."
    sudo curl -L -o /usr/bin/crtforge https://github.com/burakberkkeskin/crtForge/releases/latest/download/crtforge-$(uname -s)-$(uname -m)
    sudo chmod +x /usr/bin/crtforge
fi

# Generate SSL certificate using app name
echo "Generating SSL certificate for $APP_NAME..."
crtforge "$APP_NAME" "$DOMAIN"

# Ensure SSL folder exists in /etc/nginx/ssl (create if missing)
if [ ! -d "/etc/nginx/ssl" ]; then
    echo "Creating SSL folder: /etc/nginx/ssl"
    sudo mkdir -p "/etc/nginx/ssl"
fi

# Move the generated certificate and key to /etc/nginx/ssl
sudo mv "$HOME/.config/crtforge/default/$APP_NAME/$APP_NAME.crt" "$CRT_PATH"
sudo mv "$HOME/.config/crtforge/default/$APP_NAME/$APP_NAME.key" "$KEY_PATH"

# Update Nginx configuration to use the correct domain name and certificate paths
NGINX_CONFIG="./config/nginx.conf"
echo "Updating Nginx configuration..."
sed -i "s|server_name .*;|server_name $DOMAIN;|" "$NGINX_CONFIG"
sed -i "s|ssl_certificate .*;|ssl_certificate $CRT_PATH;|" "$NGINX_CONFIG"
sed -i "s|ssl_certificate_key .*;|ssl_certificate_key $KEY_PATH;|" "$NGINX_CONFIG"

# Start Docker Compose
echo "Starting Docker Compose..."
docker-compose up -d

echo "✅ Setup complete! Your application '$APP_NAME' is now running!"
