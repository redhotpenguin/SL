/* SLN extension for connection tracking. */

// #define DEBUG
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/textsearch.h>
#include <linux/netfilter.h>
#include <linux/tcp.h>

#include <net/netfilter/nf_conntrack.h>
#include <net/netfilter/nf_conntrack_helper.h>
#include <net/netfilter/nf_conntrack_expect.h>
#include <linux/netfilter/nf_conntrack_sl.h>

static char *ts_algo = "kmp";

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Fred Moyer <fred@redhotpenguin.com");
MODULE_DESCRIPTION("sl connection tracking helper");

module_param(ts_algo, charp, 0400);
MODULE_PARM_DESC(ts_algo, "textsearch algorithm (default: kmp)");

/* GET http method */
#define GET_LEN 5
static char get[GET_LEN + 1] = "GET /";

struct sl_ts_conf sl_ts_conf[] __read_mostly = {
	[SL_SEARCH_HOST] = {
		.string	= "Host: ",
		.len	= 6,
	},
	[SL_SEARCH_PORT] = {
		.string	= ":8135\r\n",
		.len	= 7
	},
	[SL_SEARCH_XSLR] = {
		.string	= "X-SLR",
		.len	= 5,
	},
	[SL_SEARCH_NEWLINE] = {
		.string	= "\n",
		.len	= 1,
	},
};
EXPORT_SYMBOL_GPL(sl_ts_conf);

unsigned int (*nf_nat_sl_hook)(struct sk_buff * skb, struct nf_conn * ct,
			       enum ip_conntrack_info ctinfo,
			       unsigned int host_offset,
			       unsigned int data_offset,
			       unsigned int datalen) __read_mostly;
EXPORT_SYMBOL_GPL(nf_nat_sl_hook);

static int sl_help(struct sk_buff *skb, unsigned int protoff,
		   struct nf_conn *ct, enum ip_conntrack_info ctinfo)
{
	struct tcphdr _tcph, *th;
	unsigned char _get_data[GET_LEN], *get_data;
	unsigned int dataoff, datalen;
	unsigned int host_offset;
	struct ts_state ts;
	int ret = NF_ACCEPT;
	typeof(nf_nat_sl_hook) nf_nat_sl;

	/* only operate on established connections */
	if (ctinfo != IP_CT_ESTABLISHED &&
	    ctinfo != IP_CT_ESTABLISHED + IP_CT_IS_REPLY)
		return NF_ACCEPT;

	/* only mangle outbound packets */
	if (CTINFO2DIR(ctinfo) == IP_CT_IS_REPLY)
		return NF_ACCEPT;

	/* No NAT? */
	if (0 && !(ct->status & IPS_NAT_MASK))
		return NF_ACCEPT;

#ifdef SKB_DEBUG
	printk(KERN_DEBUG "conntrackinfo = %u\n", ctinfo);
#endif

	/* not a full tcp header */
	th = skb_header_pointer(skb, protoff, sizeof(_tcph), &_tcph);
	if (th == NULL)
		return NF_ACCEPT;

#ifdef SKB_DEBUG
	printk(KERN_DEBUG "tcphdr dst %d, src %d, ack seq %u\n",
	       ntohs(th->dest), ntohs(th->source), th->ack_seq);

	/* let SYN, FIN, RST, PSH, ACK, ECE, CWR, URG packets pass */
	printk(KERN_DEBUG "FIN %d, SYN %d, RST %d, PSH %d, ACK %d, ECE %d\n",
	       th->fin, th->syn, th->rst, th->psh, th->ack, th->ece);
#endif

	/* only work on push or ack packets */
	if (!((th->psh == 1) || (th->ack == 1))) {
#ifdef SKB_DEBUG
		printk(KERN_DEBUG "not psh or ack, return\n\n");
#endif
		return NF_ACCEPT;
	}

	/* get tcp data offset */
	dataoff = protoff + th->doff * 4;
	if (dataoff >= skb->len) {
#ifdef SKB_DEBUG
		printk(KERN_DEBUG "dataoff(%u) >= skblen(%u), return\n\n",
		       dataoff, skb->len);
#endif
		return NF_ACCEPT;
	}

	/* get tcp data length */
	datalen = skb->len - dataoff;

	/* if not MIN_PACKET_LEN we aren't interested */
	if (datalen < MIN_PACKET_LEN) {
#ifdef SKB_DEBUG
		printk(KERN_DEBUG "skb data too small,  %d bytes, return\n",
		       datalen);
#endif
		return NF_ACCEPT;
	}

	pr_debug("dataoff %u, packet length %d, data length %d\n",
		 dataoff, skb->len, datalen);

	/* see if this is a GET request */
	get_data = skb_header_pointer(skb, dataoff,
				      sizeof(_get_data), &_get_data);
	if (get_data == NULL)
		return NF_ACCEPT;

	/* look for 'GET /' */
	if (strncmp(get, get_data, GET_LEN)) {
		pr_debug("No GET method found in packet, return\n\n");
		return NF_ACCEPT;
	}

	/* length of the data portion of the skb */
	datalen = skb->len - dataoff;

	host_offset = skb_find_text(skb, dataoff + GET_LEN, skb->len,
				    sl_ts_conf[SL_SEARCH_HOST].ts, &ts);
	if (host_offset == UINT_MAX)
		return NF_ACCEPT;
	host_offset += dataoff + GET_LEN;
	pr_debug("found HOST at offset %u\n", host_offset);

	nf_nat_sl = rcu_dereference(nf_nat_sl_hook);
	if (nf_nat_sl != NULL)
		ret = nf_nat_sl(skb, ct, ctinfo,
				host_offset, dataoff, datalen);
	return ret;
}

static const struct nf_conntrack_expect_policy sl_exp_policy = {
	.max_expected		= 0,
	.timeout		= 60,		/* Is this 60 seconds? */
};

static struct nf_conntrack_helper sl_helper __read_mostly = {
	.name			= "sl",
	.tuple.src.l3num	= AF_INET,
	.tuple.dst.protonum	= IPPROTO_TCP,
	.tuple.src.u.tcp.port	= __constant_htons(SL_PORT),
	.me			= THIS_MODULE,
	.help			= sl_help,
	.expect_policy		= &sl_exp_policy,
};

/* don't make this __exit, since it's called from __init ! */
static void nf_conntrack_sl_fini(void)
{
	int i;

	pr_debug(" unregistering for port %d\n", SL_PORT);
	nf_conntrack_helper_unregister(&sl_helper);
	for (i = 0; i < ARRAY_SIZE(sl_ts_conf); i++)
		textsearch_destroy(sl_ts_conf[i].ts);
}

static int __init nf_conntrack_sl_init(void)
{
	int ret = 0, i;

	pr_debug("Registering nf_conntrack_sl, port %d\n", SL_PORT);

	for (i = 0; i < ARRAY_SIZE(sl_ts_conf); i++) {
		sl_ts_conf[i].ts = textsearch_prepare(ts_algo,
						      sl_ts_conf[i].string,
						      sl_ts_conf[i].len,
						      GFP_KERNEL, TS_AUTOLOAD);
		if (IS_ERR(sl_ts_conf[i].ts)) {
			ret = PTR_ERR(sl_ts_conf[i].ts);
			goto err;
		}
	}

	ret = nf_conntrack_helper_register(&sl_helper);
	if (ret < 0) {
		pr_err("error registering module: %d\n\n", ret);
		goto err;
	}
	return ret;

err:
	while (--i >= 0)
		textsearch_destroy(sl_ts_conf[i].ts);
	return ret;
}

module_init(nf_conntrack_sl_init);
module_exit(nf_conntrack_sl_fini);
