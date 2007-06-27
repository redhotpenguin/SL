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

CREATE TABLE location (
    location_id SERIAL NOT NULL,
    ip inet NOT NULL,
    name text DEFAULT '' NOT NULL,
    description text DEFAULT '' NOT NULL,
    street_addr character varying(64),
    apt_suite character varying(5),
    zip varchar(9),
    city varchar(128),
    state varchar(2),
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean default 't',
    default_ok boolean default 't',
    custom_rate_limit character varying(10)
);

ALTER TABLE ONLY location
    ADD CONSTRAINT location_pkey PRIMARY KEY (location_id);

