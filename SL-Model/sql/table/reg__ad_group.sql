CREATE TABLE reg__ad_group (
    reg_id      integer NOT NULL,
    ad_group_id          integer NOT NULL
);

ALTER TABLE ONLY reg__ad_group
    ADD CONSTRAINT reg__ad_group_pkey PRIMARY KEY (reg_id, ad_group_id);

ALTER TABLE ONLY reg__ad_group
    ADD CONSTRAINT reg__ad_group__ad_group_id_fkey 
	FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY reg__ad_group
    ADD CONSTRAINT reg__ad_group__reg_id_fkey 
	FOREIGN KEY (reg_id) REFERENCES reg(reg_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

