-- join between reg and ad_group for group membership.  If no join is
-- present then the Default ad group will be used.

CREATE TABLE reg_ad_group (
    reg_id      integer NOT NULL,
    ad_sl_group_id integer NOT NULL
);

ALTER TABLE ONLY reg_ad_group
    ADD CONSTRAINT reg_ad_group_pkey PRIMARY KEY (reg_id, ad_group_id);

ALTER TABLE ONLY reg_ad_group
    ADD CONSTRAINT reg_ad_group_ad_sl_group_id_fkey 
	FOREIGN KEY (ad_sl_group_id) REFERENCES ad_sl_group(ad_sl_group_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY reg_ad_group
    ADD CONSTRAINT reg_ad_group_reg_id_fkey 
	FOREIGN KEY (reg_id) REFERENCES reg(reg_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

