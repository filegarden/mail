This README walks you through setting up your own instance of our mail server.

**By using this, you agree to the Let's Encrypt Subscriber Agreement.**

## Configure your hostname

Create a file named `compose.override.yaml` in your own copy of this repository, and paste the following into it:

```yaml
services:
  mail:
    hostname: mail.example.com
```

Then change `mail.example.com` to your mail server's hostname. Generally, your hostname should include an extra subdomain (like `mail.` in `mail.example.com`).

> [!NOTE]
>
> A mail server's hostname is different from the domain used in its email addresses. A hostname uniquely identifies a mail server, so a mail server can only have one hostname. On the other hand, one mail server can handle email addresses for any number of domains. For example, a mail server at `mail.example.com` can be configured to handle mail for `user@foo.com` and `user@bar.com`.

<details>
  <summary>Why should my hostname have an extra subdomain?</summary>

  > It's not strictly necessary to include an extra subdomain in your hostname, but not including one may cause difficulty [configuring your PTR record](#configure-your-ptr-record) if your domain points to something other than your mail server, such as a separate web server or a proxy like Cloudflare. If your domain doesn't point to your mail server directly in its A/AAAA record, you won't be able to create a valid PTR record, because that requires your domain's A/AAAA record to point to the same IP address from the PTR record.
</details>

## Configure your PTR record

<details>
  <summary>Why should I configure my PTR record?</summary>

  > PTR records aren't strictly necessary, but they can help increase the deliverability of your mail. Mail from servers without a PTR record is sometimes marked as spam or rejected entirely. Popular email providers (including Google and Yahoo) also require a PTR record for mail servers that exceed a certain mail frequency threshold.
</details>
