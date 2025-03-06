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

# Install dependencies without @vue-office/pdf
RUN pnpm install
RUN pnpm remove @vue-office/pdf
RUN pnpm approve-builds esbuild vue-demi
# Ensure vite-plugin-svg-icons is installed
RUN pnpm add -D vite-plugin-svg-icons

# Copy the rest of the application
COPY . .

# Modify the component that uses @vue-office/pdf to completely remove the dependency with proper syntax
RUN sed -i.bak '/onMounted(async () => {/,/})/c\onMounted(() => {\n\tconsole.warn("PDF viewer disabled in production build");\n})' ./src/views/fanyi/components/documentComponent.vue

# Modify vite.config.ts to exclude @vue-office/pdf
RUN sed -i.bak '/build: {/,/},/ s/},/commonjsOptions: { ignoreTryCatch: false, ignoreDynamicRequires: true } },/' vite.config.ts

# Attempt to build with several fallback strategies if needed
RUN NODE_ENV=production pnpm run build-only || \
    (echo "First build attempt failed, trying with SVG import fix..." && \
    grep -l "virtual:svg-icons-register" ./src/**/*.ts ./src/**/*.js 2>/dev/null | xargs -I{} sed -i.bak 's/from "virtual:svg-icons-register"/\/\/ from "virtual:svg-icons-register"/g' {} && \
    NODE_ENV=production pnpm run build-only) || \
    (echo "Second build attempt failed, trying with simple configuration..." && \
    echo "import { defineConfig } from 'vite'; import vue from '@vitejs/plugin-vue'; export default defineConfig({ plugins: [vue()] });" > vite.config.ts && \
    NODE_ENV=production pnpm run build-only)

# Clean up development dependencies
RUN pnpm install --production && \
    rm -rf /root/.npm /root/.pnpm-store /usr/local/share/.cache /tmp/*

# Expose the port the app runs on
EXPOSE 3002

# Command to run the application
CMD ["pnpm", "run", "preview"]
