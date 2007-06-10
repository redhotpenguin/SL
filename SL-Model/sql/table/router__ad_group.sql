CREATE TABLE router_ad_group (
    router_id      integer NOT NULL,
    ad_group_id          integer NOT NULL
);

ALTER TABLE ONLY router_ad_group
    ADD CONSTRAINT router_ad_group_pkey PRIMARY KEY (router_id, ad_group_id);

ALTER TABLE ONLY router_ad_group
    ADD CONSTRAINT router_ad_id_fkey 
	FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY router_ad_group
    ADD CONSTRAINT router_id_fkey 
	FOREIGN KEY (router_id) REFERENCES router(router_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

