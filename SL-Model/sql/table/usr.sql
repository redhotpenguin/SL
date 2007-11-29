-- PostgreSQL database dump
--
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: reg; Type: TABLE; Schema: public; Owner: fred; Tablespace: 
--

CREATE TABLE usr (
    usr_id SERIAL NOT NULL,
    hash_mac text NOT NULL default 'ffffff',
    cts timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY usr
    ADD CONSTRAINT usr_pkey PRIMARY KEY (usr_id);
