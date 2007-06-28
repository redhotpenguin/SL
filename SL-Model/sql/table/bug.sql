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
-- Name: reg; Type: TABLE; Schema: public; Owner: fred; Tablespace: 
--

CREATE TABLE bug (
    bug_id SERIAL NOT NULL,
    image_href text default 'http://www.redhotpenguin.com/images/sl/free_wireless.gif' NOT NULL,
    link_href text default 'http://64.151.90.20:81/click/795da10ca01f942fd85157d8be9e832e',
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY bug
    ADD CONSTRAINT bug_pkey PRIMARY KEY (bug_id);
