# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Stage 2: Production
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
# Coverage tracker reads data/coverage/<state>.yaml at runtime (see coverageService.ts).
# Only this small subtree of data/ is needed in the image.
COPY data/coverage ./data/coverage

EXPOSE 3000
CMD ["node", "--dns-result-order=ipv4first", "dist/index.js"]
