CREATE TABLE router_ad_sl (
    router_id      integer NOT NULL,
    ad_sl_id          integer NOT NULL
);

ALTER TABLE ONLY router_ad_sl
    ADD CONSTRAINT router_ad_sl_pkey PRIMARY KEY (router_id, ad_sl_id);

ALTER TABLE ONLY router_ad_sl
    ADD CONSTRAINT router_ad_id_fkey 
	FOREIGN KEY (ad_sl_id) REFERENCES ad_sl(ad_sl_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY router_ad_sl
    ADD CONSTRAINT router_id_fkey 
	FOREIGN KEY (router_id) REFERENCES router(router_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

