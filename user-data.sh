#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/"
REPO_URL="https://github.com/crystal-virtuals/bigbrain.git"
REPO_DIR="$APP_DIR/bigbrain"
BACKEND_DIR="$REPO_DIR/backend"

APP_PORT=
# install curl
dnf update -y
dnf install -y curl

# install git
dnf install -y git

# install nvm
export NVM_DIR="/root/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

# load nvm
source "$NVM_DIR/nvm.sh"

# clone repo
mkdir -p $APP_DIR
cd $APP_DIR

if [ ! -d "bigbrain" ]; then
    git clone $REPO_URL
fi

cd "$APP_DIR/bigbrain/backend"

# install nodejs
nvm install
nvm use

# install dependencies
npm install
npm install -g pm2

# setup environment variables
cat <<EOF > .env
DATABASE_URL=${db_connection_string}
PORT=5005
NODE_ENV=production
EOF

# start application with pm2
pm2 start npm --name "bigbrain-backend" -- start
pm2 save

# configure pm2 to start on boot
pm2 startup systemd -u root --hp /root
systemctl enable pm2-root

