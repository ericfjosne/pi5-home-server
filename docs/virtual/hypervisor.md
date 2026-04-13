---
title: Configure as a hypervisor
toc: true
---

We want to be able to run a hypervisor (virtual machine monitor), to allow guest operating systems to run on our machine. For this, we will install the standard open-source Linux virtualization stack: KVM, QEMU, and libvirt.

- KVM (Kernel-based Virtual Machine) acts as the hypervisor, enabling hardware acceleration.
- QEMU emulates hardware and runs the VM process.
- Libvirt manages and orchestrates these VMs using a unified API.

## What is KVM?

KVM (Kernel-based Virtual Machine) is an open-source technology that turns the Linux kernel into a Type-1 (bare-metal) hypervisor. It enables hosting multiple, isolated virtual machines (VMs) running Linux or Windows on x86 hardware with virtualization extensions (Intel VT or AMD-V), and other supported architectures.

## What is QEMU

QEMU (Quick Emulator) is a free, open-source machine emulator and virtualizer. It runs operating systems (like Windows or Linux) and software designed for one hardware architecture (e.g., ARM) on another (e.g., x86). It provides high-performance, near-native speeds through dynamic translation and KVM acceleration.

## What is libvirt?

Libvirt is an open-source, vendor-neutral software toolkit used to manage virtualization technologies, acting as an abstraction layer between users and hypervisors like KVM, QEMU, Xen, and VMware ESXi. It provides a consistent API, daemon (`libvirtd`), and command-line tool (`virsh`) to create, configure, and monitor virtual machines (VMs), networks, and storage.

## Requirements

### Confirm KVM acceleration can be used

We can confirm that KVM is supported by confirming that `/dev/kvm` exists.

```sh
ls -alh /dev/kvm
```

Should output:

```sh
crw-rw---- 1 root kvm 10, 232 Apr  3 14:31 /dev/kvm
```

## Perform the installation

To install our virtualization stack, execute the following command:

```sh
sudo apt update
sudo apt install qemu-system-arm libvirt-daemon-system libvirt-clients virt-install
```

Which will install the following packages:

- `qemu-system-arm`: QEMU full system emulation binaries
- `libvirt-damon-system`:  System daemon for managing virtualization
- `libvirt-clients`: Command-line tools like virsh for virtual machines management
- `virt-install`: Command-line tools to create and edit virtual machines

## Post-installation steps

### Run commands without sudo

By default, you must run all commands related to our virtualization stack using `sudo`. To prevent this, you can add your current user to the following groups:

```sh
sudo adduser $USER kvm
sudo adduser $USER libvirt
sudo adduser $USER libvirt-qemu
```
