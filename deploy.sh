#!/bin/bash

# ======================================================
# WhatsApp Bot Deployment Script for Low-Spec VPS (1GB RAM)
# ======================================================

# Exit on error
set -e

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== WhatsApp Bot Deployment Script for Low-Spec VPS ===${NC}"
echo -e "${YELLOW}This script will optimize and deploy the bot for 1GB RAM VPS${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
  echo -e "${RED}This script should not be run as root${NC}"
  exit 1
fi

# System update
echo -e "${BLUE}[1/10]${NC} ${GREEN}Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install required packages
echo -e "${BLUE}[2/10]${NC} ${GREEN}Installing required packages...${NC}"
sudo apt install -y git curl wget build-essential libgbm-dev gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils

# Setup swap file (important for low memory VPS)
echo -e "${BLUE}[3/10]${NC} ${GREEN}Setting up swap file...${NC}"
if [ ! -f /swapfile ]; then
  sudo fallocate -l 1G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  echo -e "${GREEN}Swap file created and enabled${NC}"
else
  echo -e "${YELLOW}Swap file already exists${NC}"
fi

# Install Node.js 18
echo -e "${BLUE}[4/10]${NC} ${GREEN}Installing Node.js 18...${NC}"
if ! command -v node &> /dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo -e "${GREEN}Node.js $(node -v) installed${NC}"
else
  echo -e "${YELLOW}Node.js $(node -v) already installed${NC}"
fi

# Install PM2
echo -e "${BLUE}[5/10]${NC} ${GREEN}Installing PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
  sudo npm install -g pm2
  echo -e "${GREEN}PM2 installed${NC}"
else
  echo -e "${YELLOW}PM2 already installed${NC}"
fi

# Create log directory
echo -e "${BLUE}[6/10]${NC} ${GREEN}Creating log directory...${NC}"
mkdir -p logs

# Install dependencies (production only)
echo -e "${BLUE}[7/10]${NC} ${GREEN}Installing dependencies (production only)...${NC}"
npm install --production

# Set environment variables
echo -e "${BLUE}[8/10]${NC} ${GREEN}Setting up environment...${NC}"
if [ ! -f .env ]; then
  cp .env.example .env
  echo -e "${YELLOW}Created .env file from example. Please edit it with your API keys${NC}"
  nano .env
else
  echo -e "${YELLOW}.env file already exists${NC}"
fi

# Set Node.js memory limit
echo -e "${BLUE}[9/10]${NC} ${GREEN}Setting Node.js memory limit...${NC}"
export NODE_OPTIONS="--max-old-space-size=512"
echo "export NODE_OPTIONS=\"--max-old-space-size=512\"" >> ~/.bashrc

# Start with PM2
echo -e "${BLUE}[10/10]${NC} ${GREEN}Starting bot with PM2...${NC}"
pm2 start ecosystem.config.js --env production
pm2 save

# Setup PM2 to start on boot
echo -e "${GREEN}Setting up PM2 to start on boot...${NC}"
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME

# Display status
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo -e "${YELLOW}Bot is now running with PM2${NC}"
echo -e "${YELLOW}To check status: ${NC}pm2 status"
echo -e "${YELLOW}To view logs: ${NC}pm2 logs whatsapp-bot-optimized"
echo -e "${YELLOW}To restart bot: ${NC}pm2 restart whatsapp-bot-optimized"
echo -e "${YELLOW}To stop bot: ${NC}pm2 stop whatsapp-bot-optimized"

# Memory optimization tips
echo -e "${BLUE}=== Memory Optimization Tips ===${NC}"
echo -e "${YELLOW}1. Monitor memory usage: ${NC}free -h"
echo -e "${YELLOW}2. Check bot memory: ${NC}pm2 monit"
echo -e "${YELLOW}3. Restart daily: ${NC}Already configured in PM2"
echo -e "${YELLOW}4. Vacuum database weekly: ${NC}sqlite3 bot_data.db \"VACUUM;\""

echo -e "${GREEN}Deployment script completed successfully!${NC}"