This README walks you through setting up your own instance of our mail server.

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

  > This mail server is configured to automatically remove the first component of your hostname to determine the default domain for the mail server's addresses. For example, if the hostname is `mail.example.com`, the default domain will be `example.com`. If the hostname is `abc.x.y.z`, the default domain will be `x.y.z`. If the hostname is `example.com`, the default domain will be `com`, which is invalid.
  >
  > Currently, the default domain is used
  >
  > * in the sender address of internally generated mail. For example, if `example.com` is the default domain, error messages can come from `root@example.com`.
  > * when logging into your mail server. For example, you can log in as `user` rather than specifying a full address like `user@example.com`. When the domain part is omitted from a login name, the server automatically appends "@" followed by the default domain.
  >
  > It's not strictly necessary to include an extra subdomain in your hostname, but if you don't, you'll need to set `mydomain = $myhostname` in `etc/postfix/main.cf` to prevent the hostname's first component from being automatically removed. Note that doing this may cause difficulty [configuring your PTR record](#configure-your-ptr-record) if your domain points to something other than your mail server, such as a separate web server or a proxy like Cloudflare. If your domain's DNS A record doesn't point to your mail server directly, you won't be able to create a PTR record, because PTR records require your domain's A record to point to the same IP address used in the PTR record.
</details>

## Configure your PTR record

<details>
  <summary>Why should I configure my PTR record?</summary>

  > PTR records aren't strictly necessary, but they can help increase the deliverability of your mail. Mail from servers without a PTR record is sometimes marked as spam or rejected entirely. Popular email providers (including Google and Yahoo) also require a PTR record for mail servers that exceed a certain mail frequency threshold.
</details>
