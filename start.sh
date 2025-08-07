#!/bin/sh
# 1) Run your backend
cd /app/backend
yarn install      # safe to re-install or change to 'yarn --production'
yarn start &

# Restore DB (only once, skip if already restored)
if [ ! -f /data/db/.restored ]; then
  mongorestore --gzip --archive=/app/backend/lynx-db.gzip
  touch /data/db/.restored
fi

# 2) Start nginx in foreground
nginx -g 'daemon off;'
