# practice

## Context

This sets up a EKS cluster with a basic nodejs/express service, a load generator service, OpenTelemetry tracing with Jaeger, and Prometheus/Grafana.

In the end you will be able to see things like:

How the load generator service causes the hello service to autoscale.

![Load Generator and Autoscaling](https://github.com/alex1x/practice/blob/main/docs/images/load-generator-and-autoscaling.png)

How Jaeger traces show us where errors occur:

![Jaeger Traces](https://github.com/alex1x/practice/blob/main/docs/images/jaeger-traces-show-credentials-error.png)

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

## How to use

TLDR: `just do-everything`

Once `./check_requirements.sh` is run and all the environment variables are set, you can run `just do-everything` from the root of the repository.

This will ~~do everything~~ create the AWS resources, build and push the hello service Docker image to the Github Container Registry, deploy the hello service to the Kubernetes cluster, and run the loadgenerator to load test the hello service.

Once everything is deployed (will take about 10 minutes), you will get a URL to Grafana and Jaeger. You can login to Grafana (username: `admin`, password: the script will output it on your console) to look at metrics or Jaeger to look at traces. 

In addition, you can run:
- `just test-hello` to test the hello service by running a curl pod and curling it
- `just rbac-test` to test the RBAC policies (this will create a pod with permissions to query the Kubernetes API - and the container will use those to query the Kubernetes API, which you can verify in the pods logs)
- `just loadgenerator` to run the loadgenerator to load test the hello service and watch it autoscale

You can also exec into the hello service and run something like 

```
curl -X POST http://localhost:8400/write -H "Content-Type: application/json" -d '{"id": "123", "data": "sample data"}'
```

This will try to store data on a DynamoDB table we have no permissions for and predictably fail. You can then look at the errors in Jaeger. 

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
- We deployed the service to the Kubernetes cluster.
- We tested the service locally by running another pod and curling the service.

## Design Choices

- I used a *private* Github Container Registry repository, just to demonstrate how to do it. You can use a *public* repository if you prefer.
- I used the official terraform module to create the EKS cluster.
- I used EKS `Auto Mode` because it is easier to set up for a demo.
- I injected a 20% error rate into the hello service to demonstrate that the liveness and readiness probes work.
- I used [hey](https://github.com/rakyll/hey) to load test the hello service and demonstrate autoscaling.
- I set up the OpenTelemetry Collector but didn't configure it fully. However you can see the service is auto-instrumented via the relevant annotation in its manifest, and the traces are being sent to the OpenTelemetry Collector. The next step would be to configure the collector to send those traces to a backend, and to configure OpenTelemetry for metrics and logs. 
- One of the requirements was to configure RBAC "to limit permissions to only what is necessary for the pod and service". The hello world deployment does not need any permissions, so *doing nothing* was a valid solution. However, I created a simple RBAC test in the `kubernetes/rbac-test.yaml` file to demonstrate how to use RBAC if it were needed.
- I did not set up TLS termination at the ingress as part of the happy path because that requires a domain name, which would have been difficult for you to replicate. Instead I set up TLS termination "separately" so I can demonstrate it. 

## Challenges

1. I could not get the path based ingress to work correctly. This is because when you go to `/grafana` it redirects you to `/login`. When you go to `/jaeger` it also tries to redirect you to `/login`. Because ot this conflict I could not get both of them to work at the same time. 
2. I found the cert-manager docs unclear. For example the docs explaining how to create a certificate for nginx ingress mention that you need to use a certain email address and a secret but they don't explain where to register your email address or what the secret should look like.


Options I looked at were:
1. Add an env var to grafana to set the root path to `/grafana`
2. Edit `grafana.ini` to set the root path to `/grafana`
3. Use NGINX rewrite rules to redirect to the correct path

None of these worked for me so I gave up. None of these would be a problem if we had a domain name. 

## Troubleshooting

If `just do-everything` fails, you can re-run it as it's supposed to be idempotent.

In my testing some times certain components would fail to install on a fresh setup due to race conditions. If you run into this, rerun the failing command until it succeeds, then run `just do-everything` again.

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
