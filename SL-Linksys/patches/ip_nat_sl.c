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
#include <linux/jhash.h>

#if 0
#define DEBUGP printk
#else
#define DEBUGP(format, args...)
#endif

#define SL_PORT 80

DECLARE_LOCK(ip_sl_lock);

/* the removal string for the port */ 
#define PORT_NEEDLE_LEN 5
static char port_needle[PORT_NEEDLE_LEN+1] = ":8135";

/* needle for GET */
#define GET_NEEDLE_LEN 5
static char get_needle[GET_NEEDLE_LEN+1] = "GET /";

/* needle for host header */
#define HOST_NEEDLE_LEN 6
static char host_needle[HOST_NEEDLE_LEN+1] = "Host: ";

#define SEARCH_FAIL 0

static int sl_data_fixup(  struct ip_conntrack *ct,
			  struct sk_buff **pskb,
			  enum ip_conntrack_info ctinfo,
			  struct ip_conntrack_expect *expect)
{
	struct iphdr *iph = (*pskb)->nh.iph;
	struct tcphdr *tcph = (void *)iph + iph->ihl*4;

	/* needed to remove string */
	char *haystack, *repl_ptr;

	/* equivalent to skb->data but apparently earlier
	   needed because ip_nat_mangle_tcp_packet uses it as a ref point */ 
	unsigned char *skb_early_data;
	
	int hlen, match_offset, match_len, rep_len;
        proc_ipt_search search=search_linear;
	
	/* this is going to sl dc, add machdr */
	printk(KERN_DEBUG "ip_nat_sl: sl_data_fixup\n");

	/* no ip header is a problem */
	if ( !iph ) return SEARCH_FAIL;

	/* get lengths, and validate them */
	hlen=ntohs(iph->tot_len)-(iph->ihl*4);
	if ( PORT_NEEDLE_LEN > hlen) return SEARCH_FAIL;
	
	/* where we are looking */
	haystack=(char *)iph+(iph->ihl*4);

    	/* The sublinear search comes in to its own
     	   on the larger packets */
    	if ( (hlen > IPT_STRING_HAYSTACK_THRESH) &&
        	(PORT_NEEDLE_LEN > IPT_STRING_NEEDLE_THRESH) ) {
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
	repl_ptr = search(port_needle, haystack, PORT_NEEDLE_LEN, hlen);
	if (repl_ptr != NULL ) {
		/* mangle the packet, removing the port number */
		/* distance past match offset of string to match  */
		match_len = (int)((char *)(*pskb)->tail - (char *)repl_ptr); 
		printk(KERN_DEBUG "match_len: %d\n", match_len); 

		rep_len = match_len - PORT_NEEDLE_LEN;	

		skb_early_data = (void *)tcph + tcph->doff*4;
		match_offset = repl_ptr - (int)skb_early_data;
		
		printk(KERN_DEBUG "match_len %d, rep_len %d\n", match_len, rep_len);
		printk(KERN_DEBUG "match_offset %d\n", match_offset);
		printk(KERN_DEBUG "UPDATED rep_buffer: %s\n", &repl_ptr[PORT_NEEDLE_LEN]);
		printk(KERN_DEBUG "UPDATED rep_len: %u\n", rep_len);
		printk(KERN_DEBUG "\npre-mangle packet: %s\n\n", &repl_ptr[-match_offset]);
		
		if (!ip_nat_mangle_tcp_packet(pskb, ct, ctinfo, 
					match_offset, match_len, 
					&repl_ptr[PORT_NEEDLE_LEN], rep_len)) {  
			printk(KERN_ERR "unable to mangle tcp packet\n");
			return 0;
		}
		printk(KERN_DEBUG "\npacket mangled ok: %s\n\n", &repl_ptr[-match_offset]);

	} else if (repl_ptr == NULL) {
		printk(KERN_DEBUG "port_needle :8135 NOT found, trying get_needle\n");
		
		/* see if this is a GET request */
       		repl_ptr = search(get_needle, haystack, GET_NEEDLE_LEN, hlen);

		/* no repl_ptr is a problem */
		if (repl_ptr == NULL) {
			printk(KERN_DEBUG "no get_needle found in packet\n");
			return 1;
		} else if ( repl_ptr != NULL) {
			
			printk(KERN_DEBUG "get_needle FOUND: %s\n", repl_ptr); 
			/* look for the Host: header */
			repl_ptr = search(host_needle, haystack, HOST_NEEDLE_LEN, hlen);
			if (repl_ptr == NULL) {
				printk(KERN_ERR "no host header found in packet\n");
				return 1;
			}  else if (repl_ptr != NULL) {	
				/* found a host header, insert the mac addr */ 
				struct ethhdr *bigmac = (*pskb)->mac.ethernet;
				unsigned int jhashed = 0;
			        int machdr_len = 0;
				char machdr[16];
				if (bigmac->h_source == NULL) {
					printk(KERN_ERR "no source mac found\n");
					return 1;
				} else  {
					printk(KERN_DEBUG "source mac found: %x%x%x%x%x%x\n",
							bigmac->h_source[0],
							bigmac->h_source[1],
							bigmac->h_source[2],
							bigmac->h_source[3],
							bigmac->h_source[4],
							bigmac->h_source[5]);
					/* jenkins hash obfuscation */
					jhashed = jhash((void *)bigmac->h_source, 
							sizeof(bigmac->h_source), 420);
					printk(KERN_DEBUG "jhashed: %x\n", jhashed);
				
					/* create the http header */
					machdr_len = sprintf(machdr, "X-SL: %x\r\n", jhashed);
					printk(KERN_DEBUG "ip_nat_sl: machdr %s, length %d\n", 
							 machdr, machdr_len);
					if (machdr_len == 0) {
						printk(KERN_ERR "sprintf fail for machdr");
						return 1;
					} else {

						match_len = 0;
						rep_len = match_len + sizeof(machdr);	
						printk(KERN_DEBUG "host match_len %u\n", match_len);	
						printk(KERN_DEBUG "host rep_len %u\n", rep_len);	
						printk(KERN_DEBUG "host match_offset %u\n", match_offset);	
						skb_early_data = (void *)tcph + tcph->doff*4;
						match_offset = repl_ptr - (int)skb_early_data;
							
						/* insert the machdr into the http headers */
						if (!ip_nat_mangle_tcp_packet(pskb, ct, ctinfo, 
								match_offset, match_len, 
								machdr, rep_len)) {  
							printk(KERN_ERR "failed mangle packet\n");
							return 0;
						}
						printk(KERN_DEBUG "\npacket mangled ok: %s\n\n", 
							&repl_ptr[-match_offset]);

					}
				}
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

	/* HACK - skip dest port not 80 */
	if (ntohs(tcph->dest) != SL_PORT) {
		return 1;
	}
	printk(KERN_DEBUG "ip_nat_sl: tcphdr dest port %d, source port %d, ack seq %d\n", 
			ntohs(tcph->dest), ntohs(tcph->source),
			tcph->ack_seq);
	
	/* let SYN packets pass */
	printk(KERN_DEBUG "ip_nat_sl: FIN: %d\n", tcph->fin);
	printk(KERN_DEBUG "ip_nat_sl: SYN: %d\n", tcph->syn);
	printk(KERN_DEBUG "ip_nat_sl: RST: %d\n", tcph->rst);
	printk(KERN_DEBUG "ip_nat_sl: ACK: %d\n", tcph->ack);
	printk(KERN_DEBUG "ip_nat_sl: URG: %d\n", tcph->urg);
	printk(KERN_DEBUG "ip_nat_sl: PSH: %d\n", tcph->psh);
	if (!( (tcph->psh == 1) && (tcph->ack == 1)) ) {
		printk(KERN_INFO "ip_nat_sl: not psh and ack\n");
		return NF_ACCEPT;
	}

	/* nasty debugging */
	if (hooknum == NF_IP_POST_ROUTING) {
		printk(KERN_DEBUG "ip_nat_sl: postrouting\n");
	} else if (hooknum == NF_IP_PRE_ROUTING) {
		printk(KERN_DEBUG "ip_nat_sl: prerouting\n");
	}

	/* packet direction */
	dir = CTINFO2DIR(ctinfo);
	if (dir == IP_CT_DIR_ORIGINAL) {
		printk(KERN_DEBUG "ip_nat_sl: original direction\n");
	} else if (dir == IP_CT_DIR_REPLY) {
		printk(KERN_DEBUG "ip_nat_sl: reply direction\n");
	} else if (dir == IP_CT_DIR_MAX) {
		printk(KERN_DEBUG "ip_nat_sl: max direction\n");
	}

	/* Only mangle things once: original direction in POST_ROUTING
	   and reply direction on PRE_ROUTING. */
	if (!((hooknum == NF_IP_POST_ROUTING) && (dir == IP_CT_DIR_ORIGINAL)) ) {
		printk(KERN_DEBUG "nat_sl: Not ORIGINAL and POSTROUTING, returning\n");
		return NF_ACCEPT;
	}
	datalen = (*pskb)->len - iph->ihl * 4 - tcph->doff * 4;

	if (!sl_data_fixup(ct, pskb, ctinfo, exp)) {
			printk(KERN_ERR "ip_nat_sl: error sl_data_fixup\n");
			return NF_DROP;
	}
	
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
    sl.mask.dst.u.tcp.port = 0;
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
