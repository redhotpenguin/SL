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

static char get_needle[6] = "GET /";

static unsigned int help (
             struct sk_buff **pskb,
	     unsigned int protoff,
	     struct nf_conntrack_expect *exp,
             enum   ip_conntrack_info ctinfo
        )     
{
    	struct tcphdr _tcph, *th;
    	struct iphdr  *iph = ip_hdr(*pskb)
    	struct nf_conn *ct = exp->master;
	unsigned int host_offset, plen;
    	struct ts_state ts;
    	unsigned char *user_data;
	int ret;
	typeof(nf_nat_sl_hook) nf_nat_sl;

	/* only operate on established connections */
        if (ctinfo != IP_CT_ESTABLISHED
            && ctinfo != IP_CT_ESTABLISHED+IP_CT_IS_REPLY) {
#ifdef SL_DEBUG                
	    printk("sl: Conntrackinfo = %u\n", ctinfo);
#endif    
                return NF_ACCEPT;
        }

	/* only mangle outbound packets */
	if (ctinfo == IP_CT_IS_REPLY) {
		return NF_ACCEPT;
	}

	// get the tcp header
	th = skb_header_pointer(*pskb, protoff, sizeof(_tcph), &_tcph);
	if (th == NULL)
		return NF_ACCEPT;

    /* only operate on port 80 (prod) and 9999 (dev) */
    	if ( ! ( ntohs(th->dest) == SL_PORT ) ||
           ( ntohs(th->dest) == SL_DEV_PORT ) ) {

		return NF_ACCEPT;
    	}


#ifdef SL_DEBUG
	printk(KERN_DEBUG "\n\nnf_conntrack_sl: tcphdr dst %d, src %d, ack seq %d\n",
        ntohs(th->dest), ntohs(th->source), th->ack_seq);

    	/* let SYN, FIN, RST, PSH, ACK, ECE, CWR, URG packets pass */
    	printk(KERN_DEBUG "nf_conntrack_sl: FIN: %d\n", th->fin);
    	printk(KERN_DEBUG "nf_conntrack_sl: SYN: %d\n", th->syn);
   	printk(KERN_DEBUG "nf_conntrack_sl: RST: %d\n", th->rst);
    	printk(KERN_DEBUG "nf_conntrack_sl: PSH: %d\n", th->psh);
    	printk(KERN_DEBUG "nf_conntrack_sl: ACK: %d\n", th->ack);
    	printk(KERN_DEBUG "nf_conntrack_sl: URG: %d\n", th->urg);
    	printk(KERN_DEBUG "nf_conntrack_sl: ECE: %d\n", th->ece);
    	printk(KERN_DEBUG "nf_conntrack_sl: CWR: %d\n", th->cwr);
#endif    


    	/* only work on push or ack packets */
    	if (!( (th->psh == 1) || (th->ack == 1)) ) {
#ifdef SL_DEBUG
        	printk(KERN_INFO "nf_conntrack_sl: psh or ack\n");
#endif    
        	return NF_ACCEPT;
    	}

    	/* get the packet length */
   	plen=ntohs(iph->tot_len)-(iph->ihl*4);
#ifdef SL_DEBUG
        printk(KERN_INFO "nf_conntrack_sl: packet length %d\n", plen);
#endif    

    	/* minimum length to search the packet */
    	if (plen < MIN_PACKET_LEN) {
#ifdef SL_DEBUG
        	printk(KERN_DEBUG "nf_conntrack_sl: packet too small to examine - %d\n", plen);
#endif    
        	return NF_ACCEPT;
    	}

        /* see if this is a GET request */
	user_data = (void *)th + th->doff*4;
        if (strncmp(get_needle, user_data, GET_NEEDLE_LEN)) {    

#ifdef SL_DEBUG
        	printk(KERN_DEBUG "\nno get_needle found in packet\n");
#endif  	      
        	return 0;
    	} 



	// see if the packet contains a Host header
    	// zero out textsearch state
    	memset(&ts, 0, sizeof(ts));

	// offset to the '\r\nHost:' header
        host_offset = skb_find_text(
        	*pskb,
        	(unsigned int)(&user_data[GET_NEEDLE_LEN]),
        	user_data_len - GET_NEEDLE_LEN,
        	search[SEARCH_HOST].ts,
		&ts );

	if (host_offset != NULL) {
		ret = nf_nat_sl(pskb, ctinfo, exp, host_offset, user_data);
	}
	else {
		ret = NF_ACCEPT;
	}
    
	return ret;
}

/* don't make this __exit, since it's called from __init ! */
static void nf_conntrack_ftp_fini(void)
{
#ifdef SL_DEBUG
	printk(KERN_DEBUG "nf_conntrack_sl: unregistering for port %d\n", SL_PORT);
#endif

        nf_conntrack_helper_unregister(&sl); 
}

static int __init nf_nat_sl_init(void)
{
 
	int ret = 0;
	    
	//    sl.list.next = 0;
	//    sl.list.prev = 0;
    	sl.me = THIS_MODULE;
	//    sl.flags = (NF_NAT_HELPER_F_STANDALONE|NF_NAT_HELPER_F_ALWAYS);
	sl.tuple.dst.protonum = IPPROTO_TCP;

	sl.tuple.dst.u.tcp.port = __constant_htons(SL_PORT);
    	//    sl.mask.dst.u.tcp.port = 0;
    	//    sl.help = sl_help;
 	//   sl.expect = NULL;

#ifdef SL_DEBUG
    printk(KERN_DEBUG "nf_conntrack_sl: Trying to register for port %d\n", SL_PORT);
#endif

    ret = nf_conntrack_helper_register(&sl);

    if (ret) {

#ifdef SL_DEBUG
        printk(KERN_ERR "nf_conntrack_sl: error registering helper, port %d\n", SL_PORT);
#endif

        nf_nat_sl_fini();
        return ret;
    }
    return ret;
}

module_init(nf_conntrack_ftp_init);
module_exit(nf_conntrack_ftp_fini);
