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
-- Name: search; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE search (
    search_id integer NOT NULL,
    query text NOT NULL,
    start smallint NOT NULL,
    duration numeric(4,2) NOT NULL,
    network_id integer NOT NULL,
    search_user_id integer NOT NULL,
    mts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.search OWNER TO phred;

--
-- Name: search_search_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE search_search_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.search_search_id_seq OWNER TO phred;

--
-- Name: search_search_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE search_search_id_seq OWNED BY search.search_id;


--
-- Name: search_search_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval('search_search_id_seq', 91, true);


--
-- Name: search_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE search ALTER COLUMN search_id SET DEFAULT nextval('search_search_id_seq'::regclass);


--
-- Data for Name: search; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY search (search_id, query, start, duration, network_id, search_user_id, mts) FROM stdin;
21	clown	0	1.17	2	13	2010-11-08 17:36:34.93571
22	clown	0	0.00	2	13	2010-11-08 17:36:44.424547
23	clown names	0	1.13	2	13	2010-11-08 17:36:51.518267
24	clown names	0	0.01	2	13	2010-11-08 17:37:43.477806
25	icp clown names	0	1.08	2	13	2010-11-08 17:37:49.476367
26	icp clown names	0	0.00	2	13	2010-11-08 17:37:57.702569
27	tacos	0	1.08	2	13	2010-11-08 17:38:05.657693
28	clown	10	0.77	2	14	2010-11-08 17:38:22.522163
29	clown face	0	1.91	2	14	2010-11-08 17:38:27.915741
30	beers	0	1.91	2	14	2010-11-08 17:38:34.558396
31	tacos	0	1.14	2	13	2010-11-09 13:49:42.369764
32	tacos	0	0.00	2	13	2010-11-09 13:49:44.493432
33	beers	0	1.34	2	14	2010-11-11 19:05:56.666968
34	burgers and beer	0	1.16	2	14	2010-11-11 19:06:02.779451
35	pizza	0	2.90	2	15	2010-11-17 16:59:40.999733
36	pizza	0	2.61	2	15	2010-11-17 17:01:35.401504
37	canine	0	1.71	2	15	2010-11-17 17:01:54.824146
38	alexander	0	2.87	2	15	2010-11-17 17:05:30.966211
39	alexander	0	2.88	2	16	2010-11-17 17:08:40.360011
40	alexander	0	1.65	2	16	2010-11-17 17:08:52.359551
41	alexander	0	1.54	2	16	2010-11-17 17:08:54.613357
42	alexander	0	1.57	2	16	2010-11-17 17:09:05.208677
43	alexander	0	1.81	2	16	2010-11-17 17:09:08.690244
44	alexander	0	1.59	2	16	2010-11-17 17:09:11.675586
45	beer	0	1.54	2	16	2010-11-17 17:09:15.162087
46	beer	0	1.26	2	16	2010-11-17 17:09:17.790116
47	beer	0	1.27	2	16	2010-11-17 17:09:21.824971
48	beer	0	0.01	2	16	2010-11-17 17:09:34.919156
49	beer	0	0.01	2	16	2010-11-17 17:09:36.968899
50	beer	0	0.00	2	16	2010-11-17 17:09:38.003679
51	beer	0	0.00	2	16	2010-11-17 17:09:39.362896
52	pizza	0	1.80	2	16	2010-11-17 17:09:45.55871
53	pizza	0	0.00	2	16	2010-11-17 17:09:47.161873
54	beer	0	0.00	2	16	2010-11-17 17:10:01.529248
55	rockets	0	1.80	2	16	2010-11-17 17:10:30.353939
56	burger	0	1.51	2	16	2010-11-17 17:10:56.13462
57	burger	0	1.06	2	16	2010-11-17 17:12:01.964482
58	burger	0	0.00	2	16	2010-11-17 17:12:03.825409
59	burger	0	1.07	2	16	2010-11-17 17:18:21.982378
60	polkers	0	1.75	2	16	2010-11-17 17:18:46.483106
61	pizza	0	2.24	2	16	2010-11-19 12:57:23.995784
62	pizza	0	4.03	2	16	2010-11-19 15:22:21.58596
63	pizza	0	1.37	2	16	2010-11-19 15:25:57.050459
64	pizza	0	0.76	2	16	2010-11-19 15:25:57.289177
65	pizza	0	0.00	2	16	2010-11-19 15:25:57.688441
66	pizza	0	1.65	2	16	2010-11-19 16:39:56.554467
67	PORTLAND COFFEE	0	1.89	2	16	2010-11-19 16:45:21.35406
68	PORTLAND COFFEE	0	0.00	2	16	2010-11-19 16:45:36.705669
69	coffee	0	1.99	2	16	2010-11-19 16:45:46.339849
70	cars	0	6.85	2	16	2010-11-19 16:46:02.72464
71	beer	0	3.98	2	16	2010-11-19 16:47:05.025337
72	pizza	0	2.20	2	16	2010-11-27 16:06:57.158305
73	pizza	0	1.29	2	16	2010-11-27 16:08:00.951831
74	pizza	0	0.00	2	16	2010-11-27 16:08:02.742917
75	pizza	10	1.41	2	16	2010-11-27 16:16:10.058081
76	pizza	30	0.74	2	16	2010-11-27 16:16:18.0564
77	pizza	0	6.75	2	16	2010-11-27 17:44:49.393657
78	stelladora	0	1.35	2	16	2010-11-27 17:45:05.403875
79	stelladoro	0	1.94	2	16	2010-11-27 17:45:09.530395
80	pizza	0	1.41	2	16	2010-11-29 19:06:41.959547
81	pizza	0	0.00	2	16	2010-11-29 19:06:49.592698
82	pizza	0	0.70	2	16	2010-11-29 19:07:54.670086
83	pizza	0	0.06	2	16	2010-11-29 19:07:54.785535
84	pizza	0	0.07	2	16	2010-11-29 19:08:07.851944
85	pizza	0	1.00	2	16	2010-11-29 19:08:16.279851
86	pizza	0	0.00	2	16	2010-11-29 19:08:28.86013
87	pizza	0	0.89	2	16	2010-11-29 19:09:28.332461
88	pizza	0	1.05	2	16	2010-11-29 19:57:52.481543
89	pizza	0	0.55	2	16	2010-11-29 20:32:54.648248
90	pizza	0	0.07	2	16	2010-11-29 20:32:58.506625
91	pizza	0	0.47	2	16	2010-11-29 20:33:21.555292
\.


--
-- Name: search__network_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY search
    ADD CONSTRAINT search__network_id_fkey FOREIGN KEY (network_id) REFERENCES network(network_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: search__search_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY search
    ADD CONSTRAINT search__search_user_id_fkey FOREIGN KEY (search_user_id) REFERENCES search_user(search_user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

