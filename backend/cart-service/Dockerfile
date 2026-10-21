FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY . .
ENV NODE_ENV=production PORT=3003
EXPOSE 3003
USER node
CMD ["node", "server.js"]
