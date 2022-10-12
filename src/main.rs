use clap::builder::PossibleValuesParser;
use clap::Parser;
use milter::{Context, Milter, Status};
use mxdns::MxDns;
use once_cell::sync::Lazy;
use regex::Regex;
use trust_dns_resolver::Resolver;

static RESOLVER: Lazy<Resolver> =
    Lazy::new(|| Resolver::from_system_conf().unwrap());

static DOMAIN_RE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(
        r"(?x)
    ^[^@\s]+@
    (?P<domain>([a-zA-Z-]+\.)*
    [[:word:]]+)$
",
    )
    .unwrap()
});

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Mode of enforcement
    #[arg(short, long, value_parser = PossibleValuesParser::new(["audit", "enforce"]), default_value = "audit")]
    mode: String,

    /// Address to listen at
    #[arg(short, long, default_value = "inet:3000@localhost")]
    listen_addr: String,

    /// Address of the DNSBL server
    #[arg(short, long, default_value = "zen.spamhaus.org")]
    blocklist: String,

    /// Custom nameserver for DNSBL
    #[arg(short, long, default_value = "")]
    nameserver: String,
}

fn get_domain(email: &str) -> Option<&str> {
    DOMAIN_RE
        .captures(email)
        .and_then(|cap| cap.name("domain").map(|domain| domain.as_str()))
}

fn get_blocklist_resolver(nameserver: String, blocklist: String) -> MxDns {
    let blocklists = vec![blocklist];
    if nameserver != "" {
        if let Ok(ip_response) = RESOLVER.lookup_ip(nameserver) {
            return MxDns::with_dns(ip_response.iter().last().unwrap(), blocklists);
        }
    }
    return MxDns::new(blocklists).unwrap();
}

#[milter::on_rcpt(rcpt_callback)]
fn handle_rcpt(mut ctx: Context<String>, recipients: Vec<&str>) -> milter::Result<Status> {
    let args = Args::parse();
    let mxdns = get_blocklist_resolver(args.nameserver, args.blocklist);
    for rcpt in recipients.iter() {
        if let Some(rcpt_domain) = get_domain(rcpt) {
            if let Ok(mx_response) = RESOLVER.mx_lookup(format!("{rcpt_domain}.")) {
                for record in mx_response.iter() {
                    if let Ok(ip_response) = RESOLVER.lookup_ip(record.exchange().to_string().as_str()) {
                        for addr in ip_response.iter() {
                            if mxdns.is_blocked(addr).unwrap() {
                                let bad_ip = addr.to_string();
                                match ctx.data.borrow_mut() {
                                    Some(bad_ips) => {
                                        *bad_ips = format!("{bad_ips},{bad_ip}");
                                    }
                                    None => {
                                        ctx.data.replace(bad_ip)?;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Ok(Status::Continue)
}

#[milter::on_eom(eom_callback)]
fn handle_eom(mut ctx: Context<String>) -> milter::Result<Status> {
    let args = Args::parse();
    let queue_id = ctx.api.macro_value("{i}").unwrap();
    if let Some(bad_ips) = ctx.data.take()? {
        println!("queue_id: {:?}, bad_ips: {:?}", queue_id.unwrap(), bad_ips);
        if args.mode == "enforce" && !bad_ips.is_empty() {
            return Ok(Status::Reject);
        }
    }
    Ok(Status::Continue)
}

#[milter::on_abort(abort_callback)]
fn handle_abort(mut ctx: Context<String>) -> milter::Result<Status> {
    let _ = ctx.data.take();
    Ok(Status::Continue)
}

fn main() {
    let args = Args::parse();
    println!("starting reject-rbl-rcpt milter");
    Milter::new(&args.listen_addr)
        .name("RcptDNSBLMilter")
        .on_rcpt(rcpt_callback)
        .on_eom(eom_callback)
        .on_abort(abort_callback)
        .run()
        .expect("milter execution failed");
}
