---
title: Ad-blocker service
toc: true
---

For this build, we will make use of [Pi-Hole](https://pi-hole.net).

## What is Pihole?

Pi-hole is a network-wide ad-blocking application that acts as a DNS sinkhole, protecting all connected devices (including smart TVs and mobile apps) from ads and trackers, without client-side software.

## Requirements

- Your machine must be configured as a [Container host](../virtual/container-host.html).
- [Dnsmasq](../networking/dhcp-dns.html) must be installed and configured.

## Configuration

We will store our configuration under `/mnt/data/master/services/pihole`. Let's start by creating the directories we need, if they don't exist yet:

```sh
sudo mkdir -p /mnt/data/master/services/pihole
sudo mkdir -p /mnt/data/master/services/pihole/etc-pihole
```

Let's create our run script:

```sh
sudo nano /mnt/data/master/services/pihole/run.sh
```

Add the following content:

```sh
#!/bin/sh

PIHOLE_DIR="/mnt/data/master/services/pihole"
TIMEZONE=`timedatectl show | grep "Timezone" | sed 's/^[^=]*=//'`

echo "Using Timezone: $TIMEZONE"

docker stop pihole
docker rm pihole
docker run --detach \
        --name pihole \
        --restart unless-stopped \
        --publish 53080:80 \
        --publish 53053:53/tcp \
        --publish 53053:53/udp \
        -e TZ=$TIMEZONE \
        --volume $PIHOLE_DIR/etc-pihole:/etc/pihole \
        pihole/pihole:latest
```

docker run --name pihole -p 53:53/tcp -p 53:53/udp -p 80:80/tcp -p 443:443/tcp -e TZ=Europe/London -e FTLCONF_webserver_api_password="correct horse battery staple" -e FTLCONF_dns_listeningMode=all -v ./etc-pihole:/etc/pihole -v ./etc-dnsmasq.d:/etc/dnsmasq.d --cap-add NET_ADMIN --restart unless-stopped pihole/pihole:latest


Some notes about this configuration (in regards to the [official documentation](https://docs.pi-hole.net/docker/)):
- We run the container as a background daemon, hence the `--detach` argument.
- We retrieve the timezone automatically, using the `timedatectl` command.
- We skip mounting the `/etc/dnsmasq.d` volume because we won't make use of this Pi-Hole instance as a DHCP server. It would be empty anyway.
- We do not expose the container network port `443` (https), because the instance makes use of a self-signed certificate for a hostname which is random. We won't be able to access it anyway.
- We do not define the environment variable `FTLCONF_webserver_api_password` with a password value. This would expose it and therefore isn't recommended. We will define the password later on.
- We do not define the environment variable `FTLCONF_dns_listeningMode=all` as the Pi-Hole instance will only interact with our host, through the internal docker network.

Let's make the run script executable:

```sh
sudo chmod +x /mnt/data/master/services/pihole/run.sh
```

Let's now start the service!

```sh
sudo /mnt/data/master/services/pihole/run.sh
```

We now need to set a password to access the Pi-Hole dashboard. We can do this by executing the `pihole setpassword` inside the running container:

```sh
sudo docker exec -it pihole pihole setpassword
```

Assuming you are using the same IP addresses for your network as the ones [referenced in this guide](../networking/interfaces.html), you can now log into your Pi-Hole dashboard using your newly defined password, at the following location: [http://10.0.0.1:53080/admin/](http://10.0.0.1:53080/admin/)

## Reset Pi-Hole admin password

In case you forgot the password to access the admin dashboard, you can simply reset it using the same command as described above:

```sh
sudo docker exec -it pihole pihole setpassword
```

## Configure Dnsmasq

Assuming you used the same configuration as [referenced in this guide](../networking/dhcp-dns.html), we need to edit the existing `home.lan.conf` configuration file:

```sh
sudo nano /etc/dnsmasq.d/home.lan.conf
```

It should contain the following lines at the end:

```sh
# Upstream DNS servers
server=8.8.8.8
server=8.8.4.4
```

Let's replace them with the following, to start making use of our dockerized Pi-Hole ad-blocker instance, available from the `dnsmasq` service instance at the localhost IP address `127.0.0.1`, on port `53053`. We also add `no-resolv` to ensure that no other upstream DNS server is used.

```sh
# Upstream DNS servers
server=127.0.0.1#53053
no-resolv
```

Let's apply the new configuration:

```sh
sudo systemctl restart dnsmasq.service
```

Let's then check that the dnsmasq service restarted successfully:

```sh
sudo systemctl status dnsmasq.service
```

Some log entries should also be displayed after executing this command, most notably a single one stating `using nameserver`, confirming the usage of `127.0.0.1#53053`

```sh
Apr 08 22:33:57 cortex systemd[1]: Starting dnsmasq.service - dnsmasq - A lightweight DHCP and caching DNS server...
Apr 08 22:33:57 cortex dnsmasq[31570]: started, version 2.91 cachesize 150
Apr 08 22:33:57 cortex dnsmasq[31570]: compile time options: IPv6 GNU-getopt DBus no-UBus i18n IDN2 DHCP DHCPv6 no-Lua TFTP conntrack ipset nftset auth DNSSEC loop-detect inotify dumpfile
Apr 08 22:33:57 cortex dnsmasq-dhcp[31570]: DHCP, IP range 10.0.0.20 -- 10.0.0.200, lease time 12h
Apr 08 22:33:57 cortex dnsmasq[31570]: using nameserver 127.0.0.1#53053
Apr 08 22:33:57 cortex dnsmasq[31570]: read /etc/hosts - 8 names
Apr 08 22:33:57 cortex systemd[1]: Started dnsmasq.service - dnsmasq - A lightweight DHCP and caching DNS server.
```

With this last step, browsing the web from your local network will prove to be a much more pleasant experience. You should also start observing incoming activity (queries) on [your Pi-Hole admin dashboard](http://10.0.0.1:53080/admin/).

## References

- [Pi-Hole documentation](https://docs.pi-hole.net/docker/)
