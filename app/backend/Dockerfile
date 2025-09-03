FROM node:20-alpine AS base

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=produciton

COPY src ./src

EXPOSE 3000

CMD ["node", "src/index.ts"]