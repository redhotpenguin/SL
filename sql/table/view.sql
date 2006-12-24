CREATE TABLE view (
    view_id serial NOT NULL,
    ad_id integer NOT NULL
    ts timestamp without time zone default now(),
    ip inet
);


ALTER TABLE ONLY view
    ADD CONSTRAINT view_pkey PRIMARY KEY (view_id);

ALTER TABLE ONLY view
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;


