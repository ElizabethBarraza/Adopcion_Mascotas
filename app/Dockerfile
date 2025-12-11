FROM node:18-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 8080
ENV NODE_ENV=production

CMD ["npm", "start"]
