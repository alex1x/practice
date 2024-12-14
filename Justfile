# This is the default recipe that lists all the recipes
default:
    just --list --unsorted

# Logs into the Docker registry using the GITHUB_TOKEN environment variable
docker-login:
    echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Builds a docker image of the hello service and tags it both with the current git commit hash and the latest tag
build-hello:
    docker build -t hello-service:$(git rev-parse --short HEAD) -t hello-service:latest ./services/hello

# Runs the latest docker image of the hello service
run-hello:
    docker run -p 8400:8400 hello-service:latest 

# Pushes the hello service docker image to the Github Container Registry
push-hello:
    docker tag hello-service:$(git rev-parse --short HEAD) ghcr.io/$GITHUB_USERNAME/hello-service:$(git rev-parse --short HEAD)
    docker tag hello-service:latest ghcr.io/$GITHUB_USERNAME/hello-service:latest
    docker push ghcr.io/$GITHUB_USERNAME/hello-service:$(git rev-parse --short HEAD)
    docker push ghcr.io/$GITHUB_USERNAME/hello-service:latest

# Cleans up the hello service docker image (if it exists)
clean-hello:
    docker rm -f $(docker ps -a -q --filter "ancestor=hello-service") || true

hello:
    just clean-hello
    just build-hello
    just push-hello



