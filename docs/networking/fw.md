---
title: Configure firewall
toc: true
---

## Enable ip forwarding at kernel level

For our machine to be able to act as a router/gateway, we need to enable IP forwarding at the kernel level.

To do this, edit the following file:

```sh
sudo nano /etc/sysctl.d/98-rpi.conf
```

add the following line at the end of it

```
net.ipv4.ip_forward=1
```

## Install and configure ufw

We want a simple no brainer firewall service and configuration. `ufw` is the perfect choice for this.

### Install ufw

To install `ufw`, execute the following command:

```sh
sudo apt update
sudo apt install ufw
```

### Apply firewall rules

We want the firewall to act according to the following:
- all incoming connections to be denied, by default
- all outgoing connections to be allowed, by default
- all routed connections (established outgoing connections originating from the local network) to be allowed, by default
- all incoming connections on our local network interface `br0` (trusted network) to be allowed


```sh
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed
sudo ufw allow in on br0
```

Let's enable the firewall, to make sure it is active and enabled on system startup

```sh
sudo ufw enable
```

### Validate configuration

Let's check that our configuration is correct

```sh
sudo ufw status verbose
```

Should output

```sh
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), allow (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
Anywhere on br0            ALLOW IN    Anywhere
Anywhere (v6) on br0       ALLOW IN    Anywhere (v6)
```
