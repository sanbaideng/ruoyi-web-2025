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

# Copy the rest of the application
COPY . .

# Modify the component that uses @vue-office/pdf to completely remove the dependency
RUN sed -i.bak 's/const module = await import(.@vue-office\/pdf.).*/console.warn("PDF viewer disabled in production build");/' ./src/views/fanyi/components/documentComponent.vue

# Create vite.config.js with proper configuration
RUN echo 'import path from "path";' > vite.config.js && \
    echo 'import { defineConfig, loadEnv } from "vite";' >> vite.config.js && \
    echo 'import vue from "@vitejs/plugin-vue";' >> vite.config.js && \
    echo 'import { createSvgIconsPlugin } from "vite-plugin-svg-icons";' >> vite.config.js && \
    echo 'function setupPlugins() {' >> vite.config.js && \
    echo '  return [' >> vite.config.js && \
    echo '    vue(),' >> vite.config.js && \
    echo '    createSvgIconsPlugin({' >> vite.config.js && \
    echo '      iconDirs: [path.resolve(process.cwd(), "src/assets/icons")],' >> vite.config.js && \
    echo '      symbolId: "icon-[name]",' >> vite.config.js && \
    echo '    })' >> vite.config.js && \
    echo '  ];' >> vite.config.js && \
    echo '}' >> vite.config.js && \
    echo 'export default defineConfig(({ mode }) => {' >> vite.config.js && \
    echo '  const viteEnv = loadEnv(mode, process.cwd());' >> vite.config.js && \
    echo '  return {' >> vite.config.js && \
    echo '    resolve: { alias: { "@": path.resolve(process.cwd(), "src") } },' >> vite.config.js && \
    echo '    plugins: setupPlugins(),' >> vite.config.js && \
    echo '    build: {' >> vite.config.js && \
    echo '      reportCompressedSize: false,' >> vite.config.js && \
    echo '      sourcemap: false,' >> vite.config.js && \
    echo '      commonjsOptions: { ignoreTryCatch: false, ignoreDynamicRequires: true }' >> vite.config.js && \
    echo '    }' >> vite.config.js && \
    echo '  };' >> vite.config.js && \
    echo '});' >> vite.config.js

# Build the application
RUN NODE_ENV=production pnpm run build-only

# Clean up development dependencies
RUN pnpm install --production && \
    rm -rf /root/.npm /root/.pnpm-store /usr/local/share/.cache /tmp/*

# Expose the port the app runs on
EXPOSE 3002

# Command to run the application
CMD ["pnpm", "run", "preview"]
