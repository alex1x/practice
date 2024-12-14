# practice

## Getting Started

### Prerequisites

Run `./check_requirements.sh` to check if you have all the prerequisites installed and all the required environment variables set.

#### Required Software

- [Just](https://github.com/casey/just)
- [Docker](https://www.docker.com/)
- [Github Account](https://github.com/)
- [AWS Account](https://aws.amazon.com/)
- [Terraform](https://www.terraform.io/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [AWS CLI](https://aws.amazon.com/cli/)
- [Helm](https://helm.sh/)

#### Required Environment Variables

- `GITHUB_USERNAME` - Your Github username.
- `GITHUB_TOKEN` - A Github Personal Access Token with at least the `write:packages` scope. See [Docker and Github Container Registry](#docker-and-github-container-registry) for more information.

## Design Choices

- I have used a private Github Container Registry repository, just to demonstrate how to do it. You can use a public repository if you prefer.

## Developing

- Run `just hello` to build and push the hello service Docker image to the Github Container Registry and deploy it to the Kubernetes cluster.

## Local Testing

- Ensure you've completed the [Prerequisites](#prerequisites) section.
- Install [minikube](https://minikube.sigs.k8s.io/docs/start/) and [kubectl](https://kubernetes.io/docs/tasks/tools/) locally.
- Run `minikube start` to start the Kubernetes cluster.
- Ensure you've logged into the Github Container Registry by running `just docker-login`.
- Run `just hello`. This will build the hello service Docker image and push it to the Github Container Registry.
- Run `k get pod -A` to check that your minikube cluster has working pods.
- (optional) Run `just create-dockerconfigjson` to create a `dockerconfigjson` secret in the Kubernetes cluster which authenticates to the Github Container Registry.
- Run `just deploy-hello` to deploy the hello service to the Kubernetes cluster.
- Run `just test-hello` to test the hello service by running a curl pod and curling the hello service.

The output should look like this:

```
kubectl run curlpod --rm -i --tty --restart=Never --image=curlimages/curl -- /bin/sh -c "curl hello-service:8400; echo"
{"message":"hello world"}
pod "curlpod" deleted
```

Take stock of what we've achieved so far:

- We built a simple nodejs/express hello world service.
- We containerised it with a `Dockerfile`.
- We pushed it to the Github Container Registry.
- We started a local Kubernetes cluster with `minikube`.
- We deployed it to a Kubernetes cluster.
- We tested the service locally by running another pod and curling the service.

## Docker and Github Container Registry

The `Dockerfile` in the `services/hello` directory is configured to push to the Github Container Registry.

To do this, you need to have a Github Personal Access Token with at least the `write:packages` (but ideally also the `delete:packages` so you can clean up afterwards) scope.

You can create one [here](https://github.com/settings/tokens/new?scopes=write:packages,delete:packages&description=Github%20Container%20Registry%20Token).

Once you have a token, you can set it in the `GITHUB_TOKEN` environment variable.

```
export GITHUB_TOKEN=<your-token>
```

Also export your Github username in the `GITHUB_USERNAME` environment variable.

```
export GITHUB_USERNAME=<your-username>
```

Then run `just docker-login` to log into the Github Container Registry.


## Justfile

See [docs/Justfile.md](docs/Justfile.md) for more information.
