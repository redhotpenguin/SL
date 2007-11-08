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

CREATE TABLE router (
    router_id SERIAL NOT NULL,
    serial_number character(12) DEFAULT '' NOT NULL,
    macaddr macaddr,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean default 't',
    proxy inet,
    replace_port smallint default 8135,
    description text default '',
    name text default '',
    feed_linkshare boolean default 'f',
    feed_google boolean default 'f',
    splash_href text default '',
    splash_timeout integer default 60
);

ALTER TABLE ONLY router
    ADD CONSTRAINT router_pkey PRIMARY KEY (router_id);

