/* Base stolen from ip_nat_ftp.c 
   SL extension for TCP NAT alteration.
   Inspiration from http://ftp.gnumonks.org/pub/doc/conntrack+nat.html */

#include <linux/module.h>
#include <linux/netfilter_ipv4.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <net/tcp.h>
#include <linux/netfilter_ipv4/ip_nat.h>
#include <linux/netfilter_ipv4/ip_nat_helper.h>
#include <linux/netfilter_ipv4/ip_nat_rule.h>
#include <linux/netfilter_ipv4/ipt_string.h>

#if 0
#define DEBUGP printk
#else
#define DEBUGP(format, args...)
#endif

#define SL_PORT 80

DECLARE_LOCK(ip_sl_lock);

/* the removal string */ 
#define NEEDLE_LEN 5
static char needle[NEEDLE_LEN+1] = ":8135";

/* turn mac address into http header by sprintfing this template */
#define MACHDR_LEN 23 
#define MACHDR_START 10 /* the digit where the mac address starts */
char machdr[MACHDR_LEN+1] = "X-SLMac: 006451163670\n";

/* needle for GET */
#define GET_NEEDLE_LEN 5
static char get_needle[GET_NEEDLE_LEN+1] = "GET /";

#define SEARCH_FAIL 0
/* 
static unsigned int
sl_nat_expected(struct sk_buff **pskb,
		 unsigned int hooknum,
		 struct ip_conntrack *ct,
		 struct ip_nat_info *info,
		 struct ip_conntrack *master,
		 struct ip_nat_info *masterinfo,
		 unsigned int *verdict)
{
	IP_NF_ASSERT(info);
*/
  /* huh? */
/*	IP_NF_ASSERT(!(info->initialized & (1<<HOOK2MANIP(hooknum))));

	DEBUGP("sl_nat_expected: skb->data %s\n", *pskb->data);

	if (hooknum == NF_IP_POST_ROUTING) {
		DEBUGP("Postrouting hook");
	} else if (hooknum == NF_IP_PRE_ROUTING) {
		DEBUGP("prerouting hook");
	}

	return NF_ACCEPT;
}
 */
/* this does the dirty work of removing the port number and inserting the
   http header */

static int sl_data_fixup(  struct ip_conntrack *ct,
			  struct sk_buff **pskb,
			  enum ip_conntrack_info ctinfo,
			  struct ip_conntrack_expect *expect)
{
	struct iphdr *iph = (*pskb)->nh.iph;
	
	struct tcphdr *tcph = (void *)iph + iph->ihl*4;

	/* needed to remove string */
	char *haystack, *repl_ptr, *buffer;
	int hlen, matchoff, matchlen;
        proc_ipt_search search=search_linear;
	
	/* this is going to sl dc, add machdr */
	printk(KERN_DEBUG "ip_nat_sl: sl_data_fixup\n");
/*	printk(KERN_DEBUG "SL_DATA_FIXUP: seq %u + %u in %u\n",
	       expect->seq, exp_sl_info->len,
	       ntohl(tcph->seq));
*/
	/* no ip header is a problem */
	if ( !iph ) return SEARCH_FAIL;

	/* get lengths, and validate them */
	hlen=ntohs(iph->tot_len)-(iph->ihl*4);
	if ( NEEDLE_LEN > hlen) return SEARCH_FAIL;
	
	/* where we are looking */
	haystack=(char *)iph+(iph->ihl*4);

    /* The sublinear search comes in to its own
     * on the larger packets */
    if ( (hlen > IPT_STRING_HAYSTACK_THRESH) &&
        (NEEDLE_LEN > IPT_STRING_NEEDLE_THRESH) ) {
        if ( hlen < BM_MAX_HLEN ) {
            search=search_sublinear;
        }else{ 
           if (net_ratelimit())
                printk(KERN_INFO "ipt_string: Packet too big "
                    "to attempt sublinear string search "
                    "(%d bytes)\n", hlen );
		}
	}

    	/* search and remove port numbers or add machdr */
	repl_ptr = search(needle, haystack, NEEDLE_LEN, hlen);
	if (repl_ptr != NULL ) {
		printk(KERN_DEBUG "port :8135 needle found, removing...\n");
		return 1;
		/* mangle the packet, removing the port number */
		if (!ip_nat_mangle_tcp_packet(pskb, ct, ctinfo, 
					matchoff, matchlen, 
					buffer, strlen(buffer)))
			return 0;
	
	} else {
		
		/* see if this is a GET request */
       		repl_ptr = search(get_needle, haystack, GET_NEEDLE_LEN, hlen);

		/* no repl_ptr is a problem */
		if (repl_ptr == NULL) {
			printk(KERN_DEBUG "no get_needle found in packet\n");
			return 1;
		} else {
			/* copy the bits */
			struct ethhdr *bigmac = (*pskb)->mac.ethernet;
			printk(KERN_DEBUG "ip_sl_nat: mac address %s", bigmac->h_source );
			return 1;
			if (bigmac->h_source != NULL) {
				return 0;
			}
		}
	}
	return 1;
}

static unsigned int sl_help(struct ip_conntrack *ct,
			 struct ip_conntrack_expect *exp,
			 struct ip_nat_info *info,
			 enum ip_conntrack_info ctinfo,
			 unsigned int hooknum,
			 struct sk_buff **pskb)
{
	struct iphdr *iph = (*pskb)->nh.iph;
	struct tcphdr *tcph = (void *)iph + iph->ihl*4;
	unsigned int datalen;
	int dir;
	/* struct ip_ct_sl_expect *exp_sl_info; */

	printk(KERN_DEBUG "ip_nat_sl: sl_help start\n");
/*	if (!exp)
		printk(KERN_ERR "ip_nat_sl: no exp!!\n");
*i8*ii8**
	/* exp_sl_info = &exp->help.exp_sl_info; */

	/* nasty debugging */
	if (hooknum == NF_IP_POST_ROUTING) {
		printk(KERN_DEBUG "nat_sl: postrouting\n");
	}
	if (hooknum == NF_IP_PRE_ROUTING) {
		printk(KERN_DEBUG "nat_sl: prerouting\n");
	}
	if (dir == IP_CT_DIR_ORIGINAL) {
		printk(KERN_DEBUG "nat_sl: original direction\n");
	} else {
		printk(KERN_DEBUG "nat_sl: not original direction\n");
	}


	/* Only mangle things once: original direction in POST_ROUTING
	   and reply direction on PRE_ROUTING. */
	dir = CTINFO2DIR(ctinfo);
	if (!(hooknum == NF_IP_POST_ROUTING && dir == IP_CT_DIR_ORIGINAL) ) {
		printk(KERN_DEBUG "nat_sl: Not touching dir %s at hook %s\n",
		       "ORIG", "POSTROUTING" );

		return NF_ACCEPT;
	}
	datalen = (*pskb)->len - iph->ihl * 4 - tcph->doff * 4;

	/* not sure what this does */
	/* If it's in the right range... */
/*	if (between(exp->seq + exp_sl_info->len,
		    ntohl(tcph->seq),
		    ntohl(tcph->seq) + datalen)) { */
		if (!sl_data_fixup(ct, pskb, ctinfo, exp)) {
			printk(KERN_ERR "ip_nat_sl: error sl_data_fixup\n");
			return NF_DROP;
		}
/*	} else { */
		/* Half a match?  This means a partial retransmisison.
		   It's a cracker being funky. */
/*		if (net_ratelimit()) {
			printk("SL_NAT: partial packet %u/%u in %u/%u\n",
			       exp->seq, exp_sl_info->len,
			       ntohl(tcph->seq),
			       ntohl(tcph->seq) + datalen);
		}
		return NF_DROP;

	}
*/
	printk(KERN_DEBUG "ip_nat_sl: sl_help end, returning nf_accept\n");
	return NF_ACCEPT;
}

struct ip_nat_helper sl;

static void fini(void)
{
	printk(KERN_DEBUG "ip_nat_sl: unregistering for port %d\n", SL_PORT);
	ip_nat_helper_unregister(&sl);
}

static int __init init(void)
{
	int ret = 0;
	
        sl.list.next = 0;
        sl.list.prev = 0;
	sl.me = THIS_MODULE;
	sl.flags = (IP_NAT_HELPER_F_STANDALONE|IP_NAT_HELPER_F_ALWAYS);
        sl.tuple.dst.protonum = IPPROTO_TCP;
	
        sl.tuple.dst.u.tcp.port = __constant_htons(SL_PORT);
        /* sl.mask.dst.protonum = 0xFFFF;
        sl.mask.dst.u.tcp.port = 0xFFFF; */
        sl.help = sl_help;
	sl.expect = NULL;
	printk(KERN_DEBUG "ip_nat_sl: Trying to register for port %d\n", SL_PORT);
        ret = ip_nat_helper_register(&sl);
	if (ret) {
  	  printk(KERN_ERR "ip_nat_sl: error registering helper for port %d\n", SL_PORT);
	  fini();
	  return ret;
	}
	return ret;
}

EXPORT_SYMBOL(ip_sl_lock);

module_init(init);
module_exit(fini);
MODULE_LICENSE("GPL");
