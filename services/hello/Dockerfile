# Use the official Node.js image as a parent image
FROM node:23.4-slim

# Set the maintainer label
LABEL maintainer="Alex Tasioulis <tasioulis.alex@gmail.com>"

# Set the Github repository URL and description labels 
LABEL org.opencontainers.image.source="https://github.com/alex1x/practice"
LABEL org.opencontainers.image.description="A simple node.js & express hello world service"

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the package.json and package-lock.json files to the working directory
COPY package*.json ./

# Install the application dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY . .

# Expose the port the app runs on
EXPOSE 8400

# Define the command to run the application
CMD ["node", "main.js"]