# ------------------- Stage 1: Build Stage ------------------------------
    FROM node:21 AS frontend-builder

    WORKDIR /app
    
    # Install dependencies
    COPY package*.json ./
    RUN npm install
    
    # Copy source and build the app with proper env
    COPY . .
    
    # Copy the .env.sample file to .env.local
    COPY .env.docker .env.local
    
    RUN npm run build
    
    # ------------------- Stage 2: Serve with Nginx -------------------------
    FROM nginx:alpine AS production
    
    # Copy built assets
    COPY --from=frontend-builder /app/dist /usr/share/nginx/html
    
    COPY nginx.conf /etc/nginx/nginx.conf
    
    EXPOSE 80
    
    CMD ["nginx", "-g", "daemon off;"]