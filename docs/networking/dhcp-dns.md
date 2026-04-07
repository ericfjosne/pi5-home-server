---
title: Configure DHCP & DNS servers
toc: true
---

We want simple no brainer DHCP & DNS services and configurations. `dnsmasq` combines both and its configuration is quite straightforward, making it our choice for this build.

## Install dnsmasq

To install `dnsmasq`, execute the following command:

```sh
sudo apt update
sudo apt install dnsmasq
```

## Create local network configuration

Let's create a configuration for a local domain `home.lan`

```sh
sudo nano /etc/dnsmasq.d/home.lan.conf
```

Add the following configuration

```
# Listen on this interface
interface=br0
domain-needed
bogus-priv

# Define local domain
domain=home.lan

# DHCP range: 10.0.0.20-10.0.0.200, 12-hour lease
dhcp-range=10.0.0.20,10.0.0.200,12h

# Gateway (router) IP
dhcp-option=3,10.0.0.1

# DNS Servers for clients
dhcp-option=6,10.0.0.1

# DNS servers
server=8.8.8.8
server=8.8.4.4
```

## Local network configuration description

For those who want to understand this configuration, here is some additional information.

From the `dnsmasq` man pages:
- `domain-needed`: Tells dnsmasq to never forward A or AAAA queries for plain names, without dots or domain parts, to upstream nameservers. If the name is not known from /etc/hosts or DHCP then a "not found" answer is returned.
- `bogus-priv`: Bogus private reverse lookups. All reverse lookups for private IP ranges (ie 192.168.x.x, etc) which are not found in /etc/hosts or the DHCP leases file are answered with "no such domain" rather than being forwarded upstream. The set of prefixes affected is the list given in RFC6303, for IPv4 and IPv6. Enabling this also subtly alters DNSSEC validation for reverse lookups in the private ranges such that a non-secure DS record is accepted as proof that the range is not signed. This works around behaviour by the public DNS services which seem not to return validated proof-of-non-existence for DS records in these domains.

On the chosen values:
- `domain=home.lan`: The `.lan` root domain is recommended as it best identifies your local network, and doesn't conflict with any publicly available root domains. `home.lan` is arbitrarily chosen. Feel free to change it to anything you like.
- `dhcp-range`: We keep the IP address ranges 10.0.0.2-10.0.0.19 and 10.0.0.201-10.0.0.254 available, for any machine we would want to configure with a static IP address on our local network.
- `dhcp-option`: We want our server to be the primary DNS server for all machines located on our local network.
- `server`: The chosen servers are DNS resolver operated by Google, `8.8.8.8` being the primary and `8.8.4.4` the secondary. Feel free to use the DNS server address(es) from your own Internet Service Provider (ISP), or other public ones.

## Apply the configuration

Restart the service

```sh
sudo systemctl restart dnsmasq
```

Check service status by running

```sh
sudo systemctl status dnsmasq
```

It should output

```sh
● dnsmasq.service - dnsmasq - A lightweight DHCP and caching DNS server
     Loaded: loaded (/usr/lib/systemd/system/dnsmasq.service; enabled; preset: enabled)
     Active: active (running) since Wed 2026-03-25 21:38:29 CET; 46min ago
 Invocation: a6f7d155ff07499c9b48960abdfe2b1d
       Docs: man:dnsmasq(8)
    Process: 1403 ExecStartPre=/usr/share/dnsmasq/systemd-helper checkconfig (code=exited, status=0/SUCCESS)
    Process: 1412 ExecStart=/usr/share/dnsmasq/systemd-helper exec (code=exited, status=0/SUCCESS)
    Process: 1418 ExecStartPost=/usr/share/dnsmasq/systemd-helper start-resolvconf (code=exited, status=0/SUCCESS)
   Main PID: 1417 (dnsmasq)
      Tasks: 1 (limit: 19363)
        CPU: 221ms
     CGroup: /system.slice/dnsmasq.service
             └─1417 /usr/sbin/dnsmasq -x /run/dnsmasq/dnsmasq.pid -u dnsmasq -7 /etc/dnsmasq.d,.dpkg-dist,.dpkg-old,.dpkg-new --local-service --trust-anchor=.,20326,8,2,E06D44B80B8F1D39A95C0>

Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPREQUEST(br0) 10.0.0.95 [REDACTED_MAC_ADDRESS]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPACK(br0) 10.0.0.95 [REDACTED_MAC_ADDRESS] [REDACTED_NAME]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPREQUEST(br0) 10.0.0.67 [REDACTED_MAC_ADDRESS]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPACK(br0) 10.0.0.67 [REDACTED_MAC_ADDRESS] [REDACTED_NAME]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPREQUEST(br0) 10.0.0.67 [REDACTED_MAC_ADDRESS]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPACK(br0) 10.0.0.67 [REDACTED_MAC_ADDRESS] [REDACTED_NAME]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPREQUEST(br0) 10.0.0.95 [REDACTED_MAC_ADDRESS]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPACK(br0) 10.0.0.95 [REDACTED_MAC_ADDRESS] [REDACTED_NAME]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPREQUEST(br0) 10.0.0.126 [REDACTED_MAC_ADDRESS]
Mar 25 22:20:27 cortex dnsmasq-dhcp[1417]: DHCPACK(br0) 10.0.0.126 [REDACTED_MAC_ADDRESS] [REDACTED_NAME]
```
