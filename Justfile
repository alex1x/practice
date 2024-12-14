# This is the default recipe that lists all the recipes
default:
    just --list --unsorted

# This is a simple recipe that prints "Hello, World!" to the console 
hello:
    echo "Hello, World!"

# Builds a docker image of the hello service and tags it both with the current git commit hash and the latest tag
build-hello:
    docker build -t hello-service:$(git rev-parse --short HEAD) -t hello-service:latest ./services/hello

# Runs the latest docker image of the hello service
run-hello:
    docker run -p 8400:8400 hello-service:latest 

# Cleans up the hello service docker image
clean-hello:
    docker rm -f $(docker ps -a -q --filter "ancestor=hello-service")

