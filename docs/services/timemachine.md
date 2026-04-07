---
title: Time Machine backup target
toc: true
---

If you own one or more Apple computers, you might be looking for a way to seamlessly automate your remote [Time Machine backups](https://support.apple.com/en-us/104984). Having a file share on your server, defined as Time Machine backup target, is the way to go.

## Requirements

Samba server needs to be configured. [Read more on this over here](./file-sharing.md).

## Manage user accesses & permissions

Instead of managing access permission on a per-user basis, we will manage them using a Unix group called `timemachine`.

Let's create the group and add our current user to it.

```sh
sudo addgroup timemachine
sudo adduser $USER timemachine
```

## Backups location

Our backups will be stored on the external disk mounted at `/mnt/timemachine`. The Time Machine backup target location will be under the `/mnt/timemachine/backups` directory. Let's create it and adjust its permissions accordingly.

```sh
sudo mkdir /mnt/timemachine/backups 
sudo chown root:timemachine /mnt/timemachine/backups
sudo chmod 770 /mnt/timemachine/backups
```

## Configure Samba

We will need to tweak some parts of the related `/etc/samba/smb.conf` configuration file. 

Let's edit it using the following command:

```sh
sudo nano /etc/samba/smb.conf
```

> ⚠️ The configuration as described below applied to a build using Debian 10 (Buster). It has been reused for this Debian 13 (Trixie) based build, and worked immediately. It might however consist of some deprecated configuration options.

### Misc

Let's add the following configuration options at the end of the Misc section:

```sh
# Time Machine
fruit:model = Macmini
fruit:advertise_fullsync = true
fruit:aapl = yes
```

### Share definition

For our setup, we will create a `timemachine` share, pointing to the `/mnt/timemachine/backups` location we created above. Let's add its definitions at the end of our `/etc/samba/smb.conf` file:

```sh
[timemachine]
comment = Time Machine
path = /mnt/timemachine/backups
valid users = @timemachine
browseable = yes
writable = yes
create mask = 0600
directory mask = 0700
spotlight = yes
durable handles = yes
kernel oplocks = no
kernel share modes = no
posix locking = no
vfs objects = catia fruit streams_xattr
ea support = yes
read only = No
inherit acls = yes
fruit:time machine = yes
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
## References

- [Samba `vfs-fruit` documentation](https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html)