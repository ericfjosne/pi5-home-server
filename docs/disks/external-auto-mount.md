---
id: external-disks-auto-mount
title: Auto unlock and auto mount external disks
sidebar_label: External disks automount
---

# Auto unlock and auto mount external disks

## Install systemd-cryptsetup

Auto unlock and auto mount can be achieved using the default Linux system and service manager `systemd`, but requires the following missing package to be installed:

```sh
sudo apt install systemd-cryptsetup
```

To make sure all required changes are applied, it is recommended to reboot the system:

```sh
sudo reboot
```

## Add a file-based key to the existing LUKS volume

We want to unlock the disks automatically when they are accessed by the system. For this to be possible, we need the password used to protect the disk to be stored locally. Instead of storing the passphrase we used when preparing the disks, we will add additional file-based keys to unlock the encrypted devices on our root partition, under the `/etc/luks-keys` directory.

Let's start by creating the directory:

```sh
sudo mkdir /etc/luks-keys
```

Let's now generate as many key files as we need for our setup, using the following command:

```sh
sudo dd if=/dev/random bs=32 count=1 of=/etc/luks-keys/keyfile1
```

We need to ensure the key file is hidden from and unreadable by all untrusted parties. Let's make sure ownership and permissions are as restrictive as possible, meaning readable only by the root user:

```sh
sudo chown root:root /etc/luks-keys/keyfile1
sudo chmod 400 /etc/luks-keys/keyfile1
```

We now need to register this key file to the encrypted device. Assuming this device is `/dev/sda1`, the command would be:

```sh
sudo cryptsetup luksAddKey /dev/sda1 /etc/luks-keys/keyfile1
```

## Validate that all can be accessed

Let's now verify that we can open the encrypted device using this key file, by executing the following:

```sh
sudo cryptsetup open /dev/sda1 test --key-file /etc/luks-keys/keyfile1
```

Once completed, we can confirm that the `test` mapped virtual block devices was successfully opened, using the following command:

```sh
sudo dmsetup ls
```

If our `test` mapped entry is present in the output, all is good.

Let's close the `test` virtual block device before moving on:

```sh
sudo cryptsetup close test
```

## Configure crypttab and fstab

We now need to configure our encrypted disk in 2 separate configuration files:
- `/etc/crypttab`, where we describe encrypted block devices used by our system.
- `/etc/fstab`: where we describe the various file systems used by our system.

### crypttab

When describing external devices in `/etc/crypttab`, it is best to make use of their Universally Unique Identifier (UUID), which identifies them uniquely and consistently. Essentially, the device which is now referred to as `/dev/sda1` could very well be `/dev/sdb1` or `/dev/sdc1` later on, depending on the boot context, USB port to which the disk is connected or the order within which disks are connected.

Let's retrieve the UUID associated with our `sda1` device, using the following command:

```sh
blkid | grep sda1
```

This command should output the following line:

```sh 
/dev/sda1: UUID="[SDA1_UUID]" TYPE="crypto_LUKS" PARTUUID="[REDACTED_PARTUUID]"
```

Where we find the UUID associated with `sda1` under the `[SDA1_UUID]` value.

Let's now edit the `crypttab` file using:

```sh
sudo nano /etc/crypttab
```

and add the following line:

```sh
data-master	UUID=[SDA1_UUID]	/etc/luks-keys/data-master	luks,nofail,noauto
```

Where:

- `data-master` is the arbitrary name we give to the virtual block device
- `UUID=[SDA1_UUID]` uniquely and consistently identifies the encrypted partition
- `/etc/luks-keys/data-master` indicates the location where the key file to unlock the encrypted partition exists. By convention, we decided to give the same arbitrary name to the virtual block device and the key file, but they can be different.
- `luks,nofail,noauto` is the list of comma-separated options:
 - `luks` indicates this is a `luks` encrypted partition
 - `nofail` indicates that this disk is not required at boot time. We want this because it is an external disk that might not always be connected. Its absence shouldn't result in a system boot failure.
 - `noauto` indicates that this disk will not be automatically unlocked at boot. We want this because we should only unlock it when we need to access it.

### fstab

Let's now edit the `fstab` file using:

```sh
sudo nano /etc/fstab
```

and add the following line:

```sh
# USB disks
/dev/mapper/data-master	/mnt/data/master	ext4	noauto,nofail,x-systemd.automount,x-systemd.device-timeout=10s,x-systemd.idle-timeout=5m
```

Where:

- `/dev/mapper/data-master` points to the virtual block device
- `/mnt/data/master` indicates the target mount location for the unlocked device
- `ext4` indicates the file system type
- the last column is the list of comma-separated options, where:
 - `noauto` prevents this mount location to be mounted at boot time
 - `nofail` prevents errors from occurring when the device does not exist (e.g. when the external disk is not connected to the system)
 - `x-systemd.automount` configures the target mount location as an automount unit point, controlled and supervised by systemd. This is used to implement on-demand mounting, as well as parallelized mounting of file systems.
 - `x-systemd.device-timeout=10s` indicates that we will wait up to 10 seconds for the device to respond, and fail the auto mount operation after that.
 - `x-systemd.idle-timeout=5m` configures the idle timeout for the automounted unit to 5 minutes.

## Our setup

In our setup, we make use of 4 external USB disks:
- `data-master`: contains all of our master data.
- `data-backup-1`: a complete backup of what is found in `data-master` (rotated with `data-backup-2`).
- `data-backup-2`: a complete backup of what is found in `data-master` (rotated with `data-backup-1`).
- `timemachine`: disk containing remote [macOS Time Machine backups](https://support.apple.com/en-us/104984) for Apple devices.


For this use case, we added the following lines to the `/etc/crypttab` file:
```sh
# External USB disks
data-master UUID=[REDACTED_UUID] /etc/luks-keys/data-master luks,nofail,noauto
data-backup-1 UUID=[REDACTED_UUID] /etc/luks-keys/data-backup-1 luks,nofail,noauto
data-backup-2 UUID=[REDACTED_UUID] /etc/luks-keys/data-backup-2 luks,nofail,noauto
timemachine UUID=[REDACTED_UUID] /etc/luks-keys/timemachine luks,nofail,noauto
```

And we added the following lines to the `/etc/fstab` file:

```sh
# External USB disks
/dev/mapper/data-master		/mnt/data/master	ext4	noauto,nofail,x-systemd.automount,x-systemd.device-timeout=10s,x-systemd.idle-timeout=5m
/dev/mapper/data-backup-1	/mnt/data/backup-1	ext4	noauto,nofail,x-systemd.automount,x-systemd.device-timeout=10s,x-systemd.idle-timeout=5m
/dev/mapper/data-backup-2	/mnt/data/backup-2	ext4	noauto,nofail,x-systemd.automount,x-systemd.device-timeout=10s,x-systemd.idle-timeout=5m
/dev/mapper/timemachine		/mnt/timemachine	ext4	noauto,nofail,x-systemd.automount,x-systemd.device-timeout=10s,x-systemd.idle-timeout=5m
```