---
title: Home Assistant
toc: true
---

## What is Home Assistant?

Home Assistant is a free, open-source smart home platform designed to centralize control of smart devices locally, prioritizing privacy and interoperability. It acts as a hub that connects thousands of devices from different brands, allowing for advanced automation and customization. Unlike solutions from Amazon, Google, or Apple, it runs on your local network, meaning your data stays in your home and devices can function without an internet connection.

## Requirements

For this build, we will run Home Assistant in a virtual machine (VM). In order for this to work, we need the following:

- Your machine must be configured as a [Hypervisor](../virtual/hypervisor.html).
- [Dnsmasq](../networking/dhcp-dns.html) must be installed and configured.

### Why a VM and not a container?

Running Home Assistant in a virtual machine provides more flexibility and is easier to maintain. The 2 following features are missing from a container runtime instance:

- Install [applications (add-ons)](https://www.home-assistant.io/apps). 
- Manage updates (system & apps) directly from the Home Assistant client application.

## Configuration

### Download qcow2 image

We must start by retrieving the proper Home Assistant `qcow2` image from the [Home Assistant release page](https://github.com/home-assistant/operating-system/releases/). 

Let's download the latest version using the following (`HAOS_VERSION` needs to be adjusted):

```sh
HAOS_VERSION=17.2
wget https://github.com/home-assistant/operating-system/releases/download/$HAOS_VERSION/haos_generic-aarch64-$HAOS_VERSION.qcow2.xz
xz -d -v haos_generic-aarch64-$HAOS_VERSION.qcow2.xz
sudo cp haos_generic-aarch64-$HAOS_VERSION.qcow2 /var/lib/libvirt/images/haos_generic-aarch64.qcow2
```

### Configure the VM

Let's create the virtual machine instance:

```sh
sudo virt-install \
	--name home-assistant \
	--description "Home Assistant OS" \
	--os-variant=generic \
	--vcpus=2 \
	--ram=4096 \
	--disk /var/lib/libvirt/images/haos_generic-aarch64.qcow2,bus=scsi \
	--controller type=scsi,model=virtio-scsi \
	--import \
	--network bridge=br0 \
	--graphics none \
	--noautoconsole \
	--boot uefi,firmware.feature0.name=enrolled-keys,firmware.feature0.enabled=no,firmware.feature1.name=secure-boot,firmware.feature1.enabled=no
```

Where:

- `--name home-assistant` is the arbitrary chosen name for our VM.
- `--os-variant=generic` means we use a generic configuration.
- `--vcpus=2` means we allocate 2 virtual CPUs to this VM.
- `--ram=4096`  means we allocate 4Gb of RAM to this VM. 
- `--disk /var/lib/libvirt/images/haos_generic-aarch64.qcow2,bus=scsi` means we make use of the disk image already present, using a scsi bus.
- `--controller type=scsi,model=virtio-scsi` specifies the controller type for the disk.
- `--import` means we will make use of the disk image as it exists when running the VM.
- `--network bridge=br0` means we connect the VM to our physical machine network bridge `br0`.
- `--graphics none` means the VM will run headless.
- `--noautoconsole` means we won't automatically try to connect to the guest console. Note: `virt-install` exits quickly when this option is specified. This is expected.
- The `--boot` argument is composed of several different information. `uefi` tells libvirt to use the default OVMF (Open Virtual Machine Firmware) and sets up necessary NVRAM. It typically implies secure boot, which is not compatible with our disk image. This is why we disable both the `enrolled-keys` and `secure-boot` firmware features, by setting them to `no`.

The command should immediately return after execution. 

### Verify VM is running

We can check that our new VM is running by executing the following:

```sh
virsh -c qemu:///system list --all
```

Which should return the complete list of configured VMs and their current state:

```sh
 Id   Name             State
--------------------------------
 1    home-assistant   running
```

### Retrieve the IP address of the VM

We now need to access the Home Assistant web interface. To achieve this, we need the IP address of the VM.

#### Directly

If you want to retrieve the IP address in a single command, here goes!

```sh
arp -a | grep "`sudo grep "mac address" /etc/libvirt/qemu/home-assistant.xml | cut -d"'" -f2`" | awk '{print $2}'  | tr -d '()'
```

#### Step by step

We now need to retrieve the IP address that was assigned to the VM via DHCP. Let's first check the physical address of the interface 

```sh
sudo grep "mac address" /etc/libvirt/qemu/home-assistant.xml
```

The output should look like this:

```sh
<mac address='52:54:00:cd:d1:36'/>
```

Where the mac address is `52:54:00:cd:d1:36`. You can retrieve the IP address associated with this physical address using the `arp` command:

```sh
arp -a | grep [MAC_ADDRESS]
```

Which should output a line like this:

```sh
? (10.0.0.148) at 52:54:00:cd:d1:36 [ether] on br0
```

Where `10.0.0.148` is the IP address of the Home Assistant OS virtual machine.

### Access Home Assistant web interface

With this, you can now open the Home Assistant OS welcome page, at the following location: [http://10.0.0.148:8123/](http://10.0.0.148:8123/), where you will be invited to either create your smart home or restore a backup.

## References

- Home Assistant homepage: [https://www.home-assistant.io/](https://www.home-assistant.io/)