--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: router; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router (
    router_id integer DEFAULT nextval('router_router_id_seq'::regclass) NOT NULL,
    serial_number character(12),
    macaddr macaddr,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true,
    proxy inet,
    replace_port smallint DEFAULT 8135,
    description text,
    name text,
    feed_google boolean DEFAULT false,
    feed_linkshare boolean DEFAULT false,
    splash_timeout integer DEFAULT 60,
    splash_href text DEFAULT ''::text,
    firmware_version character varying(4) DEFAULT ''::character varying,
    ssid text DEFAULT ''::text,
    firmware_event text DEFAULT ''::text,
    ssid_event text DEFAULT ''::text,
    passwd_event text DEFAULT ''::text
);


ALTER TABLE public.router OWNER TO phred;

--
-- Name: router_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router
    ADD CONSTRAINT router_pkey PRIMARY KEY (router_id);


--
-- Name: update_router_mts; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER update_router_mts
    BEFORE UPDATE ON router
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();


--
-- PostgreSQL database dump complete
--

