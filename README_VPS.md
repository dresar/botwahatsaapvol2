# 🚀 WhatsApp Bot Grup - Optimized for Low-Spec VPS

Bot WhatsApp ringan yang dioptimasi untuk VPS dengan spesifikasi rendah (1 Core, 1GB RAM, 20GB Storage) menggunakan Ubuntu.

## 📋 Spesifikasi VPS Minimum

- **CPU**: 1 Core
- **RAM**: 1GB
- **Storage**: 20GB
- **OS**: Ubuntu 20.04 LTS atau lebih baru

## ⚡ Fitur Utama (Optimized Version)

### 🎮 Game Features
- **Kuis** - Pertanyaan umum dengan berbagai kategori
- **Tebak Kata** - Game menebak kata dengan clue
- **Suit** - Batu gunting kertas
- **Slot Machine** - Game slot sederhana

### 👑 Admin Features
- Manajemen admin (tambah/hapus admin)
- Statistik bot dan database
- Monitoring aktivitas user

### 🤖 AI Assistant
- Powered by Google Gemini AI (dengan penggunaan resource yang dioptimasi)
- Memory lokal per chat (dibatasi untuk menghemat RAM)

## 🔧 Optimasi untuk VPS Spesifikasi Rendah

- **Memory Usage**: Dikurangi hingga 60-70%
- **CPU Usage**: Dikurangi hingga 50-60%
- **Storage**: Penggunaan minimal (<500MB)
- **Dependencies**: Dikurangi dan dioptimasi

## 🚀 Deployment di VPS Ubuntu

### 1. Persiapan Server

```bash
# Update sistem
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git curl wget build-essential

# Setup swap (penting untuk VPS 1GB RAM)
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 2. Install Node.js

```bash
# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2
```

### 3. Clone Repository

```bash
# Clone repository
git clone https://github.com/username/BOTGRUP.git
cd BOTGRUP

# Install dependencies (production only)
npm install --production
```

### 4. Konfigurasi Environment

```bash
# Copy contoh .env
cp .env.example .env

# Edit file .env
nano .env
```

Isi file `.env` dengan konfigurasi berikut:

```env
GEMINI_API_KEY=your_api_key_here
BOT_NAME=WhatsApp Bot
BOT_PREFIX=/
DB_PATH=./bot_data.db
SUPER_ADMIN=628123456789
AI_MAX_HISTORY=8
AI_RESPONSE_LIMIT=400
NODE_OPTIONS=--max-old-space-size=512
```

### 5. Deploy dengan Script Otomatis

```bash
# Berikan permission execute
chmod +x deploy.sh

# Jalankan script deployment
./deploy.sh
```

Atau deploy manual dengan PM2:

```bash
# Set Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=512"

# Start dengan PM2
pm2 start ecosystem.config.js --env production
pm2 save

# Setup PM2 startup
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME
```

## 📱 Penggunaan

Setelah bot berjalan, scan QR code yang muncul di terminal dengan WhatsApp di HP Anda.

### Perintah Dasar

```
/menu - Menu utama
/help - Bantuan
/kuis - Mulai game kuis
/tebakkata - Game tebak kata
/suit [pilihan] - Batu gunting kertas
/slot - Slot machine
/ai [pertanyaan] - Chat dengan AI
```

## 🔍 Monitoring & Maintenance

### Monitoring Resource

```bash
# Cek status PM2
pm2 status

# Monitor resource usage
pm2 monit

# Cek memory usage
free -h

# Cek disk usage
df -h
```

### Maintenance Rutin

```bash
# Restart bot (daily)
pm2 restart whatsapp-bot-optimized

# Clear logs
pm2 flush

# Vacuum database (weekly)
sqlite3 bot_data.db "VACUUM;"

# Clear cache files
rm -rf qr_codes/*.png
```

## 🔄 Update Bot

```bash
# Stop bot
pm2 stop whatsapp-bot-optimized

# Pull latest changes
git pull

# Install dependencies
npm install --production

# Start bot
pm2 restart whatsapp-bot-optimized
```

## ⚠️ Troubleshooting

### Bot Menggunakan Terlalu Banyak RAM

```bash
# Restart bot
pm2 restart whatsapp-bot-optimized

# Cek memory usage
free -h

# Jika masih tinggi, edit config.js dan kurangi nilai:
# - performance.memoryLimit
# - ai.maxHistory
# - cache.stdTTL
```

### QR Code Tidak Muncul

```bash
# Cek logs
pm2 logs whatsapp-bot-optimized

# Restart bot
pm2 restart whatsapp-bot-optimized

# Pastikan puppeteer dependencies terinstall
sudo apt install -y libgbm-dev gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
```

### Database Error

```bash
# Backup database
cp bot_data.db bot_data.db.backup

# Repair database
sqlite3 bot_data.db "PRAGMA integrity_check;"
sqlite3 bot_data.db "VACUUM;"
```

## 📈 Performance Tips

1. **Restart Daily**: Gunakan cron job untuk restart bot setiap hari
2. **Limit Fitur**: Nonaktifkan fitur yang jarang digunakan
3. **Monitor Memory**: Pantau penggunaan memory secara rutin
4. **Optimize Database**: Jalankan VACUUM secara berkala
5. **Update Node.js**: Gunakan versi Node.js terbaru untuk performa lebih baik

## 📝 License

MIT License