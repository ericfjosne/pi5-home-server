---
title: Set up encryption on external USB disks
toc: true
---

We want to initialize our external USB disks for encryptions. 

## Prepare the partition

Let's assume the disk you connected appears as `/dev/sda`. Let's repartition it.

```sh
sudo fdisk /dev/sda
```

Start by printing the current partition layout, by typing the `p` print command in the fdisk prompt:

```sh
Command (m for help): p

Disk /dev/sda: 4.55 TiB, 5000947302400 bytes, 9767475200 sectors
Disk model: Elements 2620
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: [REDACTED_UUID]

Device     Start        End    Sectors  Size Type
/dev/sda1   2048 9767475166 9767473119  4.5T Linux filesystem
```

In this case, the disk is already partition as we want. But assuming it is not the case, we need to delete all existing partitions first, using the `d` delete command:

```sh
Command (m for help): d
Selected partition 1
Partition 1 has been deleted.
```

Execute the delete partition command multiple times if required, until all is deleted.

We now need to create a new partition, using the `n` new command:

```sh
Command (m for help): n
Partition number (1-128, default 1):
First sector (34-9767475166, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-9767475166, default 9767473151):

Created a new partition 1 of type 'Linux filesystem' and of size 4.5 TiB.
Partition #1 contains a crypto_LUKS signature.

Do you want to remove the signature? [Y]es/[N]o: Y

The signature will be removed by a write command.
```

Depending on what your disk currently contains, you may see a different output. 

Let's now confirm the new partition schema before writing it to the disk, by executing the `p` print command again:

```
Command (m for help): p
Disk /dev/sda: 4.55 TiB, 5000947302400 bytes, 9767475200 sectors
Disk model: Elements 2620
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: [REDACTED_UUID]

Device     Start        End    Sectors  Size Type
/dev/sda1   2048 9767473151 9767471104  4.5T Linux filesystem

Filesystem/RAID signature on partition 1 will be wiped.
```

If all is as expected, we now need to write the changes to disk, using the `w` write command.

> ‼️ This operation will wipe all existing data from this drive. Do make sure you have a copy of what you need before executing it. In case of doubt, abort all changes by executing the `q` command to quit. No change will be applied when quitting without having executed the `w` write command.

Once the changes are written to the disk, we need to quit `fdisk` by executing the `q` quit command.

## Initialize partition encryption

To initialize the encryption, let's start by formatting it as a LUKS (Linux Unified Key Setup) partition. Execute the following command:

```sh
sudo cryptsetup luksFormat /dev/sda1
```

You will be prompted for a LUKS passphrase, which will be used as primary password to protect the data on the disk. Make sure to use a very strong password, which you will remember.

## Open the LUKS partition

We now need to open the LUKS partition, which actually means creating a mapping between the physical encrypted partition and a virtual block device, through which our actual file system will be made accessible.

Let's open `/dev/sda1` and map it to the virtual block device `storage`:

```sh
sudo cryptsetup open /dev/sda1 storage
```

This creates the virtual block device under `/dev/mapper/storage`.

## Create the file system on the encrypted partition

Let's now format this disk as `ext4` (or whichever file system type you wish to use).

```sh
sudo mkfs.ext4 /dev/mapper/storage
```

## Validate all can be accessed

Let's now try and mount this new file system, under `/mnt/storage`:

```sh
sudo mkdir /mnt/storage
sudo mount /dev/mapper/storage
sudo ls /mnt/storage
```

If all went well, the last `ls` command should list the following 3 entries only (since the partition was freshly formatted as `ext4`):

```sh
total 52K
drwxr-xr-x 10 root root  4.0K Apr  3  2022 .
drwxr-xr-x  5 root root  4.0K Apr  3 18:13 ..
drwx------  2 root root   16K Apr  3  2021 lost+found
```

At this point, we confirmed that we can access the content of the encrypted partition on our external disk. Let's unmount it and close the virtual block device by executing the following:

```sh
sudo umount /mnt/storage
sudo cryptsetup close storage
```
