# File Garden's Mail Server

This README walks you through setting up an instance of our mail server.

Note we aren't interested in maintaining a mail server that can handle every use case. This mail server is opinionated, catering primarily to our own needs with no configuration. Currently, that means:
* Only sending/replying is supported, not receiving. We receive mail using Cloudflare Email Routing.
* This doesn't store any mail persistently (and thus doesn't support IMAP or POP3).
* This is a batteries-included solution. Some automation features require a domain using Cloudflare DNS and can't be disabled:
  * Let's Encrypt TLS certificates are renewed every 60 days.
  * DKIM keys are rotated every 30 days.
* Mail-related DNS records are checked and strictly enforced to maximize your mail's deliverability and minimize any possibility of abuse.

If you want an unopinionated, configurable mail server with none of the above, you might be interested in [Docker Mailserver](https://github.com/docker-mailserver/docker-mailserver).

## Installation

**By using this, you agree to the Let's Encrypt Subscriber Agreement.**

First, you must own a server. (We recommend a VPS running Linux, but any OS will work. Debian is our favorite Linux distro!)

Inbound ports 465 and 587 are used to submit mail for the server to relay, so allow them through your firewall. Different firewalls work differently, so look up how to allow inbound ports for your system's firewall. If you don't have a firewall, you should first install one and ensure it's enabled! (For Debian-based systems, we recommend UFW. UFW comes with Ubuntu.)

Outbound port 25 is used to send mail, but sometimes hosting providers block it by default to mitigate spam. You may have to contact your provider to allow outbound (NOT inbound) port 25 for your server. Look up information for your provider if necessary.

Install [Docker](https://docs.docker.com/engine/install) on your server. Docker is the engine this mail server runs on.

Clone this repository onto your server by running the following command using [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

```sh
git clone https://github.com/filegarden/mail.git
```

This creates a directory called `mail` containing this repository's files. You can go into this directory by running the following, which will be useful for later steps.

```sh
cd mail
```

## Configuration

All configuration described below is mandatory.

### Docker Compose File

Create a file named `compose.override.yaml` in your own copy of this repository, and paste the following into it:

```yaml
services:
  mail:
    hostname: mail.example.com
```

Change `mail.example.com` to the hostname you want your mail server to use, under a domain you own. This hostname must uniquely identify your mail server, so unless your domain is used for nothing but this mail server, you should include an extra subdomain (like `mail.` in `mail.example.com`). You can always change this later and restart the mail server.

> [!NOTE]
>
> A mail server's hostname is different from the domain used in its email addresses. A mail server is uniquely identified by one hostname, but one mail server can handle email addresses for any number of domains. For example, a mail server at `mail.example.com` can be configured to handle mail for `user@example.com` and `user@foo.com`.

### Environment Variables

Create a file named `.env` in your copy of the repository, and paste the following into it:

```sh
ACME_ACCOUNT_EMAIL=
CF_API_TOKEN=
```

Set `ACME_ACCOUNT_EMAIL` equal to an email address you own. If there's ever a problem concerning your TLS certificates, then Let's Encrypt, the certificate authority that signs your certificates, will warn you via email at this address.

To set `CF_API_TOKEN`, you must own a domain that uses [Cloudflare](https://www.cloudflare.com/) for DNS. Cloudflare DNS is free and can be used with any domain. Setting a Cloudflare API token here lets the mail server automatically manage DNS records under the domain you choose.

To obtain a Cloudflare API token:
1. Go to [My Profile > API Tokens](https://dash.cloudflare.com/profile/api-tokens) from the Cloudflare dashboard.
2. Select **Create Token**.
3. Select the **Edit zone DNS** template.
4. Under **Zone Resources**, select the domain you want to give the mail server access to. _See the caution note below on choosing a domain._
5. Continue and create the token. DO NOT SHARE THE TOKEN WITH ANYONE!
6. Copy the token and paste it after `CF_API_TOKEN=` in your `.env` file.

> [!CAUTION]
>
> It's highly recommended the domain you choose for your Cloudflare token is **not** used for anything security-sensitive. That way, if an attacker ever compromises your token, their ability to impact you negatively will be limited. For security-critical applications, we advise using a throwaway domain **that isn't used in your hostname or email addresses.** You'll simply point some DNS records from your main domain(s) to the throwaway domain. We'll walk through how to do this.
>
> There's a set of `.xyz` domains which are perfect for this, known as the "1.111B class". They're designed to be cheap, costing less than $1/year from [Namecheap](https://www.namecheap.com/). It's called the 1.111B class because there are 1.111 billion domains in it: any domain that's 6 to 9 digits followed by `.xyz`. For example, File Garden uses `985532063.xyz`. (985532063 is "garden" converted from base 36 to base 10.)
>
> If you use a cheap throwaway domain for your Cloudflare token, _only_ use it for your Cloudflare token. Using a cheap throwaway domain for just your token has no impact on your mail, whereas using it for your hostname or email addresses can make your mail more likely to be marked as spam or rejected, since spammers often use cheap throwaway domains.

You can always change the values in your `.env` file later and restart the mail server. Changing the domain used in your Cloudflare token's permissions also requires a restart.

## Setting DNS Records

When the mail server exits (other than from being manually shut down), Docker automatically restarts it. This is inconvenient while you're still setting things up, because if you're missing DNS records the server needs, the server will exit with an error and go into an infinite restart loop.

To check for errors without that inconvenience, you can run just the mail server's setup stage without any automatic restarts using the following command.

```sh
docker compose run -it --rm mail setup
```

This setup stage already runs when starting the server normally, but using it separately like this makes it easy to run this command, fix any errors, run the command again, and repeat until there are no errors left.

**This process walks you through all the DNS records you need to set (if there are any), one by one.** When a DNS record is missing or incorrect, the error message has instructions on how to set it correctly.

Note that sometimes it can take a moment for the server to recognize a newly updated DNS record. In my experience using Cloudflare DNS, it can take up to two minutes but usually only takes a few seconds.

Once the command says "Setup complete!", you're ready to start the server for real!

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

**Note this is an SMTP server, not IMAP or POP3.** Mail clients often let you set IMAP or POP3 information too, but that's only needed if the mail server stores mail. This mail server doesn't, so it only needs SMTP.

If your mail client has a port option, choose port 465, as it's recommended by [RFC 8314 (section 3.3)](https://datatracker.ietf.org/doc/html/rfc8314#section-3.3).

Mail clients let you set a name (not username) for the user you're sending as. You can set this to anything you want. Recipients will see it as your display name.

Mail clients also ask for the email address separately from the username. For simplicity, this mail server always uses addresses as usernames, so be sure to input the full email address as both the username and the address.
