/* Base stolen from ip_nat_ftp.c 
   SL extension for TCP NAT alteration.
   Inspiration from http://ftp.gnumonks.org/pub/doc/conntrack+nat.html
   Much initial mentoring from Eveginy Polyakov
   Thanks to Steve Edwards for help making this stuff work
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/skbuff.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/netfilter.h>
#include <net/tcp.h>
#include <net/netfilter/nf_nat.h>
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

/* salt for the hashing */
#define JHASH_SALT 420

/* maximum packet length */ 
#define MAX_PACKET_LEN 1480

/* This is calculated anyway but we use it to check for big packets */
#define SL_HEADER_LEN 29

#define MACADDR_SIZE 12

#define SL_DEBUG 1

static unsigned int add_sl_header(
    struct sk_buff **pskb,
    struct nf_conn *ct, 
    enum ip_conntrack_info ctinfo,
    char *user_data,
    int user_data_len,
    unsigned int host_offset ) {
        
    struct ethhdr *bigmac;
    unsigned int jhashed, slheader_len, match_offset;
    char dst_string[MACADDR_SIZE], src_string[MACADDR_SIZE], slheader[SL_HEADER_LEN];
    bigmac = (struct ethhdr *) skb_push(*pskb, sizeof(struct ethhdr));

    /* create the X-SL Header */        
#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nsource mac found: %02x%02x%02x%02x%02x%02x\n",
            bigmac->h_source[0],
            bigmac->h_source[1],
            bigmac->h_source[2],
            bigmac->h_source[3],
            bigmac->h_source[4],
            bigmac->h_source[5]);

    printk(KERN_DEBUG "\ndest mac found: %02x%02x%02x%02x%02x%02x\n",
            bigmac->h_dest[0],
            bigmac->h_dest[1],
            bigmac->h_dest[2],
            bigmac->h_dest[3],
            bigmac->h_dest[4],
            bigmac->h_dest[5]);
#endif        

    sprintf(src_string, "%02x%02x%02x%02x%02x%02x",
            bigmac->h_source[0],
            bigmac->h_source[1],
            bigmac->h_source[2],
            bigmac->h_source[3],
            bigmac->h_source[4],
            bigmac->h_source[5]);

    sprintf(dst_string, "%02x%02x%02x%02x%02x%02x",
            bigmac->h_dest[0],
            bigmac->h_dest[1],
            bigmac->h_dest[2],
            bigmac->h_dest[3],
            bigmac->h_dest[4],
            bigmac->h_dest[5]);

               
    /* create the http header */
    /* jenkins hash obfuscation of source mac */
    jhashed = jhash((void *)src_string, MACADDR_SIZE, JHASH_SALT);
    slheader_len = sprintf(slheader, "X-SL: %x|%s\r\n", jhashed, dst_string);

#ifdef SL_DEBUG
    printk(KERN_DEBUG "ip_nat_sl: slheader %s, length %d\n", slheader, slheader_len);
#endif        
        
    /* handle sprintf failure */
    if (slheader_len == 0) {
#ifdef SL_DEBUG
        printk(KERN_ERR "sprintf fail for slheader");
#endif        
        return 0;
    } 

    /* now insert the sl header */
    /* calculate distance to the host header */
    match_offset = host_offset - (unsigned int)(user_data) + CRLF_NEEDLE_LEN; 

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nhost match_offset %u\n", match_offset);    
#endif        

    /* insert the slheader into the http headers */
    if (!nf_nat_mangle_tcp_packet( pskb,
				   ct, 
				   ctinfo,
				   match_offset,
                                   0, 
                                   slheader, 
				   slheader_len)) {  

#ifdef SL_DEBUG
        printk(KERN_ERR "ip_nat_sl: failed to mangle packet\n");
#endif        
        return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\npacket mangled ok: %s\n\n",
	   (char *)(host_offset - match_offset) );
#endif        

    return 1;
}


/* So, this packet has hit the connection tracking matching code.
   Mangle it, and change the expectation to match the new version. */
static unsigned int nf_nat_sl(
              struct sk_buff **pskb,
              enum ip_conntrack_info ctinfo,
              struct nf_conntrack_expect *exp,
	      unsigned int host_offset,
	      unsigned char *user_data)
{
    struct nf_conn *ct = exp->master;
    struct iphdr  *iph = ip_hdr(*pskb);
    //    struct tcphdr *tcph = (void *)iph + iph->ihl*4;
    int packet_len, user_data_len;
    
    packet_len = ntohs(iph->tot_len) - (iph->ihl*4);
    user_data_len = (int)((*pskb)->tail -  user_data);

#ifdef SL_DEBUG
    printk(KERN_DEBUG "ip_nat_sl: packet length: %d\n", packet_len);
    printk(KERN_DEBUG "ip_nat_sl: packet user data length: %d\n", user_data_len); 
    printk(KERN_DEBUG "ip_nat_sl: packet check: %s\n", user_data);
#endif


    /* look for a port rewrite and remove it if exists */
    if (sl_remove_port(pskb, ct, ctinfo, host_offset, user_data, user_data_len)) {
#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nport rewrite removed :8135 successfully\n");
#endif
        return 1;
    }

    /* ok now attempt to insert the X-SL header */
    if (!add_sl_header(pskb, ct, ctinfo, user_data, user_data_len, host_offset)) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "add_sl_header returned NULL\n");
#endif
        return 0;
    }

    /* that's all folks */
    return 1;
}


struct nf_conntrack_helper sl;

static void nf_nat_sl_fini(void)
{
	rcu_assign_pointer(nf_nat_sl_hook, NULL);
	synchronize_rcu();
}

static int __init nf_nat_sl_init(void)
{

	BUG_ON(rcu_dereference(nf_nat_sl_hook));
	rcu_assign_pointer(nf_nat_sl_hook, nf_nat_sl);
	return 0;
}

module_init(nf_nat_sl_init);
module_exit(nf_nat_sl_fini);
