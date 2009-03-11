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

static int sl_remove_port(struct sk_buff **pskb,
		          struct nf_conn *ct,
                	  enum   ip_conntrack_info ctinfo,
                	  unsigned int host_offset,
                	  unsigned int dataoff,
                	  unsigned int datalen)
{

    struct ts_state ts;
    unsigned int port_offset;

    // zero out textsearch state
    memset(&ts, 0, sizeof(ts));

    // get the offset to the location of the port string ':8135'
    port_offset = skb_find_text(*pskb,
                                // start looking after '\r\nHost:'
				host_offset + search[HOST].len,
				// search the remainder of the packet data
                                datalen - ( host_offset - dataoff + search[HOST].len ),
				search[PORT].ts, &ts );
	

    // no port needle found
    if (port_offset == UINT_MAX) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nno port rewrite found in packet\n");
#endif

        return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "remove_port found a port at offset %u\n", port_offset );
#endif

    /* remove the port */
    if (!nf_nat_mangle_tcp_packet(pskb, 
                                  ct, 
                                  ctinfo,
                                  port_offset,
                                  search[PORT].len,
				  (unsigned char *)(port_offset+search[PORT].len),
				  (datalen-(port_offset-dataoff+search[PORT].len))) )
    {
#ifdef SL_DEBUG
        printk(KERN_ERR "unable to remove port needle\n");
#endif
	// we've already found the port, so we return 1 whether it is removed or not
        return 1;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "port needle removed ok\n");
#endif

    return 1; 
}


static unsigned int add_sl_header(struct sk_buff **pskb,
                                  struct nf_conn *ct, 
                                  enum ip_conntrack_info ctinfo,
				  unsigned int host_offset,                      
				  unsigned int dataoff, 
				  unsigned int datalen)
{                      
       
    struct ts_state ts;
    struct ethhdr *bigmac;
    unsigned int jhashed, slheader_len, end_of_host;
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
        printk(KERN_ERR "sprintf fail for slheader\n");
        return 0;
    } 

#ifdef SL_DEBUG
    printk(KERN_DEBUG "slheader %s, length %d\n", slheader, slheader_len);
#endif        

    if (slheader_len != SL_HEADER_LEN) {
        printk(KERN_ERR "expected header len %d doesn't match calculated len %d\n",
               SL_HEADER_LEN, slheader_len );
    }



    /********************************************/
    // now insert the sl header
    // scan to the end of the host header
    end_of_host = skb_find_text(*pskb, 
				// start search \r\nHost: + \r\n from host header
			  	host_offset + search[HOST].len + search[CRLF].len,
				// search the remainder of the packet data
                                datalen - ( host_offset - dataoff +
					search[HOST].len +search[CRLF].len ),

				search[CRLF].ts, &ts );
	

    if (end_of_host == UINT_MAX) {
        printk(KERN_ERR "host header present but does not terminate\n");
	return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "end_of_host %u\n", end_of_host);
#endif        

    /* insert the slheader into the http headers */
    if (!nf_nat_mangle_tcp_packet( pskb,
                                   ct, 
                                   ctinfo,
                                   end_of_host + search[CRLF].len,
                                   0, 
                                   slheader,
                                   slheader_len)) {  

        printk(KERN_ERR " failed to mangle packet\n");
        return 0;
    }

#ifdef SL_DEBUG
        printk(KERN_DEBUG "\npacket mangled ok: %s\n\n", (char *)(dataoff) );
#endif        

    return 1;
}


/* So, this packet has hit the connection tracking matching code.
   Mangle it, and change the expectation to match the new version. */
static unsigned int nf_nat_sl(struct sk_buff **pskb,
                              enum ip_conntrack_info ctinfo,
                              struct nf_conntrack_expect *exp,
                              unsigned int host_offset,
                              unsigned int dataoff,
                              unsigned int datalen)
{
    struct nf_conn *ct = exp->master;
    
    /* look for a port rewrite and remove it if exists */
    if (sl_remove_port(pskb, 
                       ct, 
                       ctinfo, 
                       host_offset, 
                       dataoff, 
                       datalen)) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nport rewrite removed :8135 successfully\n");
#endif

        return NF_ACCEPT;
    }

    /* ok now attempt to insert the X-SLR header */
    if (!add_sl_header(pskb, 
                       ct, 
                       ctinfo, 
                       host_offset, 
                       dataoff, 
                       datalen))
    {

        printk(KERN_ERR "add_sl_header returned failed\n");
        return NF_ACCEPT; // accept it anyway, what else can we do?
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
