--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: search_summary; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE search_summary (
    search_summary_id integer NOT NULL,
    searches integer DEFAULT 0 NOT NULL,
    users integer DEFAULT 0 NOT NULL,
    audited boolean DEFAULT false NOT NULL,
    date timestamp with time zone DEFAULT now()
);


ALTER TABLE public.search_summary OWNER TO phred;

--
-- Name: search_summary_search_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE search_summary_search_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.search_summary_search_summary_id_seq OWNER TO phred;

--
-- Name: search_summary_search_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE search_summary_search_summary_id_seq OWNED BY search_summary.search_summary_id;


--
-- Name: search_summary_search_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval('search_summary_search_summary_id_seq', 1, false);


--
-- Name: search_summary_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE search_summary ALTER COLUMN search_summary_id SET DEFAULT nextval('search_summary_search_summary_id_seq'::regclass);


--
-- Data for Name: search_summary; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY search_summary (search_summary_id, searches, users, audited, date) FROM stdin;
\.


--
-- Name: search_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY search_summary
    ADD CONSTRAINT search_summary_pkey PRIMARY KEY (search_summary_id);


--
-- PostgreSQL database dump complete
--

