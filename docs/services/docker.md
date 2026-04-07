---
title: Install Docker engine
toc: true
---

## Perform the installation

There are 2 different ways to install Docker engine:
- [Using the apt repository](https://docs.docker.com/engine/install/debian/#install-using-the-repository) (recommended)
- [Using the convenience script](https://docs.docker.com/engine/install/debian/#install-using-the-convenience-script) (faster, but might be unsafe)

## Post-installation steps

The official documentation describes [multiple post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/). We recommend applying the following ones.

### Run docker without sudo

By default, you must use `sudo` for every Docker command. You can add your current user to the `docker` group to run commands more easily.

```sh
sudo adduser $USER docker
```

You should now either logout and log back in, or execute the following to apply the changes to your current session

```sh
newgrp docker
```

### Verify the installation

Nothing beats a good old `hello-world` test to check that all is running as expected. Confirm that Docker is installed and running correctly by executing the following:

```sh
docker run --rm hello-world
```

You can also validate that it is running with the right `aarch64` 64 bits architecture by executing:

```sh
docker info | grep Architecture
```
