#ifndef _NF_CONNTRACK_SL_H
#define _NF_CONNTRACK_SL_H

#ifdef __KERNEL__

/* enable for module debugging */
#define SL_DEBUG 1

/* packets must be on port 80 to have fun */
#define SL_PORT 80

/* packets must have this much data to go on the ride */
#define MIN_PACKET_LEN 216

/* length of SL header
   X-SLR: 9db44d24|0013102d6976\r\n */
#define SL_HEADER_LEN 30

/* salt for the hashing */
#define JHASH_SALT 420

/* maximum packet length */ 
#define MAX_PACKET_LEN 1480

/* length of the mac address */
#define MACADDR_SIZE 12


enum sl_strings {
	PORT,
   	HOST,
	GET,
	CRLF,
};

static struct {
        char                    *string;
        size_t                  len;
        struct ts_config        *ts;
} search[] = {
        [PORT] = {
                .string = ":8135",
                .len    = 5,
        },
        [HOST] = {
                .string = "\r\nHost:",
                .len    = 7,
        },
        [GET] = {
                .string = "GET /",
                .len    = 5,
        },
        [CRLF] = {
                .string = "\r\n",
                .len    = 4,
        },
};

struct nf_conntrack_expect;

extern unsigned int (*nf_nat_sl_hook)(struct sk_buff **pskb,
                                      enum ip_conntrack_info ctinfo,
                                      struct nf_conntrack_expect *exp,
                                      unsigned int host_offset,
                                      unsigned char *user_data);


#endif /* __KERNEL__ */

#endif /* _NF_CONNTRACK_SL_H */
