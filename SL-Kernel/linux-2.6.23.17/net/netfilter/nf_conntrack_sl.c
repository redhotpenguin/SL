/* SLN extension for connection tracking. */

#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/netfilter.h>
#include <linux/ip.h>
#include <linux/ctype.h>
#include <linux/inet.h>
#include <linux/textsearch.h>
#include <net/checksum.h>
#include <net/tcp.h>

#include <net/netfilter/nf_conntrack.h>
#include <net/netfilter/nf_conntrack_expect.h>
#include <net/netfilter/nf_conntrack_ecache.h>
#include <net/netfilter/nf_conntrack_helper.h>
#include <linux/netfilter/nf_conntrack_sl.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Fred Moyer <fred@redhotpenguin.com");
MODULE_DESCRIPTION("sl connection tracking helper");

static char *ts_algo = "kmp";
module_param(ts_algo, charp, 0400);
MODULE_PARM_DESC(ts_algo, "textsearch algorithm to use (default kmp)");

unsigned int (*nf_nat_sl_hook)(struct sk_buff **pskb,
                               enum ip_conntrack_info ctinfo,
                               struct nf_conntrack_expect *exp,
                               unsigned int host_offset,
                               unsigned char *user_data)
				   __read_mostly;
EXPORT_SYMBOL_GPL(nf_nat_sl_hook);


static int sl_help (struct sk_buff **pskb,
                    unsigned int protoff,
                    struct nf_conn *ct,
                    enum   ip_conntrack_info ctinfo)     
{
    struct tcphdr _tcph, *th;
    unsigned int host_offset, dataoff, datalen;
    struct nf_conntrack_expect *exp;
    struct ts_state ts;
    unsigned char *user_data;
    int ret = NF_ACCEPT;
    typeof(nf_nat_sl_hook) nf_nat_sl;

    /* only operate on established connections */
    if (ctinfo != IP_CT_ESTABLISHED
         && ctinfo != IP_CT_ESTABLISHED+IP_CT_IS_REPLY)
        return NF_ACCEPT;

    /* only mangle outbound packets */
    if ( ctinfo == IP_CT_IS_REPLY )
        return NF_ACCEPT;

#ifdef SKB_DEBUG                
    printk(KERN_DEBUG "conntrackinfo = %u\n", ctinfo);
#endif    

    // get the tcp header
    th = skb_header_pointer(*pskb, protoff, sizeof(_tcph), &_tcph);
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
    if (!( (th->psh == 1) || (th->ack == 1)) ) {
#ifdef SKB_DEBUG
    	printk(KERN_DEBUG "not psh or ack, return\n\n");
#endif    
        return NF_ACCEPT;
    }

    /* No data? */
    dataoff = protoff + th->doff * 4;
    if (dataoff >= (*pskb)->len) {

#ifdef SKB_DEBUG
	printk(KERN_DEBUG "dataoff(%u) >= skblen(%u), return\n\n", dataoff,
			 (*pskb)->len);
#endif
        return NF_ACCEPT;
    }

    datalen = (*pskb)->len - dataoff;

#ifdef SL_DEBUG
    printk(KERN_DEBUG "dataoff %u, packet length %d, data length %d\n",
	dataoff, (*pskb)->len, datalen);
#endif    

    /* if there aren't MIN_PACKET_LEN we aren't interested */
    if (datalen < MIN_PACKET_LEN) {
#ifdef SL_DEBUG
    	printk(KERN_DEBUG "skb data too small,  %d bytes, return\n\n", datalen);
#endif    
        return NF_ACCEPT;
    }

    /* see if this is a GET request */
    user_data = (void *)th + th->doff*4;

    // replace GET_NEEDLE_LEN from ts struct
    if (strncmp(search[GET].string, user_data, search[GET].len)) {    

#ifdef SL_DEBUG
        printk(KERN_DEBUG "no get_needle found in packet, return\n\n");
#endif  	      
        return NF_ACCEPT;
    } 

    /* safety break */
    exp = nf_ct_expect_alloc(ct);
    if (exp == NULL)
        return NF_DROP;

#ifdef SL_DEBUG
    printk(KERN_DEBUG "packet dump:\n%s\n", user_data);
#endif


    // see if the packet contains a Host header
    printk(KERN_DEBUG "dataoff %u, user_data %u\n",
	dataoff, (unsigned int)user_data );

    // zero out textsearch state
    memset(&ts, 0, sizeof(ts));

    // offset to the '\r\nHost:' header
    host_offset = skb_find_text(*pskb,
				dataoff + search[GET].len,
				datalen - search[HOST].len,
				search[HOST].ts, &ts );
	
    if (host_offset == UINT_MAX) {
        return NF_ACCEPT;

    } else if (host_offset > 0) {

#ifdef SL_DEBUG
    printk(KERN_DEBUG "passing packet to nat module, host offset: %u\n", host_offset);
#endif
	return NF_ACCEPT;
    	nf_nat_sl = rcu_dereference(nf_nat_sl_hook);
    	ret = nf_nat_sl(pskb, ctinfo, exp, host_offset, user_data);
    }
    
    return ret;
}

static struct nf_conntrack_helper sl_helper __read_mostly = {
		.name                     = "sl",
		.max_expected             = 0,
		.timeout                  = 180,
		.tuple.src.l3num          = AF_INET,
		.tuple.dst.protonum       = IPPROTO_TCP,
		.tuple.src.u.tcp.port     = __constant_htons(SL_PORT),
		.me                       = THIS_MODULE,
		.help                     = sl_help,
};
  

/* don't make this __exit, since it's called from __init ! */
static void nf_conntrack_sl_fini(void)
{

#ifdef SL_DEBUG
	    printk(KERN_DEBUG " unregistering for port %d\n", SL_PORT);
#endif

        nf_conntrack_helper_unregister(&sl_helper); 
}

static int __init nf_conntrack_sl_init(void)
{
 
        int ret = 0;
	int i;

	for (i = 0; i < ARRAY_SIZE(search); i++) {
		search[i].ts = textsearch_prepare(ts_algo, search[i].string,
						  search[i].len,
						  GFP_KERNEL, TS_AUTOLOAD);
		if (IS_ERR(search[i].ts)) {
			ret = PTR_ERR(search[i].ts);
			goto err;
		}
	}

#ifdef SL_DEBUG
        printk(KERN_DEBUG "Registering nf_conntrack_sl, port %d\n", SL_PORT);
#endif

        ret = nf_conntrack_helper_register(&sl_helper);
	if (ret < 0)
		goto err;
	return 0;

err:
	while (--i >= 0)
		textsearch_destroy(search[i].ts);

	return ret;
}

module_init(nf_conntrack_sl_init);
module_exit(nf_conntrack_sl_fini);
