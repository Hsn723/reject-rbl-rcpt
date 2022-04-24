[![GitHub release](https://img.shields.io/github/release/hsn723/reject-rbl-rcpt.svg?sort=semver&maxAge=60)](https://github.com/hsn723/reject-rbl-rcpt/releases)

# reject-rbl-rcpt
`reject-rbl-rcpt` is a milter for rejecting recipients based on DNSBL.

## Motivation
Several methods currently exist to reject received mail based on the sender address, for instance by checking the sender domain or IP against DNSBLs. This milter however addresses specific use cases where one would want to reject an email from being sent out based on the IP reputation of the recipients. This can be useful for reasons such as:

- you provide services which send out email notifications to customer-provided email addresses and want to avoid sending out emails to bad IPs
- you want to prevent data exfiltration from your infrastructure by means of email
- you want to log connections to bad IPs for auditing purpose

Of course, DNSBL are not perfect and this is meant to be used in addition to other stronger security measures.

## Usage
A docker container is provided for scenarios where you would want to use `reject-rbl-rcpt` as a sidecar container in Kubernetes. Otherwise, `reject-rbl-rcpt` can be run as a standalone binary. Note that `libmilter` is required, and can be installed as `libmilter-dev` in Debian-based distributions.

```sh
reject-rbl-rcpt

USAGE:
    reject-rbl-rcpt [OPTIONS]

OPTIONS:
    -b, --blocklist <BLOCKLIST>        Address of the DNSBL server [default: zen.spamhaus.org]
    -h, --help                         Print help information
    -l, --listen-addr <LISTEN_ADDR>    Address to listen at [default: inet:3000@localhost]
    -m, --mode <MODE>                  Mode of enforcement [default: audit] [possible values: audit,enforce]
    -V, --version                      Print version information
```

In Postfix, configure the milter.

```
/etc/postfix/main.cf:
    smtpd_milters = inet:localhost:3000
    non_smtpd_milters = $smtpd_milters
```
