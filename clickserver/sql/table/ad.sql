
CREATE TABLE ad (
    ad_id serial NOT NULL,
    name character varying(256),
    "template" character varying(32)
);

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad_pkey PRIMARY KEY (ad_id);

