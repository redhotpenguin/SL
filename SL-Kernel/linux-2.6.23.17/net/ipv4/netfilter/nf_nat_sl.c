/* Base stolen from ip_nat_ftp.c 
   SL extension for TCP NAT alteration.
   Inspiration from http://ftp.gnumonks.org/pub/doc/conntrack+nat.html
   Much initial mentoring from Eveginy Polyakov
   Thanks to Steve Edwards for help making this stuff work
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/textsearch.h>
#include <linux/skbuff.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/netfilter.h>
#include <net/tcp.h>
#include <net/netfilter/nf_nat.h>
#include <net/netfilter/nf_nat_helper.h>
#include <net/netfilter/nf_nat_rule.h>
#include <net/netfilter/nf_conntrack.h>
#include <net/netfilter/nf_conntrack_helper.h>
#include <net/netfilter/nf_conntrack_expect.h>
#include <linux/jhash.h>
#include <linux/netfilter_ipv4/ip_nat_sl_helper.h>

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Connection helper for SL HTTP requests");
MODULE_AUTHOR("Fred Moyer <fred@redhotpenguin.com>");

/* big packet munging is currently broken */
#define BIG_PACKET 0

/* salt for the hashing */
#define JHASH_SALT 420

/* maximum packet length */ 
#define MAX_PACKET_LEN 1480

/* This is calculated anyway but we use it to check for big packets */
#define SL_HEADER_LEN 29

#define MACADDR_SIZE 12

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


static int sl_data_fixup(
              struct nf_conn *ct,
              struct sk_buff **pskb,
              enum   ip_conntrack_info ctinfo,
              struct nf_conntrack_expect *expect )
{

    struct iphdr  *iph = ip_hdr(*pskb);
    struct tcphdr *tcph = (void *)iph + iph->ihl*4;
    unsigned char *user_data;
    int packet_len, user_data_len;
    struct ts_state ts;
    unsigned int host_offset;
    
    /* no ip header is a problem */
    if ( !iph ) return 0;

    packet_len = ntohs(iph->tot_len) - (iph->ihl*4);
    user_data = (void *)tcph + tcph->doff*4;
    user_data_len = (int)((*pskb)->tail -  user_data);

#ifdef SL_DEBUG
    printk(KERN_DEBUG "ip_nat_sl: packet length: %d\n", packet_len);
    printk(KERN_DEBUG "ip_nat_sl: packet user data length: %d\n", user_data_len); 
    printk(KERN_DEBUG "ip_nat_sl: packet check: %s\n", user_data);
#endif
       
    /* see if this is a GET request */
    if (strncmp(get_needle, user_data, GET_NEEDLE_LEN)) {    
#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nno get_needle found in packet\n");
#endif        
        return 0;
    } 

    /* It is a GET request, look for the Host header */    
/*    host_ptr = search_linear( 
        host_needle, 
        &user_data[GET_NEEDLE_LEN], 
        HOST_NEEDLE_LEN, 
        user_data_len - GET_NEEDLE_LEN);
*/

    // offset to the '\r\nHost:' header
    host_offset = skb_find_text(
        *pskb,
        (unsigned int)(&user_data[GET_NEEDLE_LEN]),
        user_data_len - GET_NEEDLE_LEN,
        search[SEARCH_HOST].ts,
	&ts );

    if (host_offset == UINT_MAX) {
#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nno host header found in packet\n");
#endif
        return 0;
    } 

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

static int help(
             struct sk_buff **pskb,
	     unsigned int protoff,
	     struct nf_conntrack_expect *exp,
             enum   ip_conntrack_info ctinfo
        )     
{
    struct iphdr  *iph = ip_hdr(*pskb);
    struct tcphdr *tcph = (void *)iph + iph->ihl*4;
    struct nf_conn *ct = exp->master;
    int plen;

    /* HACK - skip dest port not 80, but allow dev port 9999 */
    if ( ( ntohs(tcph->dest) != SL_PORT ) ||
         ( ntohs(tcph->dest) != SL_DEV_PORT ) ) {
        return 1;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\n\nip_nat_sl: tcphdr dst %d, src %d, ack seq %d\n",
            ntohs(tcph->dest), ntohs(tcph->source), tcph->ack_seq);

    /* let SYN, FIN, RST, PSH, ACK, ECE, CWR, URG packets pass */
    printk(KERN_DEBUG "ip_nat_sl: FIN: %d\n", tcph->fin);
    printk(KERN_DEBUG "ip_nat_sl: SYN: %d\n", tcph->syn);
    printk(KERN_DEBUG "ip_nat_sl: RST: %d\n", tcph->rst);
    printk(KERN_DEBUG "ip_nat_sl: PSH: %d\n", tcph->psh);
    printk(KERN_DEBUG "ip_nat_sl: ACK: %d\n", tcph->ack);
    printk(KERN_DEBUG "ip_nat_sl: URG: %d\n", tcph->urg);
    printk(KERN_DEBUG "ip_nat_sl: ECE: %d\n", tcph->ece);
    printk(KERN_DEBUG "ip_nat_sl: CWR: %d\n", tcph->cwr);
#endif    

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


    /* only work on push or ack packets */
    if (!( (tcph->psh == 1) || (tcph->ack == 1)) ) {
#ifdef SL_DEBUG
        printk(KERN_INFO "ip_nat_sl: psh or ack\n");
#endif    
        return NF_ACCEPT;
    }

    /* get the packet length */
    plen=ntohs(iph->tot_len)-(iph->ihl*4);
#ifdef SL_DEBUG
        printk(KERN_INFO "ip_nat_sl: packet length %d\n", plen);
#endif    

    /* minimum length to search the packet */
    if (plen < MIN_PACKET_LEN) {
#ifdef SL_DEBUG
        printk(KERN_DEBUG "ip_nat_sl: packet too small to examine - %d\n", plen);
#endif    
        return NF_ACCEPT;
    }

    /* wtf does this crap do?
    exp = nf_conntrack_expect_alloc(ctinfo);
    if (exp == NULL) {
        return NF_DROP;
    }
    */

    /* search the packet */
    if (!sl_data_fixup(ct, pskb, ctinfo, exp)) {
#ifdef SL_DEBUG
        printk(KERN_ERR "ip_nat_sl: error sl_data_fixup\n");
#endif
    }
    
#ifdef SL_DEBUG
    printk(KERN_DEBUG "ip_nat_sl: sl_help end, returning nf_accept\n");
#endif    
    return NF_ACCEPT;
}

struct nf_conntrack_helper sl;

static void nf_nat_sl_fini(void)
{
#ifdef SL_DEBUG
    printk(KERN_DEBUG "ip_nat_sl: unregistering for port %d\n", SL_PORT);
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
    printk(KERN_DEBUG "ip_nat_sl: Trying to register for port %d\n", SL_PORT);
#endif

    ret = nf_conntrack_helper_register(&sl);

    if (ret) {

#ifdef SL_DEBUG
        printk(KERN_ERR "ip_nat_sl: error registering helper, port %d\n", SL_PORT);
#endif

        nf_nat_sl_fini();
        return ret;
    }
    return ret;
}

module_init(nf_nat_sl_init);
module_exit(nf_nat_sl_fini);
