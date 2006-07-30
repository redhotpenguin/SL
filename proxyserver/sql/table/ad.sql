
CREATE TABLE ad (
    ad_id serial NOT NULL,
    name character varying(256),
    "template" character varying(32),
    active boolean DEFAULT false,
    ad_group_id integer NOT NULL default 1,
);

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad_pkey PRIMARY KEY (ad_id);

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad_group_id_fkey FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) ON UPDATE CASCADE ON DELETE CASCADE;
