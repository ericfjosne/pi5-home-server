# Disable Wifi & bluetooth

Edit the raspberry pi boot config

```sh
sudo nano /boot/firmware/config.txt
```

Add the following lines (Raspberry pi 5 specific) under the `[all]`

```properties
dtoverlay=disable-wifi-pi5
dtoverlay=disable-bt-pi5
```

# Configure via NetworkManager


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

# Set up the 2 wired connections (uplink & local)

## Uplink

```sh
sudo nmcli connection add type ethernet con-name eth2-uplink ifname eth2 ipv4.method auto
sudo nmcli connection up eth2-uplink
```

## Local network
```sh
sudo nmcli connection add type ethernet con-name eth1-local ifname eth1 ip4 10.0.0.1/24
sudo nmcli connection modify eth1-local ipv4.method manual
sudo nmcli connection up eth1-local
```


## Check connection status

```sh
nmcli dev status
nmcli connection show
ifconfig
```
