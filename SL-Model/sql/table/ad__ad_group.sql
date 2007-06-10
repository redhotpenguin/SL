CREATE TABLE ad_ad_group (
    ad_id      integer NOT NULL,
    ad_group_id          integer NOT NULL
);

ALTER TABLE ONLY ad_ad_group
    ADD CONSTRAINT ad_ad_group_pkey PRIMARY KEY (ad_id, ad_group_id);

ALTER TABLE ONLY ad_ad_group
    ADD CONSTRAINT ad_ad_id_fkey 
	FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ad_ad_group
    ADD CONSTRAINT ad_id_fkey 
	FOREIGN KEY (ad_id) REFERENCES ad(ad_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

