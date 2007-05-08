
CREATE TABLE forgot (
    forgot_id serial NOT NULL,
    reg_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    link_md5 character varying(32) NOT NULL,
    expired boolean default false
);

ALTER TABLE ONLY forgot
    ADD CONSTRAINT forgot_pkey PRIMARY KEY (forgot_id);

ALTER TABLE ONLY forgot
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TRIGGER forgot_md5
    BEFORE INSERT ON forgot
    FOR EACH ROW
    EXECUTE PROCEDURE forgot_md5(); 