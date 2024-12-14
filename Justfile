# This is the default recipe that lists all the recipes
default:
    just --list --unsorted

# Logs into the Docker registry using the GITHUB_TOKEN environment variable
docker-login:
    echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Builds a docker image of the hello service and tags it both with the current git commit hash and the latest tag
build-hello:
    docker build -t hello-service:$(git rev-parse --short HEAD) -t hello-service:latest ./services/hello

# Pushes the hello service docker image to the Github Container Registry
push-hello:
    docker tag hello-service:$(git rev-parse --short HEAD) ghcr.io/$GITHUB_USERNAME/hello-service:$(git rev-parse --short HEAD)
    docker tag hello-service:latest ghcr.io/$GITHUB_USERNAME/hello-service:latest
    docker push ghcr.io/$GITHUB_USERNAME/hello-service:$(git rev-parse --short HEAD)
    docker push ghcr.io/$GITHUB_USERNAME/hello-service:latest

# Cleans up the hello service docker image (if it exists)
clean-hello:
    docker rm -f $(docker ps -a -q --filter "ancestor=hello-service") || true

# Builds, pushes, deploys the hello service docker image
hello:
    just clean-hello
    just build-hello
    just push-hello
    just deploy-hello
    just test-hello

# Creates a dockerconfigjson secret in the Kubernetes cluster which authenticates to the Github Container Registry
create-dockerconfigjson:
    kubectl create secret docker-registry dockerconfigjson-github-com --docker-server=ghcr.io --docker-username=$GITHUB_USERNAME --docker-password=$GITHUB_TOKEN

# Deploys the hello service to the Kubernetes cluster
deploy-hello:
    kubectl apply -f kubernetes/hello.yaml

# Tests the hello service by running a curl pod and curling the hello service
test-hello:
    kubectl run curlpod --rm -i --tty --restart=Never --image=curlimages/curl -- /bin/sh -c "curl hello-service:8400; echo"

terraform-init:
    (cd terraform && terraform init)

terraform-apply:
    (cd terraform && terraform apply -auto-approve)

terraform-destroy:
    (cd terraform && terraform destroy -auto-approve)
