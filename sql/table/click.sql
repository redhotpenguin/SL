
CREATE TABLE click (
    click_id serial NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    link_id integer NOT NULL,
	ip inet
);

ALTER TABLE ONLY click
    ADD CONSTRAINT click_pkey PRIMARY KEY (click_id);


ALTER TABLE ONLY click
    ADD CONSTRAINT link_id_fkey FOREIGN KEY (link_id) REFERENCES link(link_id) ON UPDATE CASCADE ON DELETE CASCADE;

