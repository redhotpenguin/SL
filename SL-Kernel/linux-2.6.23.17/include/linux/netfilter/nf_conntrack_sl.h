#ifndef _NF_CONNTRACK_SL_H
#define _NF_CONNTRACK_SL_H

#ifdef __KERNEL__

/* enable for module debugging */
//define xSL_DEBUG

/* packets must be on port 80 to have fun */
#define SL_PORT 80

// developers can have fun too.  one line comments are //, multi are /* */
#define SL_DEV_PORT 9999

/* packets must have this much data to go on the ride */
#define MIN_PACKET_LEN 216

/* needle for GET */
#define GET_NEEDLE_LEN 5
// static char get_needle[GET_NEEDLE_LEN+1] = "GET /";

/* needle for host header */
#define HOST_NEEDLE_LEN 7

/* the removal string for the port */
#define PORT_NEEDLE_LEN 5

#define CRLF_NEEDLE_LEN 2

enum sl_strings {
	SEARCH_PORT,
   	SEARCH_HOST,
	SEARCH_GET,
	SEARCH_CRLF,
};

static struct {
        char                    *string;
        size_t                  len;
        struct ts_config        *ts;
} search[] = {
        [SEARCH_PORT] = {
                .string = ":8135",
                .len    = 5,
        },
        [SEARCH_HOST] = {
                .string = "\r\nHost:",
                .len    = 7,
        },
        [SEARCH_GET] = {
                .string = "GET /",
                .len    = 5,
        },
        [SEARCH_CRLF] = {
                .string = "\r\n",
                .len    = 4,
        },
};

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
    //    char *port_ptr;
    unsigned int match_offset, match_len, port_offset;

   /* Temporarily use match_len for the data length to be searched */
    match_len =  (unsigned int)(
                     user_data_len - host_offset 
		     - (unsigned int)(user_data)
                     - (HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN)
    );

    // zero out textsearch state
    memset(&ts, 0, sizeof(ts));

    // get the offset to the location of the port string ':8135'
    port_offset = skb_find_text(
                 *pskb,
		 // start looking after '\r\nHost:'
		 host_offset + HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN,
		 // (unsigned int)(&host_ptr[HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN]),
		 match_len,
                 search[SEARCH_PORT].ts,
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
    if (!nf_nat_mangle_tcp_packet( 
                pskb, ct, ctinfo,
                match_offset,
                match_len,
                &user_data[match_offset],
                match_len - PORT_NEEDLE_LEN ) )  {
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

struct nf_conntrack_expect;

extern unsigned int (*nf_nat_sl_hook)(
              struct sk_buff **pskb,
              enum ip_conntrack_info ctinfo,
              struct nf_conntrack_expect *exp,
	      unsigned int host_offset,
	      unsigned char *user_data);


#endif /* __KERNEL__ */

#endif /* _NF_CONNTRACK_SL_H */
