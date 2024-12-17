# required to load env vars from .env
set dotenv-load

# This is the default recipe that lists all the recipes
default:
    just --list --unsorted

do-everything:
    @just terraform-init
    @just terraform-apply
    @just docker-login
    @just configure-kubectl
    @just create-dockerconfigjson
    @just install-all-kubernetes-utils
    @just hello
    @just rbac-test
    @just install-ingress
    @just loadgenerator
    @just output-urls

cleanup:
    @just terraform-destroy

check-github-username:
    @if [ -z "$GITHUB_USERNAME" ]; then echo "GITHUB_USERNAME is not set"; exit 1; else echo "GITHUB_USERNAME is set to $GITHUB_USERNAME"; fi

check-github-token:
    @if [ -z "$GITHUB_TOKEN" ]; then echo "GITHUB_TOKEN is not set"; exit 1; else echo "GITHUB_TOKEN is set"; fi

update-github-username:
    @just check-github-username
    find . -type f -exec sed -i "s/alex1x/$GITHUB_USERNAME/g" {} +

update-grafana-password:
    if grep -q "^GRAFANA_PASSWORD=" .env; then sed -i "/^GRAFANA_PASSWORD=/c\GRAFANA_PASSWORD='$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 32)'" .env; else echo "GRAFANA_PASSWORD='$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 32)'" >> .env; fi

output-grafana-password:
    @echo "\033[1;34mGrafana Password:\033[0m ${GRAFANA_PASSWORD}"

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
    kubectl create secret docker-registry dockerconfigjson-github-com --docker-server=ghcr.io --docker-username=$GITHUB_USERNAME --docker-password=$GITHUB_TOKEN --dry-run=client -o yaml | kubectl apply -f -

# Deploys the hello service to the Kubernetes cluster
deploy-hello:
    kubectl apply -f kubernetes/workloads/hello.yaml

# Deploys the loadgenerator to the Kubernetes cluster, which will load test the hello service
deploy-loadgenerator:
    @kubectl delete pod loadgenerator --force || true
    echo "Running loadgenerator, this will take a few minutes..."
    echo "\033[1;32mIgnore the note about if you don't see a command prompt. You won't see one 😊\033[0m"
    echo "Instead, you will see the loadgenerator output in the terminal after 5 minutes 😊"
    kubectl apply -f kubernetes/workloads/loadgenerator.yaml

# Tests the hello service by running a curl pod and curling the hello service
test-hello:
    kubectl run curlpod --rm -i --tty --restart=Never --image=curlimages/curl -- /bin/sh -c "curl hello-service:8400; echo"

install-cert-manager:
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

install-otel-operator:
    kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/download/v0.115.0/opentelemetry-operator.yaml

install-prometheus-stack:
    export $(grep -v '^#' .env | xargs -d '\n') && helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack --set grafana.adminPassword=$GRAFANA_PASSWORD || true

install-metrics-server:
    kubectl apply -f kubernetes/utils/metrics-server.yaml

install-otelcol:
    kubectl apply -f kubernetes/utils/otelcol.yaml

install-jaeger:
    helm upgrade --install jaeger jaegertracing/jaeger --values kubernetes/helm/jaeger.yaml

install-ingress:
    kubectl apply -f kubernetes/utils/ingress.yaml

install-ingress-nginx:
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --set controller.service.type=LoadBalancer --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb" --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"="internet-facing" --set controller.allowSnippetAnnotations=true

install-all-kubernetes-utils:
    @just install-cert-manager
    @just wait-for-cert-manager
    @just install-metrics-server
    @just install-otel-operator
    @just update-grafana-password
    @just install-prometheus-stack
    @just install-otelcol
    @just install-jaeger
    @just install-ingress-nginx
    @just wait-for-ingress
    @echo "Waiting for the ingress to be ready..."
    @sleep 60 # I don't trust the above recipe

wait-for-cert-manager:
    @echo "Waiting for cert-manager to be ready..."
    @until kubectl get pods -l app.kubernetes.io/name=cert-manager -o jsonpath='{.items[0].status.phase}' -n cert-manager | grep -qE 'Running'; do echo "Waiting..."; sleep 10; done
    @until kubectl get pods -l app.kubernetes.io/name=cainjector -o jsonpath='{.items[0].status.phase}' -n cert-manager | grep -qE 'Running'; do echo "Waiting..."; sleep 10; done
    @until kubectl get pods -l app.kubernetes.io/name=webhook -o jsonpath='{.items[0].status.phase}' -n cert-manager | grep -qE 'Running'; do echo "Waiting..."; sleep 10; done
    @echo "Cert-manager is ready."

wait-for-ingress:
    @echo "Waiting for ingress-nginx-controller to have an external IP..."
    @until [ -n "$(kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')" ]; do echo "Waiting..."; sleep 10; done
    @echo "Ingress-nginx-controller has an external IP."

add-lb-url-to-env:
    if grep -q "LB_URL=" .env; then sed -i'' -e "s|LB_URL=.*|LB_URL=$(kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')|" .env; else echo LB_URL=$(kubectl get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') >> .env; fi

output-urls:
    @just add-lb-url-to-env
    export $(grep -v '^#' .env | xargs -d '\n') && just output-urls-from-env 
    @just output-grafana-password

output-urls-from-env:
    @echo "\033[1;34mIngress Load Balancer URL:\033[0m ${LB_URL}"
    @echo "\033[1;34mHello Service URL:\033[0m http://${LB_URL}/hello"
    @echo "\033[1;34mGrafana URL:\033[0m http://${LB_URL}/grafana"
    @echo "\033[1;34mJaeger URL:\033[0m http://${LB_URL}/jaeger - unfortunately this won't work out of the box 😞 instead use this: k port-forward svc/jaeger-query 16686:16686 and go to localhost:16686 on your browser"
    @echo "----------------------------------------"
    @echo ""

rbac-test:
    kubectl apply -f kubernetes/workloads/rbac-test.yaml

configure-kubectl:
    aws eks update-kubeconfig --name $(cd terraform && terraform output -raw cluster_name)

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
