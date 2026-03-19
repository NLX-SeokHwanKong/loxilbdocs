#!/bin/bash
set -e

# ============================================================
# deploy.sh — LoxiLB Enterprise Docs deployment script
# Usage: bash deploy.sh [DOMAIN_OR_IP]
# Example: bash deploy.sh docs.netlox.io
#          bash deploy.sh 1.2.3.4
# ============================================================

REPO_URL="https://github.com/netlox-dev/loxilbdocs-enterprise.git"
SITE_DIR="/var/www/loxilbdocs"
SERVER_NAME="${1:-_}"   # defaults to catch-all if no domain/IP given

echo "============================================"
echo " LoxiLB Enterprise Docs — Deploy Script"
echo " Server name: $SERVER_NAME"
echo "============================================"

# ── 1. System packages ───────────────────────────────────────
echo "[1/6] Installing system packages..."
sudo apt-get update -y -q
sudo apt-get install -y -q python3-pip python3-venv nginx git curl

# ── 2. Clone or update repo ──────────────────────────────────
echo "[2/6] Fetching repository..."
if [ -d "$SITE_DIR/.git" ]; then
    echo "  → Repository exists, pulling latest..."
    git -C "$SITE_DIR" pull
else
    sudo mkdir -p "$SITE_DIR"
    sudo chown "$USER:$USER" "$SITE_DIR"
    git clone "$REPO_URL" "$SITE_DIR"
fi

# ── 3. Python virtualenv + pip packages ──────────────────────
echo "[3/6] Setting up Python environment..."
cd "$SITE_DIR"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
# shellcheck disable=SC1091
source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet \
    "mkdocs>=1.5.0,<2.0.0" \
    "mkdocs-material>=9.4.0,<10.0.0" \
    "mike>=2.0.0,<3.0.0" \
    "mkdocs-glightbox>=0.3.0" \
    "mkdocs-autorefs>=0.5.0" \
    "pymdown-extensions>=10.0.0,<11.0.0"
deactivate

# ── 4. Build static site ─────────────────────────────────────
echo "[4/6] Building MkDocs site..."
cd "$SITE_DIR"
source venv/bin/activate
mkdocs build --clean
deactivate
echo "  → Site built at $SITE_DIR/site/"

# ── 5. Nginx configuration ───────────────────────────────────
echo "[5/6] Configuring nginx..."
sudo tee /etc/nginx/sites-available/loxilbdocs > /dev/null <<EOF
server {
    listen 80;
    server_name ${SERVER_NAME};

    root ${SITE_DIR}/site;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    location / {
        try_files \$uri \$uri/ \$uri.html =404;
    }

    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff2?)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
}
EOF

# Enable site, disable default
sudo ln -sf /etc/nginx/sites-available/loxilbdocs /etc/nginx/sites-enabled/loxilbdocs
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# ── 6. Done ──────────────────────────────────────────────────
echo "[6/6] Deployment complete!"
echo ""
echo "  Docs are now live at: http://${SERVER_NAME}"
echo ""
echo "  To update after a new push, run:"
echo "    bash $SITE_DIR/deploy.sh ${SERVER_NAME}"
echo ""
echo "  To add HTTPS (Let's Encrypt), run:"
echo "    sudo apt install -y certbot python3-certbot-nginx"
echo "    sudo certbot --nginx -d ${SERVER_NAME}"
