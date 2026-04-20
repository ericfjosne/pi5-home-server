---
title: Back up storage data
toc: true
---

The data stored on the external master disk needs to be replicated to 2 separate backup disks.

## Requirements

For our storage data backup, all of our disks (master data, backups) need to have been prepared, and we need to be able to optionally send emails, for end of backup notification purpose. This means:

- The [external disks must be configured and encrypted](../disks/external-encryption.html).
- They must be [configured to auto mount when accessed](../disks/external-auto-mount.html).
- The [SMTP relay should be configured](../services/smtp-relay.html).

## Install screen

Because our build runs headless, we want to be able to take the backup in the background, detach the process and leave it to run unattended. We will make use of `screen` to do this.

`screen` is a terminal multiplexer that allows users to manage multiple, separate terminal sessions within a single window or SSH session. It enables detaching from a session (keeping processes running) and reattaching later, preventing data loss from network issues.

It can be installed by executing the following:

```sh
sudo apt update
sudo apt install screen
```

## Scripts location

We will store all of our scripts and related configuration files under the location `/opt/backup`, which we need to create if it doesn't exist yet.

```sh
sudo mkdir /opt/backup
```

## Create backup script

Let's create our configuration backup script and make it executable:

```sh
sudo nano /opt/backup/data.sh
sudo chmod +x /opt/backup/data.sh
```

The script should contain the following:

```sh
#!/bin/bash

# Usage: ./data.sh --backup-disk=1 --dry-run

# Mail recipient for end of backup notification. Comment out if you don't want an email to be send.
MAIL_RECIPIENT="john.doe@email.com"

# Parse arguments
for i in "$@"; do
  case $i in
    --backup-disk=*)
      DISK="${i#*=}"
      shift # past argument=value
      ;;
    --dry-run)
      DRY_RUN="--dry-run"
      shift # past argument with no value
      ;;
    -*|--*)
      echo "Unknown argument $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

# Check target backup disk identifier was set
if [[ ! -v DISK ]]; then 
  echo "You must specify the target backup disk id using --backup-disk=[ID].";
  exit 0
fi

BACKUP_CRYPTDISK_NAME="data-backup-$DISK"
BACKUP_LOCATION="/mnt/data/backup-$DISK"
BACKUP_DEVICE="/dev/mapper/data-backup-$DISK"

if [ ! -d "$BACKUP_LOCATION" ]; then
  echo "Target mount directory $BACKUP_LOCATION for disk $DISK does not exist. Exiting."
  exit 0
fi

DATETIME_START=`date`

echo "Starting backup to $BACKUP_CRYPTDISK_NAME at $DATETIME_START"

# Start the backup cryptdisk process
echo "Starting cryptdisk process on $BACKUP_CRYPTDISK_NAME"
cryptdisks_start $BACKUP_CRYPTDISK_NAME

echo "Attempting to mount backup location $BACKUP_LOCATION"
mount $BACKUP_LOCATION

# Validate the disk is mounted
if ! grep -qs "$BACKUP_DEVICE" /proc/mounts; then
  echo "Backup disk is not mounted. Is it plugged in? Exiting."
  exit 0
else
  echo "Backup disk is mounted on $BACKUP_LOCATION."
fi


# Perform the backup
echo "Performing backup via rsync"
rsync -azv $DRY_RUN --delete --exclude 'lost+found' /mnt/data/master/ $BACKUP_LOCATION/

echo "Backup completed!"

echo "Unmounting backup disk from $BACKUP_LOCATION"
umount $BACKUP_LOCATION

# Stop the backup cryptdisk process ... until it is effectively stopped
echo " Stopping cryptdisks process on $BACKUP_CRYPTDISK_NAME"
while grep -qs "$BACKUP_DEVICE" /proc/mounts; do
  cryptdisks_stop $BACKUP_CRYPTDISK_NAME
  sleep 5s
done

DATETIME_END=`date`
echo "Backup process ended at $DATETIME_END. You can now unplug the backup disk $BACKUP_CRYPTDISK_NAME safely."

# If an recipient email address was set, send an end of backup notification to it.
if [[ ! -v MAIL_RECIPIENT ]]; then
  HOSTNAME=`hostname`
  MAIL_BODY="Backup to $BACKUP_CRYPTDISK_NAME completed!\n\nStarted on $DATETIME_START\nFinished on $DATETIME_END\n\nYou can now unplug the USB disk from ${HOSTNAME^}."
  MAIL_SUBJECT="Backup of data on ${HOSTNAME^} is completed!"
  printf $MAIL_BODY | mail -s $MAIL_SUBJECT $MAIL_RECIPIENT
fi

exit 0
```

## Execute the script

We recommend running the data backup script under a `screen` session, in order to ensure the command will continue running, even when we experience a network disconnection.

Let's start the screen session by executing the following:

```sh
screen
```

We can now execute our script. It takes 2 different arguments:
- `--backup-disk=1` (required), where the value is the identifier of the backup disk. We have only `1` & `2` in our setup. 
- `--dry-run` (optional) will run the rsync backup by simulating a file synchronization or backup process without actually copying, deleting, or modifying any files. Make use of it when testing the script.

Here is an example command to use in order to backup our `master` data to the `data-backup-1` disk:

```sh
cd /opt/backup
sudo ./data.sh --backup-disk=1
```

Once the command is launched, we can detach from the `screen` session using the following keys combination:

- Keep CTRL pressed down
- press A
- press D

The rsync process should still be running in the background. You can reattach to the existing detached session by executing:

```sh
screen -r
```
CTRL + A, followed by D