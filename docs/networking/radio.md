---
title: Disable Wifi & Bluetooth
---

We don't want any radio enabled during operations.

To achieve this, edit the raspberry pi boot config:

```sh
sudo nano /boot/firmware/config.txt
```

Add the following lines (Raspberry pi 5 specific) under the `[all]` section:

```properties
dtoverlay=disable-wifi-pi5
dtoverlay=disable-bt-pi5
```
