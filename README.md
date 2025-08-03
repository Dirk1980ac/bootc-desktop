# bootc-desktop

## Description

This generates  a bootc desktop image. it is basically a Fedora Workstation or
Fedora Silverblue with additional software installed. It can be used as a
workstation or as entertainment station.

The image is configured to query free public (recirsive) DNS servers to circumvent
the 'tampered' DNS servers provided by ISPs (at least in Germany).

Multimedia software is installed as well as Firefox, Chromium, Evolution, pass
and browserpass-native for firefoy and chromium, Libreoffice etc.

Base image for thos is fedora-bootc:latest which represents the actual stable
release. The 'Fedora Workstation' environment without 'weak dependencies'.

## Get image

The resulting images are automatically built and uploaded to the
[Dockerhub repository](https://hub.docker.com/repository/docker/dirk1980/bootc-desktop/general).

Podman/docker URL: docker.io/dirk1980/bootc-desktop:latest

## Build

### Prerequisites

You will have to change configs/container-policy.json to reflect your signature
keys and repositories if you want to use signatures in your image.

### Building

To build the container image at your own just clone this repository you have to
have podman (or docker) installed on your system.

if you have podman installed run:

```sh
podman build \
  --rm \
  --pull=always \
  --network=host \
  --build-id="$(date -u +%Y%m%d.%H%M)" \
  --security-opt label=type:unconfined_t \
  -t [IMAGE-NAME]:[tag] .
```

## Installation

An instruction how to deploy the downloaded image can be found in fedoras bootc
[documentation](https://docs.fedoraproject.org/en-US/bootc/bare-metal/).
