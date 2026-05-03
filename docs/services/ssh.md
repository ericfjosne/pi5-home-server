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
sudo addgroup ssh-users
sudo adduser $USER ssh-users
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
PubkeyAuthentication yes
PasswordAuthentication yes
UsePAM no
X11Forwarding no
AllowGroups ssh-users
LoginGraceTime 15
```

Where:
- `Port` defines the port on which the ssh service is listening. For this configuration, we want to listen on port 22 only. We can add more `Port XX` if we wish to open up ssh on additional ports.
- `PermitRootLogin no` indicates we refuse any root login via ssh.
- `PubkeyAuthentication yes` indicates we allow authentication using ssh keys (preferred).
- `PasswordAuthentication yes` indicates we allow authentication using user password. Should be set to `no` once ssh keys are configured.
- `UsePAM no` indicates SSH does not defer certain authentication and session management responsibilities to PAM. When enabled, this integration opens the door to a versatile and dynamic authentication process, as PAM is known for its modular approach to security. But we don't need it here.
- `X11Forwarding no` indicates we don't allow access to graphical Linux programs remotely through an SSH client.
- `AllowGroups ssh-users` indicates we only allow members of the group `ssh-users` to connect via ssh.
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

## Configure ssh keys

First, we need to create the public and private key on the machine from which you connect to the server. This can be done using the following:

```sh
ssh-keygen -t ed25519 -a 777
```

Where:
- `-t ed25519` specifies that we want to use the Ed25519 algorithm. Ed25519 is a high-performance, secure digital signature algorithm (EdDSA) based on the Twisted Edwards curve, specifically designed for speed, efficiency, and security. It offers high-level security (128 bits) with fast signing, key generation, and small 64-byte signatures, making it a modern standard for SSH, blockchains, and general cryptographic signing.
- `-a 777` specifies the number of KDF (key derivation function, currently bcrypt_pbkdf). Higher numbers result in slower passphrase verification and increased resistance to brute-force password cracking (should the keys be stolen). The default is 16 rounds.

The ssh key files we be created as follows:

```sh
# Public key
~/.ssh/id_ed25519.pub
# Private key
~/.ssh/id_ed25519
```

We now need to register the newly created public key on our server. This can be done using:

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub [remote-user]@[remote-host]
```

Where:
- `-i ~/.ssh/id_ed25519.pub` indicates the location of the public key to register.
- `[remote-user]@[remote-host]` needs to be adjusted so that `[remote-user]` indicates your username on the remote host, and `[remote-host]` indicates the IP address or the DNS name of your remote host.

If all went well, you can now authenticate using your ssh keys to your server via ssh. Running the following command should not prompt you for a password anymore.

```sh
ssh [remote-user]@[remote-host]
```

## Disable password authentication

Since you successfully authenticated to your server using ssh keys, let's disable password authentication. For this, we need to edit the custom `sshd` configuration file we created before:

```sh
sudo nano /etc/ssh/sshd_config.d/custom.conf
```

And adjust the following configuration option:

```sh
PasswordAuthentication no
```

Apply the changes using the following command:

```sh
sudo systemctl restart ssh.service
```
