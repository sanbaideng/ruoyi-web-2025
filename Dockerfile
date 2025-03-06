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

# Modify the component that uses @vue-office/pdf to completely remove the dependency with proper syntax
RUN sed -i.bak 's|onMounted(async () => {.*try {.*const module = await import.*}.*} catch (error) {.*console.error.*}.*})|onMounted(() => { console.warn("PDF viewer disabled in production build"); })|s' ./src/views/fanyi/components/documentComponent.vue

# Ensure vite-plugin-svg-icons is properly installed and configured
RUN pnpm add -D vite-plugin-svg-icons

# Create a temporary file to handle the SVG import in main.ts
RUN cp ./src/main.ts ./src/main.ts.bak && \
    sed -i 's|import .virtual:svg-icons-register.|// import from "virtual:svg-icons-register"|g' ./src/main.ts

# Copy the rest of the application
COPY . .

# Build the app
RUN NODE_ENV=production pnpm run build-only || \
    (echo "Build failed, attempting with simplified vite config..." && \
    echo "import { defineConfig } from 'vite'; import vue from '@vitejs/plugin-vue'; import svgIcons from 'vite-plugin-svg-icons'; import path from 'path'; export default defineConfig({ plugins: [vue(), svgIcons({ iconDirs: [path.resolve(process.cwd(), 'src/assets/icons')], symbolId: 'icon-[dir]-[name]' })], build: { commonjsOptions: { ignoreTryCatch: false, ignoreDynamicRequires: true } } });" > vite.config.ts && \
    NODE_ENV=production pnpm run build-only)

# Clean up development dependencies
RUN pnpm install --production && \
    rm -rf /root/.npm /root/.pnpm-store /usr/local/share/.cache /tmp/*

# Expose the port the app runs on
EXPOSE 3002

# Command to run the application
CMD ["pnpm", "run", "preview"]
