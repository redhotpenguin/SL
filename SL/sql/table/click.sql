
CREATE TABLE click (
    click_id serial NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    ad_id integer NOT NULL,
	ip inet
);

ALTER TABLE ONLY click
    ADD CONSTRAINT click_pkey PRIMARY KEY (click_id);


ALTER TABLE ONLY click
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;

