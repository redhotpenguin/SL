#ifndef _NF_CONNTRACK_SL_H
#define _NF_CONNTRACK_SL_H

#ifdef __KERNEL__

/* enable for module debugging */
#define SL_DEBUG 1

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

struct nf_conntrack_expect;

extern unsigned int (*nf_nat_sl_hook)(
              struct sk_buff **pskb,
              enum ip_conntrack_info ctinfo,
              struct nf_conntrack_expect *exp,
	      unsigned int host_offset,
	      unsigned char *user_data);


#endif /* __KERNEL__ */

#endif /* _NF_CONNTRACK_SL_H */
