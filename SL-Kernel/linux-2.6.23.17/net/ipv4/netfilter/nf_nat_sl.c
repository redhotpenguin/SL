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


/* removes :8135 from the host name */

static int sl_remove_port(
                struct sk_buff **pskb,
                struct nf_conn *ct,
                enum   ip_conntrack_info ctinfo,
                unsigned int host_offset,
                char   *user_data,
                int    user_data_len )
{

    struct ts_state ts;
    unsigned int match_offset, match_len, port_offset;

   /* Temporarily use match_len for the data length to be searched */
    match_len =  (unsigned int)(user_data_len - host_offset 
                                - (unsigned int)(user_data)
                                - (search[HOST].len + search[CRLF].len)
    );

    // zero out textsearch state
    memset(&ts, 0, sizeof(ts));

    // get the offset to the location of the port string ':8135'
    port_offset = skb_find_text(*pskb,
                                // start looking after '\r\nHost:'
                                host_offset + search[HOST].len + search[CRLF].len,
                                //(unsigned int)(&host_ptr[HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN])
                                match_len,
                                search[PORT].ts,
                                &ts );

    // no port needle found
    if (port_offset == UINT_MAX) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nno port rewrite found in packet\n");
#endif

        return 0;
    }


    match_offset = port_offset - (unsigned int)(&user_data);
    match_len    = (unsigned int)((char *)(*pskb)->tail - port_offset);

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nmatch_len: %d\n", match_len);
    printk(KERN_DEBUG "match_offset: %d\n", match_offset);
#endif

    /* remove the port */
    if (!nf_nat_mangle_tcp_packet( pskb, 
                                   ct, 
                                   ctinfo,
                                   match_offset,
                                   match_len,
                                   &user_data[match_offset],
                                   match_len - search[PORT].len ))  {

#ifdef SL_DEBUG
        printk(KERN_ERR "unable to remove port needle\n");
#endif
        return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nport needle removed ok\n");
#endif

    return 1; 
}


static unsigned int add_sl_header(struct sk_buff **pskb,
                                  struct nf_conn *ct, 
                                  enum ip_conntrack_info ctinfo,
                                  char *user_data,
                                  int user_data_len,
                                  unsigned int host_offset ) {
        
    struct ethhdr *bigmac;
    unsigned int jhashed, slheader_len, match_offset;
    char dst_string[MACADDR_SIZE], src_string[MACADDR_SIZE], slheader[SL_HEADER_LEN];
    bigmac = (struct ethhdr *) skb_push(*pskb, sizeof(struct ethhdr));

    /* first make sure there is room */
    if ( (*pskb)->len >= ( MAX_PACKET_LEN - SL_HEADER_LEN ) ) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "packet too large for sl_header, length: %d\n", (*pskb)->len);
#endif
        return 1;
    }

    /* create the X-SLR Header */        
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

    /********************************************/
    /* create the http header */
    /* jenkins hash obfuscation of source mac */
    jhashed = jhash((void *)src_string, MACADDR_SIZE, JHASH_SALT);
    slheader_len = sprintf(slheader, "X-SLR: %x|%s\r\n", jhashed, dst_string);

    /* handle sprintf failure */
    if (slheader_len == 0) {
        printk(KERN_ERR "sprintf fail for slheader");
        return 0;
    } 

#ifdef SL_DEBUG
    printk(KERN_DEBUG " slheader %s, length %d\n", slheader, slheader_len);
#endif        

    if (slheader_len != SL_HEADER_LEN) {
        printk(KERN_ERR "expected header len %d doesn't match calculated len %d",
               SL_HEADER_LEN, slheader_len );
    }



    /********************************************/
    /* now insert the sl header */
    /* calculate distance to the host header */
    match_offset = host_offset - (unsigned int)(user_data) + search[CRLF].len; 

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

        printk(KERN_ERR " failed to mangle packet\n");
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
static unsigned int nf_nat_sl(struct sk_buff **pskb,
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
    printk(KERN_DEBUG " packet length: %d\n", packet_len);
    printk(KERN_DEBUG " packet user data length: %d\n", user_data_len); 
    printk(KERN_DEBUG " packet check: %s\n", user_data);
#endif


    /* look for a port rewrite and remove it if exists */
    if (sl_remove_port(pskb, 
                       ct, 
                       ctinfo, 
                       host_offset, 
                       user_data, 
                       user_data_len)) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nport rewrite removed :8135 successfully\n");
#endif

        return NF_ACCEPT;
    }

    /* ok now attempt to insert the X-SLR header */
    if (!add_sl_header(pskb, 
                       ct, 
                       ctinfo, 
                       user_data, 
                       user_data_len, 
                       host_offset)) {

        printk(KERN_ERR "add_sl_header returned failed\n");
        return NF_ACCEPT; // accept it anyway
    }

    return NF_ACCEPT;
}


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
