CREATE TABLE location__ad_group (
    location_id      integer NOT NULL,
    ad_group_id          integer NOT NULL
);

ALTER TABLE ONLY location__ad_group
    ADD CONSTRAINT location__ad_group__pkey PRIMARY KEY (location_id, ad_group_id);

ALTER TABLE ONLY location__ad_group
    ADD CONSTRAINT location__ad_group__ad_group_id_fkey 
	FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY location__ad_group
    ADD CONSTRAINT location__ad_group__location_id_fkey 
	FOREIGN KEY (location_id) REFERENCES location(location_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

