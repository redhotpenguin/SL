CREATE TABLE account__ad_zone (
    account_id      integer NOT NULL,
    ad_zone_id          integer NOT NULL
);

ALTER TABLE ONLY account__ad_zone
    ADD CONSTRAINT account__ad_zone_pkey PRIMARY KEY (account_id, ad_zone_id);

ALTER TABLE ONLY account__ad_zone
    ADD CONSTRAINT account__ad_zone__ad_zone_id_fkey 
	FOREIGN KEY (ad_zone_id) REFERENCES ad_zone(ad_zone_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY account__ad_zone
    ADD CONSTRAINT account__ad_zone__account_id_fkey 
	FOREIGN KEY (account_id) REFERENCES account(account_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

