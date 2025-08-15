# ---------- Build stage ----------
FROM node:20-alpine AS builder
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev --ignore-scripts &&     npm cache clean --force
COPY --chown=node:node app.js ./

FROM node:20-alpine AS runtime
ENV NODE_ENV=production     
ENV PORT=3000
WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=node:node /usr/src/app/app.js ./app.js
COPY --from=builder /usr/src/app/package.json ./package.json

USER node

EXPOSE 3000

CMD ["node", "app.js"]
