# albertogalvez.com - A hugo homepage

[![Create and publish a Docker image](https://github.com/agmalpartida/brand/actions/workflows/dockerimage.yaml/badge.svg?branch=published)](https://github.com/agmalpartida/brand/actions/workflows/dockerimage.yaml)

A blog/notes page in hugo.

## Requirements

Hugo v0.92+

## Generate static data in /public

```
git submodule update --init --recursive

or

git clone https://github.com/reorx/hugo-PaperModX.git themes/PaperModX
```

## Start Hugo server

To test and create a purpose to execute the command above:

```sh
hugo server --config config-dev.toml --disableFastRender -D
```

## Build

```sh
docker build --platform linux/amd64 -t hugo .
```


