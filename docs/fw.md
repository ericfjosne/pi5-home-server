# Enable ip forwarding at kernel level

```sh
sudo nano /etc/sysctl.d/98-rpi.conf
```
add the following line:

```
net.ipv4.ip_forward=1
```

# Install and configure ufw

```sh
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed
sudo ufw allow in on eth1
sudo ufw enable
```