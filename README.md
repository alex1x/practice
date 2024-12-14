# practice

## Getting Started

### Prerequisites

- [Just](https://github.com/casey/just)
- [Docker](https://www.docker.com/)
- [Github Account](https://github.com/)

### Required Environment Variables

- `GITHUB_USERNAME` - Your Github username.
- `GITHUB_TOKEN` - A Github Personal Access Token with at least the `write:packages` scope. See [Docker and Github Container Registry](#docker-and-github-container-registry) for more information.

## Entrypoint

Run `just hello` to build and push the hello service Docker image to the Github Container Registry.

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
