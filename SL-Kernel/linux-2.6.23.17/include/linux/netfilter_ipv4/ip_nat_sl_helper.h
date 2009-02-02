#ifndef _NF_NAT_SL_HELPER_H
#define _NF_NAT_SL_HELPER_H

#define xSL_DEBUG

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

static int sl_remove_port(
                struct sk_buff **pskb,
                struct nf_conn *ct,
                enum   ip_conntrack_info ctinfo,
                char   *host_ptr,
                char   *user_data,
                int    user_data_len )
{

    struct ts_state ts;
    char *port_ptr;
    unsigned int match_offset, match_len;
    unsigned int packet_start;

   /* Temporarily use match_len for the data length to be searched*/

    match_len =  (unsigned int)(user_data_len
                       - (int)(host_ptr - user_data)
                       - (HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN));

//    packet_start = (unsigned int)((void *)tcph + tcph->doff*4);
    memset(&ts, 0, sizeof(ts));
    port_ptr = skb_find_text(
                 *pskb,
  //                packet_start+HOST_NEEDLE_LEN+CRLF_NEEDLE_LEN,
 (unsigned int)(&host_ptr[HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN]),
                 match_len,
                 search[0].ts,
                 &ts );
/*
    port_ptr = search_linear(
                    port_needle,
                    &host_ptr[HOST_NEEDLE_LEN + CRLF_NEEDLE_LEN],
                    PORT_NEEDLE_LEN, 
                    (int)match_len);
*/
    if (port_ptr == NULL) {
#ifdef SL_DEBUG
        printk(KERN_DEBUG "\nno port rewrite found in packet\n");
#endif
        return 0;
    }

    match_offset = (unsigned int)(port_ptr - user_data);
    match_len    = (unsigned int)((char *)(*pskb)->tail - port_ptr);

#ifdef SL_DEBUG
    printk(KERN_DEBUG "\nmatch_len: %d\n", match_len);
    printk(KERN_DEBUG "match_offset: %d\n", match_offset);
#endif

    /* remove the port */
    if (!nf_nat_mangle_tcp_packet( 
                pskb, ct, ctinfo,
                match_offset,
                match_len,
                &port_ptr[PORT_NEEDLE_LEN],
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

#endif
