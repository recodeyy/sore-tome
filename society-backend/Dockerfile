# Node.js 22 (package.json engines require node >=22 <25; tsx runs on 22)
FROM node:22-slim

# System deps: build toolchain + native libs required to compile `canvas`
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package manifests first for better layer caching
COPY package*.json ./

# Install dependencies (lockfile present -> deterministic install)
RUN npm ci

# Copy source code
COPY . .

# Expose port (Render injects PORT at runtime; server.js reads process.env.PORT)
EXPOSE 3001

# Start the application
CMD ["npm", "start"]
