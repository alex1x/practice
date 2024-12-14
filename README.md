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

## Developing

- Run `just hello` to build and push the hello service Docker image to the Github Container Registry and deploy it to the Kubernetes cluster.


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
