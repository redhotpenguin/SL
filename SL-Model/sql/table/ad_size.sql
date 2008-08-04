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
-- Name: ad_size; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_size (
    ad_size_id integer NOT NULL,
    name text,
    height integer NOT NULL,
    width integer NOT NULL,
    css_url text NOT NULL
);


ALTER TABLE public.ad_size OWNER TO phred;

--
-- Name: ad_size_ad_size_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_size_ad_size_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_size_ad_size_id_seq OWNER TO phred;

--
-- Name: ad_size_ad_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE ad_size_ad_size_id_seq OWNED BY ad_size.ad_size_id;


--
-- Name: ad_size_ad_size_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval('ad_size_ad_size_id_seq', 3, true);


--
-- Name: ad_size_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE ad_size ALTER COLUMN ad_size_id SET DEFAULT nextval('ad_size_ad_size_id_seq'::regclass);


--
-- Data for Name: ad_size; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY ad_size (ad_size_id, name, height, width, css_url) FROM stdin;
1	Leaderboard	90	728	http://www.silverliningnetworks.com/css/sl_leaderboard.css
2	Full Banner	60	468	http://www.silverliningnetworks.com/css/sl_full_banner.css
3	Text Ad	45	600	http://www.silverliningnetworks.com/css/sl_text_ad.css
4	Skyscraper	600	120	http://www.silverliningnetworks.com/css/sl_skyscraper.css
5	Wide Skyscraper	600	160	http://www.silverliningnetworks.com/css/sl_wide_skyscraper.css
6	Half Page Ad	600	300	http://www.silverliningnetworks.com/css/sl_half_page_ad.css
\.


--
-- Name: ad_size_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad_size
    ADD CONSTRAINT ad_size_pkey PRIMARY KEY (ad_size_id);


--
-- PostgreSQL database dump complete
--

