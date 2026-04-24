---
title: Remote access
toc: true
---

For this build, we will make use of [ssh](https://www.openssh.org/).

## What is ssh?

SSH stands for Secure Shell (or sometimes Secure Socket Shell). It is a cryptographic network protocol used for operating network services securely over an unsecured network, most commonly for remote command-line login and remote command execution.

## Install ssh

The ssh service should already be installed, by default. In case it is not, you can install it by executing the following:

```sh
sudo apt update
sudo apt install openssh-server
```

## Manage user accesses & permissions

We will manage access permissions using a Unix group called `ssh`.

Let's create the group and add our current user to it.

```sh
sudo addgroup ssh
sudo adduser $USER ssh
```

## Configure ssh

We define our custom configuration for the ssh service by editing a dedicate `custom.conf` file:

```sh
sudo nano /etc/ssh/sshd_config.d/custom.conf
```

Where we add the following content:

```sh
Port 22
PermitRootLogin no
AllowGroups ssh
LoginGraceTime 15
```

Where:
- `Port` defines the port on which the ssh service is listening. For this configuration, we want to listen on port 22 only. We can add more `Port XX` if we wish to open up ssh on additional ports.
- `PermitRootLogin no` indicates we refuse any root login via ssh.
- `AllowGroups ssh` indicates we only allow members of the group `ssh` to connect via ssh.
- `LoginGraceTime 15` sets the time allowed for successful authentication to the SSH server to 15 seconds.

Apply the changes using the following command:

```sh
sudo systemctl restart ssh.service
```

We can then check whether the service configuration was applied successfully, by running 

```sh
sudo systemctl status ssh.service
```

Which should return something like this:

```
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-04-24 20:36:12 CEST; 9s ago
 Invocation: 43c34588fe004e58bc376c9d207de841
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 1023002 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 1023005 (sshd)
      Tasks: 1 (limit: 19359)
        CPU: 33ms
     CGroup: /system.slice/ssh.service
             └─1023005 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Apr 24 20:36:12 cortex systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
Apr 24 20:36:12 cortex sshd[1023005]: Server listening on 0.0.0.0 port 22.
Apr 24 20:36:12 cortex sshd[1023005]: Server listening on :: port 22.
```
