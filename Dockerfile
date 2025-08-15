
FROM node:20-alpine AS builder
ENV NODE_ENV=production     npm_config_fund=false     npm_config_audit=false
WORKDIR /usr/src/app
COPY package*.json ./
RUN if [ -f package-lock.json ]; then       npm ci --omit=dev --ignore-scripts;     else       npm install --omit=dev --ignore-scripts;     fi &&     npm cache clean --force
COPY --chown=node:node app.js ./

# ---------- Runtime stage ----------
FROM node:20-alpine AS runtime

ENV NODE_ENV=production     PORT=3000

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=node:node /usr/src/app/app.js ./app.js
COPY --from=builder /usr/src/app/package.json ./package.json

USER node

EXPOSE 3000

CMD ["node", "app.js"]
