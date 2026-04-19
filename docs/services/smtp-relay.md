---
title: SMTP relay server
toc: true
---

For this build, we will make use of [Postfix](https://www.postfix.org/).

## What is Postfix?

Postfix is a free, open-source Mail Transfer Agent (MTA) designed to route and deliver email on Unix-like operating systems. It handles both sending outgoing mail and receiving incoming mail via SMTP

## Install Postfix

To install `postfix` and the necessary associated mail utils, execute the following command:

```sh
sudo apt install postfix mailutils
```

When prompted to select the mail server configuration type that best meets your need, select `No configuration`.

## Configure Postfix (relay through GMail)

For this configuration, we will configure Postfix as relay only. All outgoing emails will be sent out from a private Gmail address.

### Postfix configuration

Let's create the Postfix configuration file, by editing the following:

```sh
sudo nano /etc/postfix/main.cf
```

And paste the following

```sh
# Whether or not to use the local biff service. This service sends "new mail" notifications to users who have requested new mail notification with the UNIX command "biff y".
# For compatibility reasons this feature is on by default. On systems with lots of interactive users, the biff service can be a performance drain.
biff = no

# The list of trusted remote SMTP clients.
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 10.0.0.0/24 172.0.0.0/8

# Handle Postfix-style extensions.
recipient_delimiter = +

# Prevent Postfix from using backwards-compatible default settings
compatibility_level = 3.6

# Configuration to relay mail through Gmail (TLS)
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_tls_security_level = encrypt
smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination
```

Where:

- `biff = no` indicates we don't want to send "new mail" notifications to users who have requested new mail notification with the UNIX command `biff y`. On systems with lots of interactive users, the biff service can be a performance drain. And we simply don't care about this since we won't be receiving any mail anyway.
- `mynetworks` is configured to accept relaying emails from the local host `127.0.0.0/8`, our private network `10.0.0.0/24` and our private docker network `172.0.0.0/8`.
- `recipient_delimiter = +` can be useful when local applications (e.g., cron jobs, web apps) want to send emails via postfix using a syntax like user+tag@domain.com. Setting this `+` delimiter ensures Postfix does not break the address and keeps the tag intact before forwarding.
- `compatibility_level = 3.6` ensures we don't use any backwards-compatible default setting, likely for better performances.
- The rest applies to a secure relay configuration through gmail, with TLS encryption.

### Gmail SMTP authentication

In order for outgoing emails to be accepted by the Gmail SMTP server, we need to configure a Gmail application password in the `/etc/postfix/sasl_passwd` file. Let's edit it:

```sh
sudo nano /etc/postfix/sasl_passwd
```

And add the following content:

```sh
[smtp.gmail.com]:587    REDACTED_GMAIL_ADDRESS:REDACTED_APPLICATION_PASSWORD
```

Where:
- `REDACTED_GMAIL_ADDRESS` is your Gmail email address. Example: `john.doe@gmail.com`
- `REDACTED_APPLICATION_PASSWORD` is a dedicated [Google application password](https://myaccount.google.com/apppasswords), which you might need to create.


Save the file. Once this is done, we want to restrict access to it as much as we can, since it contains a password in clear. Let's adjust its permissions:

```sh
sudo chmod 600 /etc/postfix/sasl_passwd
```

Finally, run the following to create/update the lookup table Postfix requires:

```sh
sudo postmap hash:/etc/postfix/sasl_passwd
```

### Restart Postfix

All that remains to do is restart Postfix in order to load our new configuration. This is done using:

```sh
sudo systemctl restart postfix
```

Once done, you can check whether the service was successfully started using:

```sh
sudo systemctl status postfix
```

Which should indicates that the service is `active (running)`, and also mention the following in the associated logs:

```sh
Apr 18 22:26:53 [HOSTNAME] postfix/master[368525]: daemon started -- version 3.10.5, configuration /etc/postfix
Apr 18 22:26:53 [HOSTNAME] systemd[1]: Started postfix.service - Postfix Mail Transport Agent (main/default instance).
```

## Send out a test email

You can validate that the configuration is working as expected by sending out an email from command line.

```sh
echo "Coucou you" | mail -s "Test email" [RECIPIENT_EMAIL_ADDRESS]
```

Where you need to replace `[RECIPIENT_EMAIL_ADDRESS]` with the actual email address of the recipient of this test email.

If all went well, it should be delivered. Otherwise, it might be stuck in the local mail queue, which can be checked using:

```sh
mailq
```

If you see an error and want to attempt to deliver all queued mail again, you can run:

```sh
mailq -q
```