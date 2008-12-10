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
-- Name: client; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE client (
    mac macaddr NOT NULL,
    kbytes_down integer DEFAULT 0 NOT NULL,
    kbytes_up integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.client OWNER TO phred;

--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY client (mac, kbytes_down, kbytes_up) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

