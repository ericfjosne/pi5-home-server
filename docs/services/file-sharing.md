---
title: File sharing service
toc: true
---

For this build, we will make use of Samba. It is an open-source software suite that implements the SMB/CIFS networking protocols, enabling Unix-like systems to seamlessly share files and printers with Windows, macOS, and other Linux machines. 

While CIFS (Common Internet File System) is an older dialect of SMB, Samba now supports modern, faster, and more secure SMB2/3 protocols.

## Install Samba

To install `samba`, execute the following command:

```sh
sudo apt update
sudo apt install samba
```

## Manage user accesses & permissions

### On the file system

Access restrictions at the file system level are enforced using the regular Unix user/group, and regular Unix `rwx` permissions. These can be managed using the following commands:

- `chown` (change owner) dictates who owns a file. Specifically, `chown` controls what user and what group owns a given file or directory.
- `chmod `(change mode) dictates what the user/group that owns a file can do with it. It also dictates what all other users and groups can do with it. Specifically, `chmod` details read, write, and execute permissions on the Unix command line at 3 different levels: `user`, `group` and `all`.

Worded differently:

- Use `chmod` when you want to change what users can do with a file.
- Use `chown` when you want to change the owner of a file.

For the reminder,

- Unix users are listed and managed under `/etc/passwd`
- Unix groups are listed and managed under `/etc/group`
- Managing the Unix password for a given user is done with the command `passwd`

### On the shares

The default authentication method to access a Samba share is user/password based.

Samba makes use of the Unix users/groups when enforcing access restrictions to the file system, or on the shares. It however manages user authentication separately, using its own set of Samba users and associated credentials.

These are managed using the `smbpasswd` command. 

```sh
sudo smbpasswd -a [USERNAME] # to create the Samba user [USERNAME]
sudo smbpasswd [USERNAME] # to change the password of the existing Samba user `[USERNAME]`.
sudo smbpasswd -d [USERNAME] # to disable the existing Samba user `[USERNAME]`.
sudo smbpasswd -e [USERNAME] # to enable the existing Samba user `[USERNAME]`.
sudo smbpasswd -x [USERNAME] # to delete the existing Samba user `[USERNAME]`.
```

> ℹ️ Please note that the Samba user password can differ from the Unix one.

> ℹ️ Please also not that, for the sake of managing share user accesses, we need our Samba user to have a matching existing Unix user. But it is absolutely possible to create Unix users with no password or home directory, therefore only enabling access access to the shares of this host through the Samba managed credentials.

### Unix group for our setup

Instead of managing access permission on a per-user basis, we will manage them using a Unix group called `smb_users`.

Let's create the group and add our current user to it.

```sh
sudo addgroup smb_users
sudo adduser $USER smb_users
```

## Configure Samba

The whole service configuration is centralized in the `/etc/samba/smb.conf` file.

Let's edit it using the following command:

```sh
sudo nano /etc/samba/smb.conf
```

In this file, we find:
- Sections identifier, between square brackets. Example: `[global]`
- Descriptions of the different configuration options on lines starting with `#`
- Configuration options and their values, in the form of `config option = value`. If the line starts with `;`, it means that either the default value is used, or that this configuration option is inactive.

Let's make the following edits:

### Browsing / identification

Let's change the following properties:

- `workgroup`: Sets the NetBIOS group of machines that the server belongs to. We will set it to `HOME`.
- `server string`: Sets a descriptive string for the Samba server. We will set it to `%h`, which is an alias for the host name.

After edits, the relevant part of the configuration file should look like this:

```sh
# Change this to the workgroup/NT-domain name your Samba server will part of
   workgroup = HOME

# server string is the equivalent of the NT Description field
   server string = %h
```

### Networking

Let's restrict access to our shares to machines on our private local network only, by specifying the interfaces on which the service will listen.

- `interfaces`: Uncomment the configuration option, and set it to `10.0.0.0/24 127.0.0.1/8 br0 lo`.
- `bind interfaces only`: Uncomment the configuration option, and set it to `yes`. 

This will ensure we accept incoming connections from the host itself, and from machines located on our private local network.

After edits, the relevant part of the configuration file should look like this:

```sh
# The specific set of interfaces / networks to bind to
# This can be either the interface name or an IP address/netmask;
# interface names are normally preferred
   interfaces = 10.0.0.0/24 127.0.0.1/8 br0 lo

# Only bind to the named interfaces and/or networks; you must use the
# 'interfaces' option above to use this.
# It is recommended that you enable this feature if your Samba machine is
# not protected by a firewall or is a firewall itself.  However, this
# option cannot handle dynamic or non-broadcast interfaces correctly.
   bind interfaces only = yes
```

### Authentication

We don't need to make any change in this part of the file, as the default values are fitting for our setup.

It is however worth mentioning that the default `security = user` configuration option is used. This means that the authentication method to the Samba server will be user/password based.

### Share Definitions

Let's delete or comment out every single existing configuration entry under this section. We want to start clean.

For our setup, we will create the following master shares `files` and `home`, all located on the external disk mounted at `/mnt/master/data`:

- `files`: Contains general files to which all authenticated users should have access. 
- `home`: Contains personal files. The share will contain one folder per user. Access to a user folder is restricted to the related authenticated user only.

Let's now add the following share definitions to our `/etc/samba/smb.conf` file:

```sh
[files]
comment = General files
path = /mnt/data/master/files
valid users = @smb_users
writable = yes
browseable = yes
guest ok = no
create mask = 0660
directory mask = 0770
admin users =

[home]
comment = Personal files
valid users = @smb_users
path = /mnt/data/master/home
writable = yes
browseable = yes
guest ok = no
create mask = 0660
directory mask = 0770
admin users =
```

## Apply the new configuration

Let's apply the new configuration by executing the following command:

```sh
sudo systemctl restart smbd
```

We can now validate whether the Samba service is active and running as expected, using the following command:

```sh
sudo systemctl status smbd
```
