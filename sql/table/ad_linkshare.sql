CREATE TABLE ad_linkshare (
    ad_linkshare_id serial NOT NULL,
    ad_id INTEGER NOT NULL,
	mname varchar(128) NOT NULL,
	mid integer NOT NULL,
	linkid integer NOT NULL,
	linkname varchar(128),
	linkurl varchar(256),
	trackurl varchar(256),
	category varchar(64),
    displaytext varchar(256)
);

ALTER TABLE ONLY ad_linkshare
    ADD CONSTRAINT ad_linkshare_pkey PRIMARY KEY (ad_linkshare_id);

ALTER TABLE ONLY ad_linkshare
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) 
	REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;
