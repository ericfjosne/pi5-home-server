---
title: Configure interfaces via NetworkManager
toc: true
---

## Clear existing connections

List currently active connections

```sh
sudo nmcli -p connection show
```

Delete them, based on UUID or name

```sh

sudo nmcli connection delete [UUID]
sudo nmcli connection delete netplan-eth0
```

Confirm the connection configuration was deleted

```sh
sudo nmcli -p connection show
```

## Set up the 2 wired connections (uplink & local)

### Uplink

Configure ip address on network interface `eth2` as auto (retrieved via DHCP)

```sh
sudo nmcli connection add type ethernet con-name eth2 ifname eth2 ipv4.method auto
```

Bring physical interface `eth2` up

```sh
sudo nmcli connection up eth2
```

### Local network

For this setup, we want to have the ability to run virtual machines on the server and have them exposed on the local network. Those virtual machines will need to share the same IP address range as all physical machines connected to the local network. To achieve this, we need to configure a bridge network interface `br0`, and add our physical interface `eth1` as bridge slave.

Create bridge interface `br0` and add the `eth1` interface to it as slave

```sh
sudo nmcli connection add type bridge con-name br0 ifname br0
sudo nmcli connection add type bridge-slave ifname eth1 master br0
```

Disable [Spanning Tree Protocol (STP)](https://en.wikipedia.org/wiki/Spanning_Tree_Protocol) support on the bridge, to avoid unnecessary packet noise from the interface, and configure ip address:

```sh
sudo nmcli connection modify br0 bridge.stp no
sudo nmcli connection modify br0 ipv4.addresses 10.0.0.1/24
sudo nmcli connection modify br0 ipv4.method manual
```

Bring physical interface `eth1` down (just in case)

```sh
sudo nmcli connection down eth1
```

Bring bridge interface `br0` up

```sh
sudo nmcli connection up br0
```

## Check connection status

Running the following command

```sh
nmcli dev status
```

Should give the following output

```sh
DEVICE  TYPE      STATE                   CONNECTION
eth2    ethernet  connected               eth2
br0     bridge    connected               br0
eth1    ethernet  connected               bridge-slave-eth1
lo      loopback  connected (externally)  lo
eth0    ethernet  unavailable             --
```

Running the following command

```sh
nmcli connection show
```

Should give the following output

```sh
NAME                         UUID             TYPE      DEVICE
eth2                         [REDACTED_UUID]  ethernet  eth2
br0                          [REDACTED_UUID]  bridge    br0
bridge-slave-eth1            [REDACTED_UUID]  ethernet  eth1
lo                           [REDACTED_UUID]  loopback  lo
eth1                         [REDACTED_UUID]  ethernet  --
```

Running the following command

```sh
ifconfig
```

Should give the following output

```sh
br0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.0.1  netmask 255.255.255.0  broadcast 10.0.0.255
        inet6 fe80::bb84:171d:6e1b:b673  prefixlen 64  scopeid 0x20<link>
        ether [REDACTED_MAC_ADDRESS]  txqueuelen 1000  (Ethernet)
        RX packets 80752  bytes 222033036 (211.7 MiB)
        RX errors 0  dropped 7  overruns 0  frame 0
        TX packets 95716  bytes 47250039 (45.0 MiB)
        TX errors 0  dropped 3 overruns 0  carrier 0  collisions 0

eth0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        ether [REDACTED_MAC_ADDRESS]  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 3 overruns 0  carrier 0  collisions 0
        device interrupt 116

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        ether [REDACTED_MAC_ADDRESS]  txqueuelen 1000  (Ethernet)
        RX packets 219559  bytes 232816206 (222.0 MiB)
        RX errors 0  dropped 68  overruns 0  frame 0
        TX packets 106436  bytes 47250765 (45.0 MiB)
        TX errors 0  dropped 3 overruns 0  carrier 0  collisions 0

eth2: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet [REDACTED_PUBLIC_ADDRESS]  netmask 255.255.255.0  broadcast [REDACTED_PUBLIC_BROADCAST]
        inet6 [REDACTED]  prefixlen 64  scopeid 0x0<global>
        inet6 [REDACTED]  prefixlen 64  scopeid 0x20<link>
        ether [REDACTED_MAC_ADDRESS]  txqueuelen 1000  (Ethernet)
        RX packets 128125  bytes 49302125 (47.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 200335  bytes 229495421 (218.8 MiB)
        TX errors 0  dropped 2 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 96  bytes 7969 (7.7 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 96  bytes 7969 (7.7 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
