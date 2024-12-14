# Use the official Node.js image as a parent image
FROM node:23.4-alpine3.20

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