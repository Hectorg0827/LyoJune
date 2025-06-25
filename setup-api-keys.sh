#!/bin/bash

# LyoApp API Key Setup Script
# This script helps set up secure API keys for production deployment

set -e

echo "🚀 LyoApp API Key Setup"
echo "======================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found. Please run this script from the project root directory.${NC}"
    exit 1
fi

echo -e "${BLUE}Setting up API keys for LyoApp...${NC}"

# Function to update or add environment variable
update_env_var() {
    local key=$1
    local value=$2
    local env_file=".env"
    
    if grep -q "^${key}=" "$env_file"; then
        # Update existing variable
        sed -i.bak "s/^${key}=.*/${key}=${value}/" "$env_file"
    else
        # Add new variable
        echo "${key}=${value}" >> "$env_file"
    fi
}

# Function to prompt for API key
prompt_for_key() {
    local service=$1
    local key_name=$2
    local description=$3
    local optional=${4:-false}
    
    echo ""
    echo -e "${YELLOW}Setting up ${service}${NC}"
    echo "Description: $description"
    
    if [ "$optional" = true ]; then
        echo -e "${BLUE}(Optional - press Enter to skip)${NC}"
    fi
    
    read -p "Enter your ${service} API key: " api_key
    
    if [ -n "$api_key" ]; then
        update_env_var "$key_name" "$api_key"
        echo -e "${GREEN}✓ ${service} API key set${NC}"
    elif [ "$optional" = false ]; then
        echo -e "${RED}Error: ${service} API key is required${NC}"
        exit 1
    else
        echo -e "${YELLOW}⚠ ${service} API key skipped${NC}"
    fi
}

echo ""
echo "This script will help you configure the following API keys:"
echo "1. Backend API Key (Required)"
echo "2. Gemma AI API Key (Required for AI features)"
echo "3. OpenAI API Key (Optional)"
echo "4. Claude API Key (Optional)"
echo "5. Analytics API Key (Optional)"
echo "6. Firebase/FCM Keys (Optional)"
echo ""

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Backend Configuration
echo ""
echo -e "${BLUE}Backend Configuration${NC}"
read -p "Enter your backend base URL [https://api.lyo.app/v1]: " backend_url
backend_url=${backend_url:-"https://api.lyo.app/v1"}
update_env_var "BACKEND_BASE_URL" "$backend_url"

read -p "Enter your backend WebSocket URL [wss://api.lyo.app/v1/ws]: " ws_url
ws_url=${ws_url:-"wss://api.lyo.app/v1/ws"}
update_env_var "BACKEND_WS_URL" "$ws_url"

# API Keys
prompt_for_key "Backend API" "API_KEY" "Main API key for backend authentication" false
prompt_for_key "Gemma AI" "GEMMA_API_KEY" "Google Gemma AI service for Study Buddy features" false
prompt_for_key "OpenAI" "OPENAI_API_KEY" "OpenAI GPT for additional AI features" true
prompt_for_key "Claude" "CLAUDE_API_KEY" "Anthropic Claude for AI conversations" true

# Analytics
echo ""
echo -e "${YELLOW}Analytics Configuration (Optional)${NC}"
read -p "Enter your Analytics API key (optional): " analytics_key
if [ -n "$analytics_key" ]; then
    update_env_var "ANALYTICS_API_KEY" "$analytics_key"
    echo -e "${GREEN}✓ Analytics API key set${NC}"
fi

read -p "Enter your Mixpanel token (optional): " mixpanel_token
if [ -n "$mixpanel_token" ]; then
    update_env_var "MIXPANEL_TOKEN" "$mixpanel_token"
    echo -e "${GREEN}✓ Mixpanel token set${NC}"
fi

# Push Notifications
echo ""
echo -e "${YELLOW}Push Notifications Configuration (Optional)${NC}"
read -p "Enter your FCM Server Key (optional): " fcm_key
if [ -n "$fcm_key" ]; then
    update_env_var "FCM_SERVER_KEY" "$fcm_key"
    echo -e "${GREEN}✓ FCM Server Key set${NC}"
fi

read -p "Enter your APNS Key ID (optional): " apns_key_id
if [ -n "$apns_key_id" ]; then
    update_env_var "APNS_KEY_ID" "$apns_key_id"
    echo -e "${GREEN}✓ APNS Key ID set${NC}"
fi

read -p "Enter your APNS Team ID (optional): " apns_team_id
if [ -n "$apns_team_id" ]; then
    update_env_var "APNS_TEAM_ID" "$apns_team_id"
    echo -e "${GREEN}✓ APNS Team ID set${NC}"
fi

# Third Party Services
echo ""
echo -e "${YELLOW}Third Party Services (Optional)${NC}"
read -p "Enter your Stripe Publishable Key (optional): " stripe_key
if [ -n "$stripe_key" ]; then
    update_env_var "STRIPE_PUBLISHABLE_KEY" "$stripe_key"
    echo -e "${GREEN}✓ Stripe key set${NC}"
fi

# Environment Settings
echo ""
echo -e "${BLUE}Environment Settings${NC}"
read -p "Is this a production environment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    update_env_var "DEBUG_MODE" "false"
    update_env_var "MOCK_BACKEND" "false"
    update_env_var "LOG_LEVEL" "error"
    echo -e "${GREEN}✓ Production environment configured${NC}"
else
    update_env_var "DEBUG_MODE" "true"
    update_env_var "MOCK_BACKEND" "false"
    update_env_var "LOG_LEVEL" "debug"
    echo -e "${GREEN}✓ Development environment configured${NC}"
fi

# Security Recommendations
echo ""
echo -e "${YELLOW}Security Recommendations:${NC}"
echo "1. Add .env to your .gitignore file (if not already done)"
echo "2. Use environment variables or CI/CD secrets for production deployment"
echo "3. Rotate API keys regularly"
echo "4. Use different API keys for different environments (dev, staging, prod)"
echo "5. Consider using a secrets management service for production"

# Add .env to .gitignore if not already there
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo "" >> .gitignore
        echo "# Environment variables" >> .gitignore
        echo ".env" >> .gitignore
        echo ".env.local" >> .gitignore
        echo ".env.*.local" >> .gitignore
        echo -e "${GREEN}✓ Added .env to .gitignore${NC}"
    fi
else
    echo ".env" > .gitignore
    echo -e "${GREEN}✓ Created .gitignore with .env${NC}"
fi

# Cleanup backup file
rm -f .env.bak

echo ""
echo -e "${GREEN}🎉 API Key setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Build and test your app with the new configuration"
echo "2. For production deployment, consider using:"
echo "   - Xcode build configurations"
echo "   - CI/CD environment variables"
echo "   - Apple's CloudKit or similar secure storage"
echo ""
echo "Configuration file updated: .env"
echo -e "${YELLOW}⚠ Keep your API keys secure and never commit them to version control!${NC}"
