# ---------- Build stage ----------
FROM node:20-alpine AS builder

ENV NODE_ENV=production     npm_config_fund=false     npm_config_audit=false

WORKDIR /usr/src/app

# Copy manifests (works whether or not package-lock.json exists)
COPY package*.json ./

# Prefer reproducible install if lockfile exists; otherwise fall back.
# Also skip lifecycle scripts and dev dependencies during build.
RUN if [ -f package-lock.json ]; then       npm ci --omit=dev --ignore-scripts;     else       npm install --omit=dev --ignore-scripts;     fi &&     npm cache clean --force

# Copy application source
COPY --chown=node:node app.js ./

# ---------- Runtime stage ----------
FROM node:20-alpine AS runtime

ENV NODE_ENV=production     PORT=3000

WORKDIR /usr/src/app

# Copy runtime artifacts only
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=node:node /usr/src/app/app.js ./app.js
COPY --from=builder /usr/src/app/package.json ./package.json

# Add a container-level healthcheck (Alpine includes busybox wget)
HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=5s   CMD wget -qO- http://127.0.0.1:3000/ >/dev/null || exit 1

# Run as non-root user
USER node

EXPOSE 3000

CMD ["node", "app.js"]
