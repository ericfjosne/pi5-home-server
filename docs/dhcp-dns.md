# DHCP & DNS configuration

Install dnsmasq

```sh
sudo apt install dnsmasq
```

Create configuration for home network

```sh
sudo nano /etc/dnsmasq.d/home.lan.conf
```

Add content
```
# Listen on this interface
interface=eth1
domain-needed
bogus-priv

# Define local domain
domain=home.lan

# DHCP range: 10.0.0.20-10.0.0.200, 12-hour lease
dhcp-range=10.0.0.20,10.0.0.200,12h

# Gateway (router) IP
dhcp-option=3,10.0.0.1

# DNS Servers for clients
dhcp-option=6,10.0.0.1,8.8.8.8

# Upstream DNS servers
server=8.8.8.8
server=8.8.4.4
```


Restart the service

```sh
sudo systemctl restart dnsmasq
```

Check service status

```sh
sudo systemctl status dnsmasq
```