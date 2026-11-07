# syntax=docker/dockerfile:1

# --- Build stage ---------------------------------------------------------
FROM node:24-alpine AS builder
WORKDIR /app

# Install all dependencies (including dev) using the lockfile.
COPY package.json package-lock.json ./
RUN npm ci

# Compile the TypeScript sources to dist/.
COPY . .
RUN npm run build

# Drop dev dependencies so only runtime deps are carried forward.
RUN npm prune --omit=dev

# --- Runtime stage -------------------------------------------------------
FROM node:24-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app

# Copy the pruned production dependencies and the compiled output.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

EXPOSE 3001
CMD ["node", "dist/main.js"]
