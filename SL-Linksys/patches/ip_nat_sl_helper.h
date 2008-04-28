#ifndef _IP_NAT_SL_HELPER_H
#define _IP_NAT_SL_HELPER_H

#define SL_DEBUG 1

/* packets must be on port 80 to have fun */
#define SL_PORT 80

/* packets must have this much data to go on the ride */
#define MIN_PACKET_LEN 216

/* needle for GET */
#define GET_NEEDLE_LEN 5
static char get_needle[GET_NEEDLE_LEN+1] = "GET /";

/* needle for host header */
#define HOST_NEEDLE_LEN 7
static char host_needle[HOST_NEEDLE_LEN+1] = "\r\nHost:";

/* the removal string for the port */
#define PORT_NEEDLE_LEN 5
static char port_needle[PORT_NEEDLE_LEN+1] = ":8135";

#define CRLF_NEEDLE_LEN 2

static int sl_remove_port(
                struct sk_buff **skb,
				struct ip_conntrack *ct,
				enum   ip_conntrack_info ctinfo,
				char   *host_ptr,
				char   *user_data,
				int    user_data_len ) {

    char *port_ptr = NULL;
    unsigned int match_offset = 0;
    unsigned int match_len = 0;
    
    port_ptr = search_linear(
                    port_needle,
                    &host_ptr[HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN],
                    PORT_NEEDLE_LEN,
                    user_data_len
                    - (int)((char *)host_ptr - (char *)user_data)
                    - (HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN)  );

    if (port_ptr == NULL) {
#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nno port rewrite found in packet\n");
#endif
        return 0;
    }

    match_offset = (int)((char *)port_ptr - (char *)user_data);
    match_len    = (int)((char *)(*skb)->tail - (char *)port_ptr);

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nmatch_len: %d\n", match_len);
    printk(KERN_DEBUG "match_offset: %d\n", match_offset);
#endif

    /* remove the port */
    if (!ip_nat_mangle_tcp_packet( 
                skb, ct, ctinfo,
                match_offset,
                match_len,
                &port_ptr[PORT_NEEDLE_LEN],
                match_len - PORT_NEEDLE_LEN ) )  {
#ifdef SL_DEBUG
        printk(KERN_ERR "unable to remove port needle\n");
#endif
        return 1;
    }

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nport needle removed ok\n");
#endif

   return 1; 
}

#endif
