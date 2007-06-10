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
    ip inet NOT NULL,
    serial_number character(12),
    macaddr macaddr,
    name character varying(128),
    description text,
    street_addr character varying(64),
    apt_suite character varying(5),
    referer character varying(32),
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean default 't',
    code integer,
    custom_rate_limit character varying(10)
);

ALTER TABLE ONLY router
    ADD CONSTRAINT router_pkey PRIMARY KEY (router_id);