FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY . .
ENV NODE_ENV=production PORT=3004
EXPOSE 3004
USER node
CMD ["node", "server.js"]
