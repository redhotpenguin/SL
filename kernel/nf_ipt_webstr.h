#ifndef _NF_IPT_WEBSTR_H
#define _NF_IPT_WEBSTR_H

// define the httpinfo struct
struct httpinfo_t {
                // host
		char* host;
		int hostlen;
                
                // url
                char* url;
	        int urllen;
};

typedef struct httpinfo {
    char host[BUFSIZE + 1];
    int hostlen;
    char url[BUFSIZE + 1];
    int urllen;
} httpinfo_t;

extern int find_pattern2(const char*, size_t, const char*, size_t, 
		const char, unsigned int*, unsigned int*);

extern int mangle_http_header(const struct sk_buff *skb, int);

extern int get_http_info(const struct sk_buff *skb, int, 
        const struct httpinfo_t*);

extern char *search_linear(const char*, const char*, int, int);

extern int match(
		const struct sk_buff *skb, 
		struct net_device*, 
		struct net_device*, 
		void*,
		int, 
		void*,
	   	u_int16_t, 
		int*);

extern int checkentry(const char*, const struct ipt_ip*, void*, 
		unsigned int, unsigned int);

#endif
