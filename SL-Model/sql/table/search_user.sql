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
-- Name: search_user; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE search_user (
    search_user_id integer NOT NULL,
    user_agent text NOT NULL,
    uuid text NOT NULL,
    tos integer DEFAULT 0 NOT NULL,
    mts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.search_user OWNER TO phred;

--
-- Name: search_user_search_user_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE search_user_search_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.search_user_search_user_id_seq OWNER TO phred;

--
-- Name: search_user_search_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE search_user_search_user_id_seq OWNED BY search_user.search_user_id;


--
-- Name: search_user_search_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval('search_user_search_user_id_seq', 16, true);


--
-- Name: search_user_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE search_user ALTER COLUMN search_user_id SET DEFAULT nextval('search_user_search_user_id_seq'::regclass);


--
-- Data for Name: search_user; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY search_user (search_user_id, user_agent, uuid, tos, mts) FROM stdin;
13	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.44 Safari/534.7	C8D6C8D8-EBA1-11DF-BC31-FBD625C087E4	1289266676	2010-11-08 17:36:33.673779
14	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12	09335054-EBA2-11DF-8043-C4D725C087E4	1289266710	2010-11-08 17:38:21.654357
15	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.44 Safari/534.7	1DE118EC-F2AF-11DF-9471-4D863BAE503A	1290042156	2010-11-17 16:59:37.978126
16	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; en-US) AppleWebKit/534.7 (KHTML, like Gecko) Chrome/7.0.517.44 Safari/534.7	5F7E0B06-F2B0-11DF-8076-4D863BAE503A	0	2010-11-17 17:08:37.470216
\.


--
-- Name: search_user_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY search_user
    ADD CONSTRAINT search_user_pkey PRIMARY KEY (search_user_id);


--
-- PostgreSQL database dump complete
--

