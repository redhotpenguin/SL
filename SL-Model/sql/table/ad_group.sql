CREATE TABLE ad_group (
    ad_group_id serial NOT NULL,
	active boolean DEFAULT true,
    name character varying(256),
    cts timestamp without time zone default now ()
);

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group_pkey PRIMARY KEY (ad_group_id);
