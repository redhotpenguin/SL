CREATE TABLE ad (
    ad_id serial NOT NULL,
    ad_group_id INTEGER NOT NULL DEFAULT 1,
	active boolean DEFAULT false,
    md5 character varying(32),
    cts timestamp without time zone default now ()
);

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad_pkey PRIMARY KEY (ad_id);


ALTER TABLE ONLY ad
    ADD CONSTRAINT ad__ad_group_id_fkey FOREIGN KEY (ad_group_id) 
    REFERENCES ad_group(ad_group_id) ON UPDATE CASCADE ON DELETE CASCADE;

