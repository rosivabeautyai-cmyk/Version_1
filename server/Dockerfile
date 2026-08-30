# ROSIVA AI backend — portable Node image (works on Render, Fly, Railway,
# Koyeb, Cloud Run, plain Docker...).
FROM node:20-slim

ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev --no-audit --no-fund

COPY src ./src

# Drop root.
USER node

# Most PaaS inject PORT; 8080 is the local `docker run` default. The
# server binds 0.0.0.0 so any platform load balancer can reach it.
ENV PORT=8080
EXPOSE 8080

CMD ["node", "src/index.js"]
