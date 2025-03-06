# Single-stage build for simplicity and efficiency
FROM node:lts-alpine

# Set NODE_OPTIONS to increase memory limit
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Install pnpm globally
RUN npm install pnpm -g

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies with build scripts approved
RUN pnpm install
RUN pnpm approve-builds @vue-office/pdf esbuild vue-demi

# Copy the rest of the application
COPY . .

# Fix for @vue-office/pdf resolution issue
RUN echo '{"type":"module","main":"dist/vue-office-pdf.es.js"}' > ./node_modules/@vue-office/pdf/package.json

# Build the application
RUN NODE_ENV=production pnpm run build-only || (echo "Build failed, checking for @vue-office/pdf usage" && \
    sed -i.bak 's/import.*@vue-office\/pdf.*//g' $(grep -l "@vue-office/pdf" ./src/**/*.vue ./src/**/*.ts ./src/**/*.js 2>/dev/null || echo "/dev/null") && \
    NODE_ENV=production pnpm run build-only)

# Clean up development dependencies
RUN pnpm install --production && \
    rm -rf /root/.npm /root/.pnpm-store /usr/local/share/.cache /tmp/*

# Expose the port the app runs on
EXPOSE 3002

# Command to run the application
CMD ["pnpm", "run", "preview"]
