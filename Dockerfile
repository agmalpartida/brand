# Use the base image 'ubuntu:bionic'
FROM ubuntu:bionic as builder

# Define the Hugo version
ARG TARGETARCH
ARG HUGO_VERSION="0.131.0"

# Update the package repository
RUN apt-get update && \
    apt-get install -y \
        ca-certificates \
        wget && \
    update-ca-certificates
# Download and install Hugo
RUN wget --quiet "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz" && \
    tar xzf hugo_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz && \
    rm -r hugo_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz && \
    mv hugo /usr/bin && \
    chmod 755 /usr/bin/hugo
## Hugo source code
# Set the working directory to '/src'
WORKDIR /src
# Copy code into the '/src' directory
COPY ./ /src
# Command to run when the container starts
RUN hugo --minify --gc
#RUN hugo --minify --gc --enableGitInfo
# Set the fallback 404 page if defaultContentLanguageInSubdir is enabled, please replace the `en` with your default language code.
# RUN cp ./public/en/404.html ./public/404.html

###############
# Final Stage #
###############
FROM nginx:1.25.4-alpine
COPY --from=builder /src/public /usr/share/nginx/html
