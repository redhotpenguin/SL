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

    unsigned int  end_of_host;

    // scan to the end of the host header
    end_of_host=host_offset;
    while ( ++(end_of_host) < (host_offset+HOST_SEARCH_LEN) ) {
	if (!strncmp(search[NEWLINE].string, &user_data[end_of_host],
		search[NEWLINE].len))
	    break;
    } 

    if (end_of_host == (host_offset+HOST_SEARCH_LEN-1)) {
	// host header is split between two packets?
        printk(KERN_ERR "host header not found in search\n");
	return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "found end_of_host %u\n", end_of_host);
    printk(KERN_DEBUG "packet dump:%s\n",
		(unsigned char *)((unsigned int)user_data+end_of_host));
#endif        

    
   // ok we have end of host, look for the port string
    if (strncmp(search[PORT].string, 
	&user_data[end_of_host-search[PORT].len+search[NEWLINE].len],
	search[PORT].len)) {

#ifdef SL_DEBUG
        printk(KERN_DEBUG "no port rewrite found in packet strncmp\n");
	printk(KERN_DEBUG "packet dump:%s\n",
		(unsigned char *)((unsigned int)user_data+end_of_host-search[PORT].len+search[NEWLINE].len));
#endif
	return end_of_host;
    }


#ifdef SL_DEBUG
    printk(KERN_DEBUG "remove_port found a port at offset %u\n",
	end_of_host-search[PORT].len+search[NEWLINE].len );
#endif

    /* remove the port */
    if (!nf_nat_mangle_tcp_packet(pskb, ct, ctinfo,
        end_of_host-search[PORT].len+search[NEWLINE].len,
        search[PORT].len-(search[NEWLINE].len*2), // subtract \r\n
	NULL,
	0))
    {
        printk(KERN_ERR "unable to remove port needle\n");
	// we've already found the port, so we return 1 regardless
        return 0;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "port removed ok, new packet\n%s\n",
	(unsigned char *)user_data);

#endif

    return 1; 
}


static unsigned int add_sl_header(struct sk_buff **pskb,
                                  struct nf_conn *ct, 
                                  enum ip_conntrack_info ctinfo,
				  unsigned int host_offset, 
				  unsigned int dataoff, 
				  unsigned int datalen,
				  unsigned char *user_data,
				  unsigned int end_of_host)
{                      
       
//    struct ts_state ts;
    unsigned int jhashed, slheader_len;
    char dst_string[MACADDR_SIZE], src_string[MACADDR_SIZE], slheader[SL_HEADER_LEN];
    struct ethhdr *bigmac = eth_hdr(*pskb);

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
    unsigned int port_status;

    /* look for a port rewrite and remove it if exists */
    port_status = sl_remove_port(pskb, ct, ctinfo, 
                       host_offset, dataoff, 
                       datalen, user_data );

    if (!port_status) {
	// an error occurred which means this packet cannot be changed
	return NF_ACCEPT;
    } else if (port_status == 1) {
	// port was found and removed
#ifdef SL_DEBUG
        printk(KERN_DEBUG "port rewrite removed :8135 successfully\n\n");
#endif
	return NF_ACCEPT;
    } else if (port_status > 1) {
	// port was not found but a host header was found in range
#ifdef SL_DEBUG
        printk(KERN_DEBUG "no :8135, but host header %u found\n", port_status);
#endif
    }

    /* ok now attempt to insert the X-SLR header */
    if (!add_sl_header(pskb, 
                       ct, 
                       ctinfo, 
                       host_offset, 
                       dataoff, 
                       datalen,
		       user_data,
		       port_status))
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
}

static int __init nf_nat_sl_init(void)
{
	int ret=0;

	BUG_ON(rcu_dereference(nf_nat_sl_hook));
	rcu_assign_pointer(nf_nat_sl_hook, nf_nat_sl);

	// setup text search
	search[PORT].ts = textsearch_prepare(ts_algo, search[PORT].string,
					     search[PORT].len,
				             GFP_KERNEL, TS_AUTOLOAD);

		if (IS_ERR(search[PORT].ts)) {
			ret = PTR_ERR(search[PORT].ts);
			goto err;
	}

	return ret;

err:
	textsearch_destroy(search[PORT].ts);

	return ret;
}

module_init(nf_nat_sl_init);
module_exit(nf_nat_sl_fini);
