# Dockerfile

### Stage 1: Build Frontend ###
FROM node:18-alpine AS frontend-build
RUN corepack enable
WORKDIR /app
COPY    package*.json craco.config.js ./
RUN     yarn install
COPY    src ./src
COPY    public ./public
RUN     yarn build
COPY    storage ./storage

### Stage 2: Build Backend ###
FROM node:18-alpine AS backend-build
RUN corepack enable
WORKDIR /app/backend
COPY    backend/package*.json ./
RUN     yarn install
COPY    backend ./
COPY    lynx-db.gzip ./

### Stage 3: Final Image (nginx + backend) ###
FROM nginx:alpine

# Install Node.js and Yarn so we can run the backend
RUN apk add --no-cache nodejs yarn bash

# Copy NGINX configs & certificates
COPY nginx.conf            /etc/nginx/nginx.conf
COPY default               /etc/nginx/conf.d/default.conf
COPY localhost.pem              /etc/nginx/certs/localhost.pem
COPY localhost-key.pem              /etc/nginx/certs/localhost-key.pem

# Copy built frontend and backend code
COPY --from=frontend-build  /app/build        /var/www/lynx-dev
COPY --from=backend-build   /app/backend      /app/backend
COPY --from=frontend-build /app/storage /storage
# Fix permissions so nginx can read the files
RUN chown -R nginx:nginx /var/www/lynx-dev

# Copy and make your start script executable
COPY start.sh              /start.sh
RUN  chmod +x /start.sh

EXPOSE 80 443
CMD ["/start.sh"]
