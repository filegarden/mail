# File Garden's Mail Server

This README walks you through setting up an instance of our mail server.

Note we aren't interested in maintaining a mail server that can handle every use case. This mail server is opinionated, catering primarily to our own needs with no configuration. Currently, that means:

- Only sending/replying is supported, not receiving. We receive mail using Cloudflare Email Routing.
- This doesn't store any mail persistently (and thus doesn't support IMAP or POP3). We store mail in the inbox at the address Cloudflare Email Routing forwards to.
- This is a batteries-included solution. Some automation features require a domain using Cloudflare DNS and can't be disabled:
  - Let's Encrypt TLS certificates are renewed every 60 days.
  - DKIM keys are rotated every 30 days.
- Mail-related DNS records are checked and strictly enforced to maximize your mail's deliverability and minimize any possibility of abuse.

If you want an unopinionated, configurable mail server with none of the above, you might be interested in [Docker Mailserver](https://github.com/docker-mailserver/docker-mailserver).

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
  - [Docker Compose File](#docker-compose-file)
  - [Environment Variables](#environment-variables)
- [Setting DNS Records](#setting-dns-records)
- [Managing the Server](#managing-the-server)
  - [Start the Server](#start-the-server)
  - [Viewing Server Logs](#viewing-server-logs)
  - [Restart the Server](#restart-the-server)
  - [Update the Server](#update-the-server)
  - [Stop the Server](#stop-the-server)
  - [Uninstall the Server](#uninstall-the-server)
- [Managing Email Addresses](#managing-email-addresses)
  - [Add a User](#add-a-user)
  - [Reset a User's Password](#reset-a-users-password)
  - [Remove a User](#remove-a-user)
  - [List All Users](#list-all-users)
- [Sending Mail](#sending-mail)

## Installation

**By using this mail server, you agree to the Let's Encrypt Subscriber Agreement.**

First, you must own a server. We recommend a VPS running Linux. (Debian is our favorite Linux distro!) A mail server isn't resource-intensive unless it handles massive volumes of mail, so we recommend choosing a cheap one.

It must have a static IPv4 address (which for especially cheap servers can cost extra), or else your mail won't be deliverable to any recipient using a mail provider that only supports IPv4, which is unfortunately very common.

Inbound ports 465 and 587 are used to submit mail for the server to relay, so you may need to allow them through your firewall. Different firewalls work differently, so look up how to allow inbound ports for your system's firewall. If you don't have a firewall, you should first install one and ensure it's enabled! (For Debian-based systems, we recommend UFW, which sometimes comes preinstalled.) Some hosting providers also enforce another firewall outside the server through some sort of network configuration on their website.

Outbound port 25 is used to send mail, but sometimes hosting providers block it by default to mitigate spam. You may have to contact your provider to allow outbound (NOT inbound) port 25 for your server. Look up information for your provider if necessary.

Install [Docker](https://docs.docker.com/engine/install) on your server. Docker is the engine this mail server runs on.

Clone this repository onto your server by running the following command using [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

```sh
git clone https://github.com/filegarden/mail.git
```

This creates a directory called `mail` containing this repository's files. You can go into this directory by running the following.

```sh
cd mail
```

> [!IMPORTANT]
> All commands used in this README must be ran from inside the repository's directory.

## Configuration

All configuration described below is mandatory.

### Docker Compose File

Create a file named `compose.override.yaml` in your own copy of this repository, and paste the following into it.

```yaml
services:
  mail:
    hostname: mail.example.com
```

Change `mail.example.com` to the hostname you want your mail server to use, under a domain you own. This hostname must uniquely identify your mail server, so unless your domain is used for nothing but this mail server, you should include an extra subdomain (like `mail.` in `mail.example.com`). You can always change this later and restart the mail server.

> [!NOTE]
> A mail server's hostname is different from the domain used in its email addresses. A mail server is uniquely identified by one hostname, but one mail server can handle email addresses for any number of domains. For example, a mail server at `mail.example.com` can be configured to handle mail for `user@example.com` and `user@foo.com`.

### Environment Variables

Create a file named `.env` in your copy of the repository, and paste the following into it.

```sh
POSTMASTER_ADDRESS=
CF_API_TOKEN=
```

Set `POSTMASTER_ADDRESS` equal to an email address you own. If there's ever a problem with your mail server, the mail server itself will email you at this address. If there's a problem with the mail server's TLS certificates, you'll be emailed by Let's Encrypt, the certificate authority that signs the certificates.

To set `CF_API_TOKEN`, you must own a domain that uses [Cloudflare](https://www.cloudflare.com/) for DNS. Cloudflare DNS is free and can be used with any domain. Setting a Cloudflare API token here lets the mail server automatically manage DNS records under the domain you choose.

To obtain a Cloudflare API token:

1. Go to [My Profile > API Tokens](https://dash.cloudflare.com/profile/api-tokens) from the Cloudflare dashboard.
2. Select **Create Token**.
3. Select the **Edit zone DNS** template.
4. Under **Zone Resources**, select the domain you want to give the mail server access to. _See the caution note below on choosing a domain._
5. Continue and create the token. DO NOT SHARE THE TOKEN WITH ANYONE!
6. Copy the token and paste it after `CF_API_TOKEN=` in your `.env` file.

> [!CAUTION]
> It's highly recommended the domain you choose for your Cloudflare token is **not** used for anything security-sensitive. That way, if an attacker ever compromises your token, their ability to impact you negatively will be limited. For security-critical applications, we advise using a throwaway domain **that isn't used in your hostname or email addresses.** You'll simply point some DNS records from your main domain(s) to the throwaway domain. We'll walk through how to do this when [setting DNS records](#setting-dns-records).
>
> There's a set of `.xyz` domains which are perfect for this, known as the "1.111B class". They're designed to be cheap, costing less than $1/year from [Namecheap](https://www.namecheap.com/). It's called the 1.111B class because there are 1.111 billion domains in it: any domain that's 6 to 9 digits followed by `.xyz`. For example, File Garden uses `985532063.xyz`. (985532063 is "garden" converted from base 36 to base 10.)
>
> If you use a cheap throwaway domain for your Cloudflare token, _only_ use it for your Cloudflare token. Using a cheap throwaway domain for just your token has no impact on your mail, whereas using it for your hostname or email addresses can make your mail more likely to be marked as spam or rejected, since spammers often use cheap throwaway domains.

You can always change the values in your `.env` file later and restart the mail server. Changing the domain used in your Cloudflare token's permissions also requires a restart.

## Setting DNS Records

> [!NOTE]
> If the mail server ever requires a DNS record that's under the domain your Cloudflare token has access to, the server can set it automatically rather than outputting an error with manual instructions. When this happens, the server outputs the DNS record that was set.

When the mail server exits (other than from being manually shut down), Docker automatically restarts it. This is inconvenient while you're still setting things up, because if you're missing DNS records the server needs, the server will exit with an error and go into an infinite restart loop.

To check for errors without that inconvenience, you can run just the mail server's setup stage without automatic restarts using this command.

```sh
docker compose run --rm mail setup
```

This setup stage already runs when starting the server normally, but using it separately like this makes it easy to run this command, fix any errors, run the command again, and repeat until there are no errors left.

**This process walks you through all the DNS records you need to set (if there are any), one by one.** When a DNS record is missing or incorrect, the error message has instructions on how to set it correctly.

Note that sometimes it can take a moment for the server to recognize a newly updated DNS record. In my experience using Cloudflare DNS, it can take up to two minutes but usually only takes a few seconds.

Once the command says "Setup complete!", you're ready to [start the server for real](#start-the-server)!

## Managing the Server

### Start the Server

To start the mail server, run this.

```sh
docker compose up -d
```

After running this, the mail server will start automatically on boot from now on.

If there's an outdated build of the mail server already running, this stops it and then starts the most recently built version. See information on [building updates](#update-the-server).

### Viewing Server Logs

For a live view of the mail server's logs, run this.

```sh
docker compose logs -f
```

To stop viewing, press `ctrl`+`C`.

If you only want the logs for when your mail is bounced and fails to send, run this.

```sh
docker compose logs -f | grep -F ' status=bounced '
```

It's recommended you occasionally check this for any fixable issues.

> [!TIP]
> If the output of any of these commands doesn't fit in your terminal, you can enter the same command but with ` | less` at the end to see only one screen of its output at a time, starting from the beginning.
>
> When using `less`, type `q` to stop viewing, and don't scroll to navigate. Instead, use the arrow keys, `Page Up`, and `Page Down`.
>
> You can also type `F` (capitalized, so hold `shift`) to stay scrolled to the end like the original command. Then press `ctrl`+`C` to navigate manually again.

### Restart the Server

To restart the mail server **using the version that's already running**, run this. This does **not** restart to a new version after [updating](#update-the-server).

```sh
docker compose restart
```

This does nothing if the mail server isn't already running.

> [!NOTE]
> During a restart, the mail server will be down for a brief moment. There are techniques for restarting with zero downtime in Docker, but they're less simple and outside the scope of this README.

### Update the Server

To update the mail server and restart it with the updated version, run this.

```sh
git pull && docker compose up -d --build
```

If the mail server is already up to date, it won't be restarted.

To update the mail server and build the updated version without starting it, run this.

```sh
git pull && docker compose build
```

When you're ready, use the updated build by [starting](#start-the-server) the mail server (NOT [RESTARTING](#restart-the-server), which restarts the old build).

> [!CAUTION]
> When the mail server is updated, the previous version of the Docker image becomes "dangling" (unused and untagged) but isn't deleted. To delete all dangling Docker images on your machine, run this command.
>
> ```sh
> docker image prune -f
> ```

### Stop the Server

To stop the server, run this.

```sh
docker compose down
```

After running this, the server will no longer start automatically when the server boots.

### Uninstall the Server

To delete the mail server and all of its data irreversibly, run this.

```sh
docker compose down -v --rmi local
```

After running this, you can delete the repository's directory too.

## Managing Email Addresses

### Add a User

To add a user to your mail server that you can log into and send mail as, run the following command from inside the repository, replacing `user@example.com` with the email address to create for the new user.

```sh
docker compose run -it --rm mail user add user@example.com
```

If this outputs an error requiring you to set a DNS record, set it and run the command again. You may have to do this a few times; there are a few DNS records that must be set.

If there are no errors, a strong password for the new user will be generated and outputted for you to copy. To log in as the user, see [Sending Mail](#sending-mail). This password will never appear again and is not stored anywhere. (Passwords are irreversibly hashed using Argon2, and only the hash is stored.)

### Reset a User's Password

To generate and display a new password for an existing user, overwriting the old password, use this command.

```sh
docker compose run -it --rm mail user reset user@example.com
```

### Remove a User

Use this command to remove a user so it can no longer log in or send mail.

```sh
docker compose run -it --rm mail user remove user@example.com
```

If you remove all addresses that used a particular domain, this will also output a list of any DNS records the mail server no longer needs under that domain.

### List All Users

Use this command to list every user's email address.

```sh
docker compose run -it --rm mail user list
```

If you have no users, this won't output anything.

## Sending Mail

After successfully [creating a user](#add-a-user), you'll see output similar to the following.

```
User created with these credentials:

SMTP Server: mail.example.com

Username: user@example.com

Password:
AVnJwwbQcg5SEJac0/WSZhI6IxOXIB9PfVfdNBn5NJTxEA8IA6Aqp2pPzLHYMRSpgI5kKDw3No/OOooM+ui1qMX/NbeuVONDprTqRI8Z/tmRHVatNoc4NYrp4RvsT48d0NCGFO8RiRG2NU9/4mJR/KwMLFe88PoCKMZpVvG4MkiTDZs2LVlFajunvhfbvuNqAoe4c3saL2v/vosuA0HW4yh5yi4ANwdEoKuGuc+x/DGnYHG6ZPHATQHxM49vJ8q
```

The credentials you see can be used in your mail client to log into your mail server and send mail. For example, here's [instructions for Gmail](https://support.google.com/mail/answer/22370). You can look up how to send as a different address for your mail client.

**If your mail client has a port option, choose port 465,** as it's recommended by [RFC 8314 (section 3.3)](https://datatracker.ietf.org/doc/html/rfc8314#section-3.3).

Mail clients let you set a name (not username) for the user you're sending as. You can set this to anything you want. Recipients will see it as your display name.

Mail clients also ask for the email address separately from the username. For simplicity, this mail server always uses addresses as usernames, so be sure to input the full email address as both the username and the address.

Note this is an SMTP server, not IMAP or POP3. Mail clients often let you set IMAP or POP3 information too, but that's only needed if the mail server stores mail. This mail server doesn't, so it only needs SMTP.
