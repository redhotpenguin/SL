/* test module for connection tracking. */

#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/netfilter.h>
#include <linux/ip.h>
#include <linux/ctype.h>
#include <linux/inet.h>
#include <net/checksum.h>
#include <net/tcp.h>

#include <net/netfilter/nf_nat_helper.h>
#include <net/netfilter/nf_conntrack.h>
#include <net/netfilter/nf_conntrack_expect.h>
#include <net/netfilter/nf_conntrack_helper.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Fred Moyer <fred@redhotpenguin.com");
MODULE_DESCRIPTION("test module");


unsigned int (*nf_nat_sl_hook)(struct sk_buff **pskb,
                               enum ip_conntrack_info ctinfo,
                               struct nf_conntrack_expect *exp );
EXPORT_SYMBOL_GPL(nf_nat_sl_hook);

static int help (
             struct sk_buff **pskb,
	     unsigned int protoff,
	     struct nf_conn *ct,
             enum   ip_conntrack_info ctinfo)     
{

	     printk(KERN_DEBUG "test entry point %d\n", 1);
	
             return NF_ACCEPT;
}

// struct nf_conntrack_helper sl;
static struct nf_conntrack_helper sl_helper __read_mostly = {
		.name			= "sl",
		.max_expected           = 1,
		.timeout                = 60,
		.tuple 	= {
			.src.l3num	= AF_INET,
			.dst.protonum   = IPPROTO_TCP,
			.dst.u.tcp.port = __constant_htons(80),
		},
		.me			= THIS_MODULE,
		.help			= help,
};
  

/* don't make this __exit, since it's called from __init ! */
static void nf_conntrack_sl_fini(void)
{
	printk(KERN_DEBUG "unregistering test module\n");

        nf_conntrack_helper_unregister(&sl_helper); 
}

static int __init nf_conntrack_sl_init(void)
{
 
	int ret = 0;

    printk(KERN_DEBUG "Trying to register test module\n");

    ret = nf_conntrack_helper_register(&sl_helper);

    printk(KERN_DEBUG "conntrack register returned: %d\n", ret);

    if (ret) {

        printk(KERN_ERR "error registering helper\n");
        nf_conntrack_sl_fini();
        return ret;
    }

    printk(KERN_DEBUG "conntrack_helper registered OK\n");
	
    printk("test module  pf: %d port %d\n",
		sl_helper.tuple.src.l3num,
		sl_helper.tuple.dst.u.tcp.port );
	

    return ret;
}

module_init(nf_conntrack_sl_init);
module_exit(nf_conntrack_sl_fini);
