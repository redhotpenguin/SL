--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: ad_ad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('ad', 'ad_id'), 12, true);


--
-- Name: click_click_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('click', 'click_id'), 9, true);


--
-- Name: link_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('link', 'link_id'), 12, true);


--
-- Data for Name: ad; Type: TABLE DATA; Schema: public; Owner: fred
--

COPY ad (ad_id, name, "template") FROM stdin;
5	Bridal Show	bridal
7	CbarPDX	cbar
12	OCC Main	occ_main
11	Starbucks	starbucks
9	Kinkos	kinkos
6	OCC Events	events
10	IF Green	ifgreen
\.


--
-- Data for Name: click; Type: TABLE DATA; Schema: public; Owner: fred
--

COPY click (click_id, ts, link_id) FROM stdin;
\.


--
-- Data for Name: link; Type: TABLE DATA; Schema: public; Owner: fred
--

COPY link (link_id, ad_id, uri, md5) FROM stdin;
4	5	http://www.portlandbridalshow.com	6c723a4dd393cf7ba09cfaf3d62f9c9f
5	6	http://live.oregoncc.org/iebms/coe/coe_p1_all.aspx?oc=10&cc=occcoe	421cfb7b37236c8b9e92607f22520268
6	7	http://www.cbarpdx.com/index2.htm	4b0a3c9fa343bc654ad458d1b67704d9
7	9	http://www.oregoncc.org/kinkos/kinkos.htm	af07169ee8893ab424e4ce275508c2f7
8	10	http://www.ifgreen.com/	0dbb2f68518de986eba2841e430060b7
9	11	http://www.redhotpenguin.com/images/sl/occ_starbucks_map.pdf	7786e3657cac833903da443d7a59aad0
10	12	http://www.weather.com/outlook/events/sports/local/671:20?from=hyper_dropdown_venue_results	b6bce9998e1a00a5d79ea90e6a395318
11	12	http://www.portofportland.com/flights.aspx	f2cf71dc0d64505cabd2a4ec269cb140
12	12	http://www.trimet.org/guide/index.htm	ff3d68332495fbffae0a2859e65a2f38
\.


--
-- PostgreSQL database dump complete
--

