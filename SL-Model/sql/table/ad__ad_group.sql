CREATE TABLE ad__ad_group (
    ad_id      integer NOT NULL,
    ad_group_id          integer NOT NULL
);

ALTER TABLE ONLY ad__ad_group
    ADD CONSTRAINT ad__ad_group_pkey PRIMARY KEY (ad_id, ad_group_id);

ALTER TABLE ONLY ad__ad_group
    ADD CONSTRAINT ad__ad_group__ad_group_id_fkey 
	FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ad__ad_group
    ADD CONSTRAINT ad__ad_group__ad_id_fkey 
	FOREIGN KEY (ad_id) REFERENCES ad(ad_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

