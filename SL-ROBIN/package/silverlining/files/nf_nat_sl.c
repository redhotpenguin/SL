/*
   SL extension for TCP NAT alteration.
   Inspiration from http://ftp.gnumonks.org/pub/doc/conntrack+nat.html
   Much initial mentoring from Eveginy Polyakov
   Thanks to Steve Edwards for help making this stuff work
   Thanks also to Patrick McHardy for resolving some issues

   Copyright 2009 Silver Lining Networks
   Portions of this module are licensed under the Silver Lining Networks
   software license.
*/

#define DEBUG
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/textsearch.h>
#include <linux/skbuff.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/netfilter_ipv4.h>
#include <net/netfilter/nf_nat.h>
#include <net/netfilter/nf_nat_helper.h>
#include <net/netfilter/nf_nat_rule.h>
#include <net/netfilter/nf_conntrack.h>
#include <net/netfilter/nf_conntrack_helper.h>
#include <net/netfilter/nf_conntrack_expect.h>
#include <linux/jhash.h>
#include <linux/netfilter/nf_conntrack_sl.h>

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Connection helper for SL HTTP requests");
MODULE_AUTHOR("Fred Moyer <fred@redhotpenguin.com>");

static char int2Hex[16] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F' };

static char *sl_proxy = "69.36.240.28";
module_param(sl_proxy, charp, 0400);
MODULE_PARM_DESC(sl_proxy, "proxy server ip address in dotted quad");

static char *sl_device = "ffffffffffff";
module_param(sl_device, charp, 0400);
MODULE_PARM_DESC(sl_device, "macaddress that identifies the device");

/* removes :8135 from the host name */

static int sl_remove_port(struct sk_buff *skb,
			  struct nf_conn *ct,
			  enum ip_conntrack_info ctinfo,
			  unsigned int host_offset,
			  unsigned int dataoff,
			  unsigned int datalen,
			  unsigned int end_of_host)
{
	unsigned int start, end, offset;
	struct ts_state ts;

	/* Is the http port 8135?  Look for 'Host: foo.com:8135'
	   end_of_host? -----^     */
	start = end_of_host - sl_ts_conf[SL_SEARCH_PORT].len;
	end   = start + sl_ts_conf[SL_SEARCH_PORT].len;
	offset = skb_find_text(skb, start, end,
			       sl_ts_conf[SL_SEARCH_PORT].ts, &ts);
	if (offset == UINT_MAX) {
		pr_debug("no port rewrite found in packet strncmp\n");
		return 0;
	}
	offset += start;
	pr_debug("remove_port found a port at offset %u\n", offset);

	/* remove the ':8135' port designation from the packet */
	if (!nf_nat_mangle_tcp_packet(skb, ct, ctinfo, offset - dataoff,
				      sl_ts_conf[SL_SEARCH_PORT].len -
				      sl_ts_conf[SL_SEARCH_NEWLINE].len * 2,	// subtract \r\n
				      NULL, 0)) {
		pr_err("unable to remove port needle\n");

		/* we've already found the port, so we return 1 regardless */
		return 1;
	}

	pr_debug("port removed ok\n");
	return 1;
}

static unsigned int add_sl_header(struct sk_buff *skb,
				  struct nf_conn *ct,
				  enum ip_conntrack_info ctinfo,
				  unsigned int host_offset,
				  unsigned int dataoff,
				  unsigned int datalen,
				  unsigned int end_of_host)
{
	unsigned int end, offset;
	struct ts_state ts;

	/* first make sure there is room */
	if (skb->len >= (MAX_PACKET_LEN - SL_HEADER_LEN)) {
		pr_debug("\nskb too big, length: %d\n", skb->len);
		return 0;
	}

	/* next make sure an X-SLR header is not already present in the
	   http headers already */
	end = end_of_host + sl_ts_conf[SL_SEARCH_XSLR].len;
	offset = skb_find_text(skb, end_of_host, end,
			       sl_ts_conf[SL_SEARCH_XSLR].ts, &ts);
	if (offset != UINT_MAX) {
		pr_debug("\npkt x-slr already present\n");
		return 0;
	}
	pr_debug("\nno x-slr header present, adding\n");

	{
		unsigned int jhashed, slheader_len;
		char slheader[SL_HEADER_LEN];
		char src_string[MACADDR_SIZE];
		unsigned char *pSrc_string = src_string;
		struct ethhdr *bigmac = eth_hdr(skb);
		unsigned char *pHsource = bigmac->h_source;
		int i = 0;

		/* convert the six octet mac source address into a hex  string
		   via bitmask and bitshift on each octet */
		while (i < 6) {
			*(pSrc_string++) = int2Hex[(*pHsource) >> 4];
			*(pSrc_string++) = int2Hex[(*pHsource) & 0x0f];

			pHsource++;
			i++;
		}

		/* null terminate it just to be safe */
		*pSrc_string = '\0';

		pr_debug("\nsrc macaddr %s\n", src_string);

		/********************************************/
		/* create the http header */
		/* jenkins hash obfuscation of source mac */
		jhashed = jhash(src_string, MACADDR_SIZE, JHASH_SALT);

		/* create the X-SLR Header */
		slheader_len = sprintf(slheader, "X-SLR: %08x|%s\r\n", jhashed, sl_device);

		/* handle sprintf failure */
		if (slheader_len != SL_HEADER_LEN) {
			pr_err("exp header %s len %d doesnt match calc len %d\n",
			       slheader, SL_HEADER_LEN, slheader_len);

			return 0;
		}
		pr_debug("xslr %s, len %d\n", slheader, slheader_len);

		/* insert the slheader into the http headers
		   Host: foo.com\r\nXSLR: ffffffff|ffffffffffff  */
		if (!nf_nat_mangle_tcp_packet(skb, ct, ctinfo,
					      end_of_host - dataoff, 0,
					      slheader, slheader_len)) {

			pr_err(" failed to mangle packet\n");
			return 0;
		}
		pr_debug("packet mangled ok\n");
		return 1;
	}
}

/* So, this packet has hit the connection tracking matching code.
   Mangle it, and change the expectation to match the new version. */
static unsigned int nf_nat_sl(struct sk_buff *skb, struct nf_conn *ct,
			      enum ip_conntrack_info ctinfo,
			      unsigned int host_offset,
			      unsigned int dataoff,
			      unsigned int datalen)
{
	struct iphdr *iph = ip_hdr(skb);
	struct ts_state ts;
	unsigned int port_status = 0;
	unsigned int start, end_of_host;
	char dest_ip[16];

	pr_debug("\nhere is the proxy ip %s\n", sl_proxy);
	pr_debug("\nsource %u.%u.%u.%u, dest %u.%u.%u.%u\n",
		 NIPQUAD(iph->saddr), NIPQUAD(iph->daddr));

	// make sure we have an end of host header
	// scan to the end of the host header
	start = host_offset + sl_ts_conf[SL_SEARCH_HOST].len;
	end_of_host = skb_find_text(skb, start, skb->len,
				    sl_ts_conf[SL_SEARCH_NEWLINE].ts, &ts);
	if (end_of_host == UINT_MAX) {
		pr_err("\nend of host not found in search\n");
		return NF_ACCEPT;
	}
	end_of_host += start + sl_ts_conf[SL_SEARCH_NEWLINE].len;
	pr_debug("\nfound end_of_host %u\n", end_of_host);

	// if it isn't destined for the proxy, try to remove the port
	sprintf(dest_ip, "%u.%u.%u.%u", NIPQUAD(iph->daddr));
	if (strcmp(sl_proxy, dest_ip)) {
		pr_debug("\nsl_proxy %s, dest %s no match, checking port\n",
			 sl_proxy, dest_ip);

		/* look for a port rewrite and remove it if exists */
		port_status = sl_remove_port(skb, ct, ctinfo,
					     host_offset, dataoff, datalen,
					     end_of_host);

		pr_debug("\nport status: %d\n\n", port_status);

		if (port_status) {
			pr_debug("\nport rewrite removed :8135 successfully\n\n");
			return NF_ACCEPT;
		}

	}
	pr_debug("\nsl_proxy %s, dest_ip %s\n", sl_proxy, dest_ip);

	/* attempt to insert the X-SLR header, since this is sl destined */
	if (!add_sl_header(skb, ct, ctinfo, host_offset,
			   dataoff, datalen, end_of_host))
		pr_debug("\nadd_sl_header returned not added\n");

	return NF_ACCEPT;
}

static void nf_nat_sl_fini(void)
{
	rcu_assign_pointer(nf_nat_sl_hook, NULL);
	synchronize_rcu();
}

static int __init nf_nat_sl_init(void)
{
	BUG_ON(nf_nat_sl_hook != NULL);
	rcu_assign_pointer(nf_nat_sl_hook, nf_nat_sl);

	pr_debug("nf_nat_sl starting, proxy %s, device %s\n", sl_proxy, sl_device);
	return 0;
}

module_init(nf_nat_sl_init);
module_exit(nf_nat_sl_fini);
