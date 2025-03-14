---
Title: "Docker Images"
date: 2024-10-19
categories:
- Docker
tags:
- docker
keywords:
- docker
summary: "Docker Images"
comments: false
showMeta: false
showActions: false
---

```sh
docker run --name=base-container -ti ubuntu
apt update && apt install -y nodejs
node -e 'console.log("Hello world!")'
docker container commit -m "Add node" base-container node-base
docker image history node-base
docker run node-base node -e "console.log('Hello again')"
docker rm -f base-container
```

## Build an app image

```sh
docker run --name=app-container -ti node-base
echo 'console.log("Hello from an app")' > app.js
node app.js
docker container commit -c "CMD node app.js" -m "Add app" app-container sample-app
docker image history sample-app
docker run sample-app
docker rm -f app-container
```

