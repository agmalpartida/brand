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

# Docker Images

- **Base Layer** : The initial FROM instruction grabs the base lunchbox model (e.g., Ubuntu OS). This layer rarely changes.

- **Intermediate Layers** : Each subsequent instruction (RUN, COPY, etc.) usually adds a new transparent tray on top. Installing tools? A layer with utensils. Installing dependencies? The layer with the pre-washed lettuce and specific dressing packet.

- **Layer Caching** : When you build again, Docker checks your recipe. If an instruction hasn't changed (you used the same lettuce), Docker reuses the cached layer from the last time! It only rebuilds starting from the first changed instruction. Changed only your app code (top layer)? The build reuses all the heavy base layers and finishes in seconds, not minutes. It's like the chef grabbing the pre-made salad base and just adding your new garnish. This makes development incredibly fast.

An Image is just the blueprint (the frozen meal). To actually run your application (eat the lunch), you use `docker run <your-image-name>`. This command:

1. Takes the read-only Image layers (the frozen blueprint).

2. Adds a thin, writable layer on top (like a napkin for crumbs or temporary notes during the meal).

3. Starts your application process inside this new structure, following the CMD instruction from your recipe.


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

