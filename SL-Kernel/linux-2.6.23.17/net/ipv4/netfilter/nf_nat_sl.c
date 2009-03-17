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

module_param(ts_algo, charp, 0400);
MODULE_PARM_DESC(ts_algo, "textsearch algorithm to use (default kmp)");

/* removes :8135 from the host name */

static int sl_remove_port(struct sk_buff **pskb,
		          struct nf_conn *ct,
                	  enum   ip_conntrack_info ctinfo,
                	  unsigned int host_offset,
                	  unsigned int dataoff,
                	  unsigned int datalen,
			  unsigned char *user_data)
{

    struct ts_state ts;
    unsigned int port_offset, start_offset, stop_offset;

    start_offset = host_offset;
    //stop_offset  = datalen - host_offset;
    stop_offset  = host_offset+64;


#ifdef SL_DEBUG
    printk(KERN_DEBUG "searching for port start_offset %u, stop_offset %u\n",
		start_offset, stop_offset);

	if (start_offset > stop_offset) {
		printk(KERN_ERR "invalid stop offset, return\n");
		return 1;
	}

	printk(KERN_DEBUG "packet dump:%s\n",
		(unsigned char *)((unsigned int)user_data+host_offset));

	if (search[PORT].ts == NULL)  {
		printk(KERN_DEBUG "search pointer UNINITIZALIED\n");
	} else {
		printk(KERN_DEBUG "search pointer ok\n");
	}
//	return 1;
#endif


    // get the offset to the location of the port string ':8135'
    memset(&ts, 0, sizeof(ts));
    port_offset = skb_find_text(*pskb,
                                // start looking after '\r\nHost:'
				start_offset,
				stop_offset,
				search[PORT].ts, &ts );
	

    // no port needle found
    if (port_offset == UINT_MAX) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "no port rewrite found in packet\n");
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
				  unsigned int datalen,
				  unsigned char *user_data)
{                      
       
    struct ts_state ts;
    struct ethhdr *bigmac;
    unsigned int jhashed, slheader_len, end_of_host;
    char dst_string[MACADDR_SIZE], src_string[MACADDR_SIZE], slheader[SL_HEADER_LEN];
    bigmac = eth_hdr(*pskb);

    /* first make sure there is room */
    if ( (*pskb)->len >= ( MAX_PACKET_LEN - SL_HEADER_LEN ) ) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "packet too large for sl_header, length: %d\n", (*pskb)->len);
#endif
        return 0;
    }

    /* create the X-SLR Header */        
#ifdef SL_DEBUG
    printk(KERN_DEBUG "source mac found: %02x%02x%02x%02x%02x%02x\n",
            bigmac->h_source[0],
            bigmac->h_source[1],
            bigmac->h_source[2],
            bigmac->h_source[3],
            bigmac->h_source[4],
            bigmac->h_source[5]);

    printk(KERN_DEBUG "dest mac found: %02x%02x%02x%02x%02x%02x\n",
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
   if (slheader_len != SL_HEADER_LEN) {
        printk(KERN_ERR "expected header len %d doesn't match calculated len %d\n",
               SL_HEADER_LEN, slheader_len );
        return 0;
    }


#ifdef SL_DEBUG
    printk(KERN_DEBUG "slheader %s, length %d\n", slheader, slheader_len);
    printk(KERN_DEBUG "looking for end of host, start %u\n", host_offset);
#endif        

    // scan to the end of the host header
    end_of_host=host_offset;
    while ( ++end_of_host < (host_offset+64) ) {
	if (!strncmp(search[NEWLINE].string, &user_data[end_of_host],
		search[NEWLINE].len))
	    break;
    } 
/*

    memset(&ts, 0, sizeof(ts));
    end_of_host = skb_find_text(*pskb, host_offset+search[NEWLINE].len, host_offset+64,
				search[NEWLINE].ts, &ts );
*/	
    //if (end_of_host == UINT_MAX) {
    if (end_of_host == (host_offset+63)) {
        printk(KERN_ERR "host header present but does not terminate\n");
	return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "looking for end of host, end %u\n", end_of_host);
    printk(KERN_DEBUG "packet dump:%s\n",
		(unsigned char *)((unsigned int)user_data+host_offset+end_of_host));
#endif        
    
    /********************************************/
    /* insert the slheader into the http headers */
    if (!nf_nat_mangle_tcp_packet( pskb,
                                   ct, 
                                   ctinfo,
                                   end_of_host + search[NEWLINE].len,
                                   0, 
                                   slheader,
                                   slheader_len)) {  

        printk(KERN_ERR " failed to mangle packet\n");
	return 0;
    }

#ifdef SL_DEBUG
        printk(KERN_DEBUG "packet mangled ok:%s\n",
		(unsigned char *)((unsigned int)user_data));
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
                              unsigned int datalen,
			      unsigned char *user_data)
{
    struct nf_conn *ct = exp->master;

    /* look for a port rewrite and remove it if exists */
    if (sl_remove_port(pskb, 
                       ct, 
                       ctinfo, 
                       host_offset, 
                       dataoff, 
                       datalen,
		       user_data)) {

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
                       datalen,
		       user_data))
    {

#ifdef SL_DEBUG
        printk(KERN_ERR "add_sl_header returned not added\n");
#endif
    }

    return NF_ACCEPT;
}


static void nf_nat_sl_fini(void)
{
	
	rcu_assign_pointer(nf_nat_sl_hook, NULL);
	synchronize_rcu();
/*
	for (i = 0; i < ARRAY_SIZE(search); i++)
	{
		if (search[i].ts != NULL)
			textsearch_destroy(search[i].ts);
	} */
}

static int __init nf_nat_sl_init(void)
{
	int ret=0;
	int i;

	BUG_ON(rcu_dereference(nf_nat_sl_hook));
	rcu_assign_pointer(nf_nat_sl_hook, nf_nat_sl);

	// setup CRLF and PORT
	for (i = 1; i < ARRAY_SIZE(search); i++) {
		search[i].ts = textsearch_prepare(ts_algo, search[i].string,
						  search[i].len,
						  GFP_KERNEL, TS_AUTOLOAD);
		if (IS_ERR(search[i].ts)) {
			ret = PTR_ERR(search[i].ts);
			goto err;
		}
		printk(KERN_DEBUG "text search id %d setup ok\n", i);
	}

	return ret;

err:
	while (--i >= 1) {
		textsearch_destroy(search[i].ts);
	}

	return ret;
}

module_init(nf_nat_sl_init);
module_exit(nf_nat_sl_fini);
