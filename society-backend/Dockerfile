# Use Node.js 20 LTS as base
FROM node:20-slim

# Install system dependencies (for canvas/ocr if needed)
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build TypeScript if needed (assuming tsx is used for run, but for prod usually we build)
# RUN npm run build

# Expose port
EXPOSE 3001

# Start the application
CMD ["npm", "start"]
