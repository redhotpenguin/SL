--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: account; Type: TABLE; Schema: public; Owner: fred; Tablespace: 
--

CREATE TABLE bug (
    bug_id SERIAL NOT NULL,
    image_href text NOT NULL,
    link_href text NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    account_id INTEGER NOT NULL,
    ad_size_id INTEGER NOT NULL
);

ALTER TABLE ONLY bug
    ADD CONSTRAINT bug_pkey PRIMARY KEY (bug_id);

ALTER TABLE ONLY bug
    ADD CONSTRAINT bug__account_id_fkey 
	FOREIGN KEY (account_id) REFERENCES account(account_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY bug
    ADD CONSTRAINT bug__ad_size_id_fkey 
	FOREIGN KEY (ad_size_id) REFERENCES ad_size(ad_size_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;
