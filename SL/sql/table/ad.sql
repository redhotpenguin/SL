CREATE TABLE ad (
    ad_id serial NOT NULL,
	active boolean DEFAULT false,
    md5 character varying(32),
    cts timestamp without time zone default now ()
);

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad_pkey PRIMARY KEY (ad_id);
