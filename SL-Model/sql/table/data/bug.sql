--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

--
-- Name: bug_bug_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred2
--

SELECT pg_catalog.setval('bug_bug_id_seq', 141, true);


--
-- Data for Name: bug; Type: TABLE DATA; Schema: public; Owner: phred2
--

COPY bug (bug_id, image_href, link_href, cts, mts, account_id, ad_size_id) FROM stdin;
1	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 22:56:38.9086	2008-08-03 22:56:38.9086	1	1
2	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 22:56:38.9166	2008-08-03 22:56:38.9166	1	2
3	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 22:56:38.9246	2008-08-03 22:56:38.9246	1	3
4	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.009595	2008-08-03 23:01:13.009595	1	4
5	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.061596	2008-08-03 23:01:13.061596	1	5
6	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.077597	2008-08-03 23:01:13.077597	1	6
7	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.085597	2008-08-03 23:01:13.085597	3	1
8	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.097598	2008-08-03 23:01:13.097598	3	2
9	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.105598	2008-08-03 23:01:13.105598	3	3
10	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.113598	2008-08-03 23:01:13.113598	3	4
11	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.121598	2008-08-03 23:01:13.121598	3	5
12	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.129599	2008-08-03 23:01:13.129599	3	6
13	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.137599	2008-08-03 23:01:13.137599	4	1
14	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.145599	2008-08-03 23:01:13.145599	4	2
15	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.153599	2008-08-03 23:01:13.153599	4	3
16	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.1696	2008-08-03 23:01:13.1696	4	4
17	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.1776	2008-08-03 23:01:13.1776	4	5
18	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.189601	2008-08-03 23:01:13.189601	4	6
19	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.197601	2008-08-03 23:01:13.197601	5	1
20	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.209601	2008-08-03 23:01:13.209601	5	2
21	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.213601	2008-08-03 23:01:13.213601	5	3
22	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.221602	2008-08-03 23:01:13.221602	5	4
23	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.237602	2008-08-03 23:01:13.237602	5	5
24	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.245602	2008-08-03 23:01:13.245602	5	6
25	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.253603	2008-08-03 23:01:13.253603	6	1
26	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.269603	2008-08-03 23:01:13.269603	6	2
27	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.277604	2008-08-03 23:01:13.277604	6	3
28	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.285604	2008-08-03 23:01:13.285604	6	4
29	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.297604	2008-08-03 23:01:13.297604	6	5
30	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.305604	2008-08-03 23:01:13.305604	6	6
31	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.313605	2008-08-03 23:01:13.313605	7	1
32	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.329605	2008-08-03 23:01:13.329605	7	2
33	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.337605	2008-08-03 23:01:13.337605	7	3
34	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.345606	2008-08-03 23:01:13.345606	7	4
35	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.361606	2008-08-03 23:01:13.361606	7	5
36	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.377607	2008-08-03 23:01:13.377607	7	6
37	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.413608	2008-08-03 23:01:13.413608	8	1
38	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.429609	2008-08-03 23:01:13.429609	8	2
39	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.46161	2008-08-03 23:01:13.46161	8	3
40	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.47761	2008-08-03 23:01:13.47761	8	4
41	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.493611	2008-08-03 23:01:13.493611	8	5
42	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.513611	2008-08-03 23:01:13.513611	8	6
43	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.529612	2008-08-03 23:01:13.529612	9	1
44	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.545612	2008-08-03 23:01:13.545612	9	2
45	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.561613	2008-08-03 23:01:13.561613	9	3
46	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.577613	2008-08-03 23:01:13.577613	9	4
47	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.593614	2008-08-03 23:01:13.593614	9	5
48	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.613615	2008-08-03 23:01:13.613615	9	6
49	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.629615	2008-08-03 23:01:13.629615	10	1
50	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.645616	2008-08-03 23:01:13.645616	10	2
51	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.661616	2008-08-03 23:01:13.661616	10	3
52	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.669616	2008-08-03 23:01:13.669616	10	4
53	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.677617	2008-08-03 23:01:13.677617	10	5
54	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.685617	2008-08-03 23:01:13.685617	10	6
55	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.693617	2008-08-03 23:01:13.693617	11	1
56	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.705618	2008-08-03 23:01:13.705618	11	2
57	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.713618	2008-08-03 23:01:13.713618	11	3
58	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.721618	2008-08-03 23:01:13.721618	11	4
59	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.729618	2008-08-03 23:01:13.729618	11	5
60	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.737619	2008-08-03 23:01:13.737619	11	6
61	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.745619	2008-08-03 23:01:13.745619	12	1
62	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.753619	2008-08-03 23:01:13.753619	12	2
63	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.761619	2008-08-03 23:01:13.761619	12	3
64	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.76962	2008-08-03 23:01:13.76962	12	4
65	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.77762	2008-08-03 23:01:13.77762	12	5
66	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.78562	2008-08-03 23:01:13.78562	12	6
67	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.79362	2008-08-03 23:01:13.79362	13	1
68	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.805621	2008-08-03 23:01:13.805621	13	2
69	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.813621	2008-08-03 23:01:13.813621	13	3
70	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.821621	2008-08-03 23:01:13.821621	13	4
71	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.829622	2008-08-03 23:01:13.829622	13	5
72	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.837622	2008-08-03 23:01:13.837622	13	6
73	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.845622	2008-08-03 23:01:13.845622	14	1
74	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.853622	2008-08-03 23:01:13.853622	14	2
75	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.861623	2008-08-03 23:01:13.861623	14	3
76	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.869623	2008-08-03 23:01:13.869623	14	4
77	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.877623	2008-08-03 23:01:13.877623	14	5
78	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.893624	2008-08-03 23:01:13.893624	14	6
79	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.913624	2008-08-03 23:01:13.913624	15	1
80	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.921625	2008-08-03 23:01:13.921625	15	2
81	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.929625	2008-08-03 23:01:13.929625	15	3
82	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.937625	2008-08-03 23:01:13.937625	15	4
83	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.945625	2008-08-03 23:01:13.945625	15	5
84	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.953626	2008-08-03 23:01:13.953626	15	6
85	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.961626	2008-08-03 23:01:13.961626	16	1
86	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.969626	2008-08-03 23:01:13.969626	16	2
87	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.977626	2008-08-03 23:01:13.977626	16	3
88	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.985627	2008-08-03 23:01:13.985627	16	4
89	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:13.993627	2008-08-03 23:01:13.993627	16	5
90	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.005627	2008-08-03 23:01:14.005627	16	6
91	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.041629	2008-08-03 23:01:14.041629	17	1
92	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.053629	2008-08-03 23:01:14.053629	17	2
93	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.061629	2008-08-03 23:01:14.061629	17	3
94	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.06963	2008-08-03 23:01:14.06963	17	4
95	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.07763	2008-08-03 23:01:14.07763	17	5
96	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.08563	2008-08-03 23:01:14.08563	17	6
97	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.09363	2008-08-03 23:01:14.09363	18	1
98	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.105631	2008-08-03 23:01:14.105631	18	2
99	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.113631	2008-08-03 23:01:14.113631	18	3
100	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.121631	2008-08-03 23:01:14.121631	18	4
101	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.137632	2008-08-03 23:01:14.137632	18	5
102	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.145632	2008-08-03 23:01:14.145632	18	6
103	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.161633	2008-08-03 23:01:14.161633	19	1
104	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.169633	2008-08-03 23:01:14.169633	19	2
105	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.177633	2008-08-03 23:01:14.177633	19	3
106	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.185633	2008-08-03 23:01:14.185633	19	4
107	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.193634	2008-08-03 23:01:14.193634	19	5
108	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.205634	2008-08-03 23:01:14.205634	19	6
109	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.213634	2008-08-03 23:01:14.213634	20	1
110	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.221635	2008-08-03 23:01:14.221635	20	2
111	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.229635	2008-08-03 23:01:14.229635	20	3
112	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.237635	2008-08-03 23:01:14.237635	20	4
113	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.253636	2008-08-03 23:01:14.253636	20	5
114	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.269636	2008-08-03 23:01:14.269636	20	6
115	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.277636	2008-08-03 23:01:14.277636	21	1
116	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.285637	2008-08-03 23:01:14.285637	21	2
117	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.293637	2008-08-03 23:01:14.293637	21	3
118	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.305637	2008-08-03 23:01:14.305637	21	4
119	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.313638	2008-08-03 23:01:14.313638	21	5
120	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.321638	2008-08-03 23:01:14.321638	21	6
121	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.329638	2008-08-03 23:01:14.329638	22	1
122	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.337638	2008-08-03 23:01:14.337638	22	2
123	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.361639	2008-08-03 23:01:14.361639	22	3
124	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.369639	2008-08-03 23:01:14.369639	22	4
125	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.37764	2008-08-03 23:01:14.37764	22	5
126	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.38564	2008-08-03 23:01:14.38564	22	6
127	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.39364	2008-08-03 23:01:14.39364	23	1
128	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.405641	2008-08-03 23:01:14.405641	23	2
129	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.413641	2008-08-03 23:01:14.413641	23	3
130	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.421641	2008-08-03 23:01:14.421641	23	4
131	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.429641	2008-08-03 23:01:14.429641	23	5
132	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.437642	2008-08-03 23:01:14.437642	23	6
133	http://www.silverliningnetworks.com/bugs/sl/leaderboard_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.453642	2008-08-03 23:01:14.453642	2	1
134	http://www.silverliningnetworks.com/bugs/sl/full_banner_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.461642	2008-08-03 23:01:14.461642	2	2
135	http://www.silverliningnetworks.com/bugs/sl/text_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.469643	2008-08-03 23:01:14.469643	2	3
136	http://www.silverliningnetworks.com/bugs/sl/skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.477643	2008-08-03 23:01:14.477643	2	4
137	http://www.silverliningnetworks.com/bugs/sl/wide_skyscraper_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.485643	2008-08-03 23:01:14.485643	2	5
138	http://www.silverliningnetworks.com/bugs/sl/half_page_ad_sponsored_by.gif	http://www.silverliningnetworks.com/?referer=silverlining	2008-08-03 23:01:14.493643	2008-08-03 23:01:14.493643	2	6
139	http://www.silverliningnetworks.com/argenta/awlogo.gif	http://www.kharmaconsulting.net/kharma-advertising-network/argenta-wireless.html	2008-08-07 16:50:13.293357	2008-08-07 16:50:13.293357	2	1
140	http://desitec.biz/freewifi/desitec_free_wifi.gif	http://www.desitec.biz	2008-08-07 17:09:12.451179	2008-08-07 17:09:12.451179	3	3
141	http://www.silverliningnetworks.com/aircloud/airCloud_full_banner_sponsored_by.gif	http://www.aircloud.com/welcome/	2008-08-07 17:26:50.638154	2008-08-07 17:26:50.638154	21	2
\.


--
-- PostgreSQL database dump complete
--

