FROM alpine:latest

LABEL maintainer="Alex Tasioulis <tasioulis.alex@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/alex1x/practice"
LABEL org.opencontainers.image.description="A image to load test the hello service"

RUN apk --no-cache add curl

RUN curl -L https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -o /usr/local/bin/hey && \
    chmod +x /usr/local/bin/hey

ENTRYPOINT ["hey"]
