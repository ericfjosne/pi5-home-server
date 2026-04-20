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