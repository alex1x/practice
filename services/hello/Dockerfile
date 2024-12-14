FROM node:23.4-slim

LABEL maintainer="Alex Tasioulis <tasioulis.alex@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/alex1x/practice"
LABEL org.opencontainers.image.description="A simple node.js & express hello world service"

WORKDIR /

COPY package*.json ./

RUN npm install

# Copy the rest of the application code to the working directory
COPY . .

EXPOSE 8400

CMD ["node", "main.js"]