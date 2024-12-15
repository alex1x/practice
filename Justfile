# This is the default recipe that lists all the recipes
default:
    just --list --unsorted

check-github-username:
    @if [ -z "$GITHUB_USERNAME" ]; then echo "GITHUB_USERNAME is not set"; exit 1; else echo "GITHUB_USERNAME is set to $GITHUB_USERNAME"; fi

check-github-token:
    @if [ -z "$GITHUB_TOKEN" ]; then echo "GITHUB_TOKEN is not set"; exit 1; else echo "GITHUB_TOKEN is set"; fi

update-github-username:
    @just check-github-username
    find . -type f -exec sed -i "s/alex1x/$GITHUB_USERNAME/g" {} +

# Logs into the Docker registry using the GITHUB_TOKEN environment variable
docker-login:
    @just check-github-username
    @just check-github-token
    echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

# Builds a docker image of the hello service and tags it both with the current git commit hash and the latest tag
build-hello:
    docker build -t hello-service:$(git rev-parse --short HEAD) -t hello-service:latest ./services/hello

# Pushes the hello service docker image to the Github Container Registry
push-hello:
    @just check-github-username  
    docker tag hello-service:$(git rev-parse --short HEAD) ghcr.io/$GITHUB_USERNAME/hello-service:$(git rev-parse --short HEAD)
    docker tag hello-service:latest ghcr.io/$GITHUB_USERNAME/hello-service:latest
    docker push ghcr.io/$GITHUB_USERNAME/hello-service:$(git rev-parse --short HEAD)
    docker push ghcr.io/$GITHUB_USERNAME/hello-service:latest

# Cleans up the hello service docker image (if it exists)
clean-hello:
    kubectl delete deployment hello-service --force || true

# Builds, pushes, deploys the hello service docker image
hello:
    @just clean-hello
    @just build-hello
    @just push-hello
    @just deploy-hello
    @just test-hello

clean-loadgenerator:
    kubectl delete deployment loadgenerator --force || true

build-loadgenerator:
    docker build -t loadgenerator:$(git rev-parse --short HEAD) -t loadgenerator:latest ./services/loadgenerator

push-loadgenerator:
    @just check-github-username
    docker tag loadgenerator:$(git rev-parse --short HEAD) ghcr.io/$GITHUB_USERNAME/loadgenerator:$(git rev-parse --short HEAD)
    docker tag loadgenerator:latest ghcr.io/$GITHUB_USERNAME/loadgenerator:latest
    docker push ghcr.io/$GITHUB_USERNAME/loadgenerator:$(git rev-parse --short HEAD)
    docker push ghcr.io/$GITHUB_USERNAME/loadgenerator:latest

loadgenerator:
    @just clean-loadgenerator
    @just build-loadgenerator
    @just push-loadgenerator

# Creates a dockerconfigjson secret in the Kubernetes cluster which authenticates to the Github Container Registry
create-dockerconfigjson:
    @just check-github-username
    @just check-github-token
    kubectl create secret docker-registry dockerconfigjson-github-com --docker-server=ghcr.io --docker-username=$GITHUB_USERNAME --docker-password=$GITHUB_TOKEN

# Deploys the hello service to the Kubernetes cluster
deploy-hello:
    kubectl apply -f kubernetes/hello.yaml

# Deploys the loadgenerator to the Kubernetes cluster, which will load test the hello service
deploy-loadgenerator:
    echo "Running loadgenerator, this will take a few minutes..."
    kubectl run loadgenerator --rm -i --tty --restart=Never --image=ghcr.io/alex1x/loadgenerator --overrides='{"spec": {"imagePullSecrets": [{"name": "dockerconfigjson-github-com"}]}}' -- -z 5m -c 50 http://hello-service:8400

# Tests the hello service by running a curl pod and curling the hello service
test-hello:
    kubectl run curlpod --rm -i --tty --restart=Never --image=curlimages/curl -- /bin/sh -c "curl hello-service:8400; echo"

install-cert-manager:
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

install-otel-operator:
    kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.115.0/opentelemetry-operator.yaml

install-prometheus-stack:
    helm install prometheus-stack prometheus-community/kube-prometheus-stack

terraform-init:
    (cd terraform && terraform init)

terraform-plan:
    (cd terraform && terraform plan)

terraform-apply:
    (cd terraform && terraform apply -auto-approve)

terraform-output:
    (cd terraform && terraform output)

terraform-destroy:
    (cd terraform && terraform destroy -auto-approve)
