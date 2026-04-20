---
title: Back up build configuration
toc: true
---

We would like to take a daily snapshot of all our build configuration files, and keep a backup of each of them.

## Requirements

For our backup configuration, all of our disks (master data, backups) need to have been prepared. This means:

- The [external disks must be configured and encrypted](../disks/external-encryption.html).
- They must be [configured to auto mount when accessed](../disks/external-auto-mount.html).

## Scripts location

We will store all of our scripts and related configuration files under the location `/opt/backup`, which we need to create if it doesn't exist yet.

```sh
sudo mkdir /opt/backup
```

## Prepare backup target location

We will store these snapshots on our external master data disk. Let's create the target location, if it doesn't already exist:

```sh
sudo mkdir -p /mnt/data/master/backup/configuration
```

## List files & directories to include

Let's first list all the files and directories we would like to include in this backup, in a new dedicated file:

```sh
sudo nano /etc/backup/configuration.list
```

If you followed the entirety of this guide, the files that should be included are as follows:

```sh
/boot/firmware/config.txt
/etc/crontab
/etc/crypttab
/etc/dnsmasq.d/home.lan.conf
/etc/fstab
/etc/group
/etc/hosts
/etc/luks-keys/data-backup-1
/etc/luks-keys/data-backup-2
/etc/luks-keys/data-master
/etc/luks-keys/timemachine
/etc/passwd
/etc/postfix/main.cf
/etc/postfix/sasl_passwd
/etc/samba/smb.conf
/etc/ssh/sshd_config.d/custom.conf
/etc/ufw/after.rules
/opt/backup
```

## Create backup script

Let's create our configuration backup script and make it executable:

```sh
sudo nano /opt/backup/configuration.sh
sudo chmod +x /opt/backup/configuration.sh
```

The script should contain the following:

```sh
#!/bin/sh
MONTH=`date +%Y-%m`
DATE=`date +%Y-%m-%d`
mkdir -p /mnt/data/master/backup/configuration/$MONTH > /dev/null
tar -zcf /mnt/data/master/backup/configuration/$MONTH/$DATE.tar.gz --files-from=/opt/backup/configuration.list
```

The script does the following:
- Attempts to create the month directory, with name `YYYY-mm` (ex: `2026-04`), if it doesn't alredy exist
- Creates a compressed tar archive with name `YYYY-mm-dd` (ex: `2026-04-18`), containing all the files and directories as listed in `/opt/backup/configuration.list`.

We can check this works as expected by simply executing the backup script:

```sh
sudo /opt/backup/configuration.sh
```

Which should create today's backup at the appropriate location, as explained below.

## Backup target location organization

The `/mnt/data/master/backup/configuration` will contain one directory per year/month:

```sh
ls /mnt/data/master/backup/configuration
2021-03  2021-06  2021-09  2021-12  2022-03  2022-06  2022-09  2022-12  2023-03  2023-06  2023-09  2023-12  2024-03  2024-06  2024-09  2024-12  2025-03  2025-06  2025-09  2025-12  2026-03
2021-04  2021-07  2021-10  2022-01  2022-04  2022-07  2022-10  2023-01  2023-04  2023-07  2023-10  2024-01  2024-04  2024-07  2024-10  2025-01  2025-04  2025-07  2025-10  2026-01  2026-04
2021-05  2021-08  2021-11  2022-02  2022-05  2022-08  2022-11  2023-02  2023-05  2023-08  2023-11  2024-02  2024-05  2024-08  2024-11  2025-02  2025-05  2025-08  2025-11  2026-02
```

Which in turn will contains all the backups taken on that month:

```sh
ls /mnt/data/master/backup/configuration/2026-04
2026-04-14.tar.gz  2026-04-15.tar.gz  2026-04-16.tar.gz  2026-04-17.tar.gz  2026-04-18.tar.gz  2026-04-19.tar.gz
```

## Automate script execution

We now need to make this script runs automatically. For this, we edit the `/etc/crontab` file:

```sh
sudo nano /etc/crontab
```

And add the following line at the end of it:

```sh
00 0    * * *   root    /opt/backup/configuration.sh 1> /dev/null 2> /dev/null
```

Which indicates that the script must run on a daily basis at midnight.
