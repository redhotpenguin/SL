CREATE TABLE ad_sl (
	ad_sl_id serial NOT NULL,
    ad_id INTEGER NOT NULL,
	text character varying(256),
    uri character varying(512),
    reg_id integer NOT NULL default 1,
    mts timestamp without time zone default now ()
);
 
ALTER TABLE ONLY ad_sl
    ADD CONSTRAINT ad_sl_pkey PRIMARY KEY (ad_sl_id);
 
ALTER TABLE ONLY ad_sl
    ADD CONSTRAINT ad_sl_reg_id_fkey FOREIGN KEY (reg_id) 
	REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY ad_sl
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) 
	REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;
