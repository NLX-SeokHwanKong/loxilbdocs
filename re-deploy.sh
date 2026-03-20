#!/bin/bash
cd /var/www/loxilbdocs
git pull
source venv/bin/activate
mkdocs build --clean
deactivate
sudo systemctl reload nginx