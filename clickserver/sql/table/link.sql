CREATE TABLE link (
    link_id serial NOT NULL,
    ad_id integer NOT NULL,
    uri character varying(512),
    md5 character varying(32)
);


ALTER TABLE ONLY link
    ADD CONSTRAINT link_pkey PRIMARY KEY (link_id);

CREATE TRIGGER md5
    BEFORE INSERT OR UPDATE ON link
    FOR EACH ROW
    EXECUTE PROCEDURE link_md5();

ALTER TABLE ONLY link
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;


