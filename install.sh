#!/bin/bash

# install.sh - Script instalasi WhatsApp Bot untuk VPS Ubuntu
# Optimized for 1 Core, 1GB RAM, 20GB Storage

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1"
}

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "================================================="
    echo "    WhatsApp Bot VPS Installer (Optimized)    "
    echo "    For Ubuntu with 1GB RAM, 1 Core, 20GB     "
    echo "================================================="
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "Script berjalan sebagai root"
        print_warning "Beberapa operasi akan dilakukan dengan sudo"
    fi
}

# Check Ubuntu version
check_ubuntu() {
    if [ ! -f /etc/os-release ]; then
        print_error "Tidak dapat mendeteksi OS. Script ini untuk Ubuntu."
        exit 1
    fi
    
    . /etc/os-release
    
    if [ "$ID" != "ubuntu" ]; then
        print_error "Script ini hanya untuk Ubuntu. OS terdeteksi: $ID"
        exit 1
    fi
    
    print_success "Ubuntu $VERSION_ID terdeteksi"
}

# Check system resources
check_resources() {
    print_header "Checking System Resources"
    
    # Check RAM
    TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    FREE_RAM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    
    print_status "Total RAM: ${TOTAL_RAM}MB"
    print_status "Free RAM: ${FREE_RAM}MB"
    
    if [ "$TOTAL_RAM" -lt 900 ]; then
        print_warning "RAM total kurang dari 1GB (${TOTAL_RAM}MB). Bot mungkin tidak stabil."
    fi
    
    # Check CPU
    CPU_CORES=$(nproc)
    print_status "CPU Cores: ${CPU_CORES}"
    
    # Check disk space
    DISK_AVAIL=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    print_status "Available disk space: ${DISK_AVAIL}GB"
    
    if [ "$DISK_AVAIL" -lt 5 ]; then
        print_error "Disk space tidak cukup (${DISK_AVAIL}GB). Minimal 5GB diperlukan."
        exit 1
    fi
    
    print_success "System resources check passed"
}

# Update system
update_system() {
    print_header "Updating System"
    
    print_status "Updating package list..."
    sudo apt update
    
    print_status "Upgrading packages..."
    sudo apt upgrade -y
    
    print_success "System updated"
}

# Install basic dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    print_status "Installing basic packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        unzip \
        htop \
        nano \
        vim
    
    print_success "Basic dependencies installed"
}

# Setup swap file
setup_swap() {
    print_header "Setting Up Swap File"
    
    # Check if swap already exists
    if swapon --show | grep -q '/swapfile'; then
        print_warning "Swap file already exists"
        return
    fi
    
    print_status "Creating 1GB swap file..."
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    # Make swap permanent
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    # Optimize swap settings for low RAM
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    
    print_success "Swap file created and configured"
}

# Install Node.js
install_nodejs() {
    print_header "Installing Node.js"
    
    # Check if Node.js is already installed
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 16 ]; then
            print_success "Node.js $(node --version) already installed"
            return
        else
            print_warning "Node.js version too old ($(node --version)). Updating..."
        fi
    fi
    
    print_status "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    if command -v node &> /dev/null; then
        print_success "Node.js $(node --version) installed"
        print_success "npm $(npm --version) installed"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Install PM2
install_pm2() {
    print_header "Installing PM2"
    
    if command -v pm2 &> /dev/null; then
        print_success "PM2 $(pm2 --version) already installed"
        return
    fi
    
    print_status "Installing PM2 globally..."
    sudo npm install -g pm2
    
    # Setup PM2 startup
    print_status "Setting up PM2 startup..."
    sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME
    
    print_success "PM2 installed and configured"
}

# Install Puppeteer dependencies
install_puppeteer_deps() {
    print_header "Installing Puppeteer Dependencies"
    
    print_status "Installing Chrome/Chromium dependencies..."
    sudo apt install -y \
        libgbm-dev \
        gconf-service \
        libasound2 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgcc1 \
        libgconf-2-4 \
        libgdk-pixbuf2.0-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        ca-certificates \
        fonts-liberation \
        libappindicator1 \
        libnss3 \
        lsb-release \
        xdg-utils
    
    print_success "Puppeteer dependencies installed"
}

# Create bot user (optional)
create_bot_user() {
    print_header "Creating Bot User (Optional)"
    
    read -p "Create dedicated user for bot? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter username for bot (default: botuser): " BOT_USER
        BOT_USER=${BOT_USER:-botuser}
        
        if id "$BOT_USER" &>/dev/null; then
            print_warning "User $BOT_USER already exists"
        else
            print_status "Creating user $BOT_USER..."
            sudo useradd -m -s /bin/bash "$BOT_USER"
            sudo usermod -aG sudo "$BOT_USER"
            print_success "User $BOT_USER created"
        fi
        
        print_status "To switch to bot user: sudo su - $BOT_USER"
    else
        print_status "Continuing with current user: $USER"
    fi
}

# Setup bot directory
setup_bot_directory() {
    print_header "Setting Up Bot Directory"
    
    read -p "Enter bot directory path (default: ~/whatsapp-bot): " BOT_DIR
    BOT_DIR=${BOT_DIR:-~/whatsapp-bot}
    
    # Expand tilde
    BOT_DIR=$(eval echo "$BOT_DIR")
    
    if [ -d "$BOT_DIR" ]; then
        print_warning "Directory $BOT_DIR already exists"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled"
            exit 1
        fi
    else
        print_status "Creating directory $BOT_DIR..."
        mkdir -p "$BOT_DIR"
    fi
    
    cd "$BOT_DIR"
    print_success "Working directory: $(pwd)"
    
    # Create subdirectories
    print_status "Creating subdirectories..."
    mkdir -p logs qr_codes media temp backups
    
    export BOT_DIR
}

# Clone or copy bot files
setup_bot_files() {
    print_header "Setting Up Bot Files"
    
    read -p "Do you want to clone from Git repository? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Git repository URL: " GIT_REPO
        if [ -n "$GIT_REPO" ]; then
            print_status "Cloning repository..."
            git clone "$GIT_REPO" .
            print_success "Repository cloned"
        else
            print_error "No repository URL provided"
            exit 1
        fi
    else
        print_warning "Please copy your bot files to: $BOT_DIR"
        print_warning "Required files: package.json, app.js (or app-optimized.js), config.js, etc."
        read -p "Press Enter when files are ready..." -r
    fi
}

# Install bot dependencies
install_bot_dependencies() {
    print_header "Installing Bot Dependencies"
    
    if [ ! -f "package.json" ]; then
        print_error "package.json not found. Please ensure bot files are in place."
        exit 1
    fi
    
    print_status "Installing Node.js dependencies..."
    npm install --production --no-optional
    
    print_success "Bot dependencies installed"
}

# Setup environment file
setup_environment() {
    print_header "Setting Up Environment"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_status "Copying .env.example to .env..."
            cp .env.example .env
        else
            print_status "Creating basic .env file..."
            cat > .env << EOF
# WhatsApp Bot Environment Configuration
NODE_ENV=production
NODE_OPTIONS=--max-old-space-size=512

# Bot Configuration
BOT_NAME=WhatsApp Bot VPS
BOT_PREFIX=/

# Admin Configuration (REQUIRED)
SUPER_ADMIN=628123456789

# AI Configuration (REQUIRED)
GEMINI_API_KEY=your_gemini_api_key_here

# Database
DB_PATH=./bot_data.db

# Performance Settings
MEMORY_LIMIT=256
GC_INTERVAL=180000
CACHE_TTL=300

# Monitoring
MEMORY_WARNING_THRESHOLD=350
MEMORY_CRITICAL_THRESHOLD=400
AUTO_RESTART_ENABLED=true
EOF
        fi
        
        print_success ".env file created"
    else
        print_warning ".env file already exists"
    fi
    
    print_warning "IMPORTANT: Edit .env file and configure:"
    echo "  - SUPER_ADMIN: Your WhatsApp number (format: 628123456789)"
    echo "  - GEMINI_API_KEY: Your Google Gemini API key"
    echo "  - Other settings as needed"
    
    read -p "Open .env file for editing now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        nano .env
    fi
}

# Setup systemd service (alternative to PM2)
setup_systemd_service() {
    print_header "Setting Up Systemd Service (Optional)"
    
    read -p "Create systemd service? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SERVICE_NAME="whatsapp-bot"
        SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
        
        print_status "Creating systemd service..."
        
        sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=WhatsApp Bot Optimized
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$BOT_DIR
Environment=NODE_ENV=production
Environment=NODE_OPTIONS=--max-old-space-size=512
ExecStart=/usr/bin/node app-optimized.js
Restart=always
RestartSec=10
KillMode=process
TimeoutSec=300
TimeoutStopSec=300
KillSignal=SIGINT

# Resource limits
MemoryMax=500M
MemoryHigh=400M

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=whatsapp-bot

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
        
        print_success "Systemd service created: $SERVICE_NAME"
        print_status "Use 'sudo systemctl start $SERVICE_NAME' to start"
        print_status "Use 'sudo systemctl status $SERVICE_NAME' to check status"
    fi
}

# Setup firewall
setup_firewall() {
    print_header "Setting Up Firewall (Optional)"
    
    if command -v ufw &> /dev/null; then
        read -p "Configure UFW firewall? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Configuring UFW..."
            sudo ufw --force enable
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw allow ssh
            
            print_success "UFW firewall configured"
        fi
    else
        print_warning "UFW not installed. Consider installing: sudo apt install ufw"
    fi
}

# Setup monitoring
setup_monitoring() {
    print_header "Setting Up Monitoring"
    
    # Create monitoring script
    cat > monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script

echo "=== WhatsApp Bot Status ==="
echo "Date: $(date)"
echo ""

echo "=== PM2 Status ==="
pm2 status 2>/dev/null || echo "PM2 not running"
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h .
echo ""

echo "=== CPU Usage ==="
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
echo ""

echo "=== Bot Logs (last 10 lines) ==="
tail -n 10 logs/combined.log 2>/dev/null || echo "No logs found"
EOF
    
    chmod +x monitor.sh
    
    print_success "Monitoring script created: ./monitor.sh"
}

# Final setup
final_setup() {
    print_header "Final Setup"
    
    # Make scripts executable
    if [ -f "start.sh" ]; then
        chmod +x start.sh
        print_success "start.sh made executable"
    fi
    
    if [ -f "deploy.sh" ]; then
        chmod +x deploy.sh
        print_success "deploy.sh made executable"
    fi
    
    # Set proper permissions
    chmod 755 .
    chmod -R 755 logs qr_codes media temp backups 2>/dev/null || true
    
    print_success "Permissions set"
}

# Show completion message
show_completion() {
    print_header "Installation Complete!"
    
    echo -e "${GREEN}"
    echo "================================================="
    echo "    WhatsApp Bot Installation Completed!       "
    echo "================================================="
    echo -e "${NC}"
    
    echo "Next steps:"
    echo "1. Edit .env file and configure API keys:"
    echo "   nano .env"
    echo ""
    echo "2. Start the bot:"
    echo "   ./start.sh --pm2"
    echo ""
    echo "3. Monitor the bot:"
    echo "   pm2 status"
    echo "   pm2 logs whatsapp-bot-optimized"
    echo "   ./monitor.sh"
    echo ""
    echo "4. Useful commands:"
    echo "   ./start.sh --status    # Check status"
    echo "   ./start.sh --restart   # Restart bot"
    echo "   ./start.sh --stop      # Stop bot"
    echo "   ./start.sh --cleanup   # Cleanup files"
    echo ""
    echo "Bot directory: $BOT_DIR"
    echo "Log files: $BOT_DIR/logs/"
    echo ""
    print_warning "Remember to configure .env file before starting!"
}

# Main installation function
main() {
    print_banner
    
    check_root
    check_ubuntu
    check_resources
    
    update_system
    install_dependencies
    setup_swap
    install_nodejs
    install_pm2
    install_puppeteer_deps
    
    create_bot_user
    setup_bot_directory
    setup_bot_files
    install_bot_dependencies
    setup_environment
    
    setup_systemd_service
    setup_firewall
    setup_monitoring
    final_setup
    
    show_completion
}

# Run main function
main "$@"