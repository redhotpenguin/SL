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


-- Create the default group
INSERT INTO ad_group (ad_group_id, name) values (1, 'Default');


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

ALTER TABLE public.url OWNER TO fred;

--
-- Name: url_url_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('url', 'url_id'), 386, true);


--
-- Data for Name: url; Type: TABLE DATA; Schema: public; Owner: fred
--

INSERT INTO url VALUES (281, 'directorym.com', true);
INSERT INTO url VALUES (282, 'euroclick.com', true);
INSERT INTO url VALUES (283, 'caesars.com', true);
INSERT INTO url VALUES (284, 'haaretz.com', true);
INSERT INTO url VALUES (285, 'com.com', true);
INSERT INTO url VALUES (286, 'comcast.net/providers', true);
INSERT INTO url VALUES (287, 'livejournal.com', true);
INSERT INTO url VALUES (288, 'stat.livejournal.com', true);
INSERT INTO url VALUES (289, 'wynnlasvegas.com', true);
INSERT INTO url VALUES (290, 'images.friendster.com', true);
INSERT INTO url VALUES (291, 'img.shopzilla.com', true);
INSERT INTO url VALUES (292, 'images.thetimes.co.uk', true);
INSERT INTO url VALUES (293, 'connextra.com', true);
INSERT INTO url VALUES (294, 'subaru.com', true);
INSERT INTO url VALUES (295, 'ferrariworld.com', true);
INSERT INTO url VALUES (296, 'porsche.com', true);
INSERT INTO url VALUES (297, 'winningmark.com', true);
INSERT INTO url VALUES (298, 'wordpress.org', true);
INSERT INTO url VALUES (299, 'specificclick.net', true);
INSERT INTO url VALUES (300, 'tmcs.net', true);
INSERT INTO url VALUES (301, 'zedo.net', true);
INSERT INTO url VALUES (302, 'zedo.com', true);
INSERT INTO url VALUES (303, 'cafepress.com', true);
INSERT INTO url VALUES (304, 'espn.go.com/myespn', true);
INSERT INTO url VALUES (305, 'espn.go.com/motion', true);
INSERT INTO url VALUES (306, 'burstnet.com', true);
INSERT INTO url VALUES (307, 'delb.myspace.com', true);
INSERT INTO url VALUES (308, 'my.ebay.com', true);
INSERT INTO url VALUES (309, 'llnwd.net', true);
INSERT INTO url VALUES (310, 'yieldmanager.com', true);
INSERT INTO url VALUES (311, 'ebayobjects.com', true);
INSERT INTO url VALUES (312, 'trafficmp.com', true);
INSERT INTO url VALUES (313, 'urchin.com', true);
INSERT INTO url VALUES (314, 'mediaplex.com', true);
INSERT INTO url VALUES (315, 'newsmax.com', true);
INSERT INTO url VALUES (316, 'nextag.com', true);
INSERT INTO url VALUES (317, 'questionmarket.com', true);
INSERT INTO url VALUES (318, 'realmedia.com', true);
INSERT INTO url VALUES (319, 'ebayrtm.com', true);
INSERT INTO url VALUES (320, 'fastclick.net', true);
INSERT INTO url VALUES (321, 'images.yelp.com', true);
INSERT INTO url VALUES (322, 'websidestory.com', true);
INSERT INTO url VALUES (323, 'mt.redhotpenguin.com', true);
INSERT INTO url VALUES (324, 'symantecliveupdate.com', true);
INSERT INTO url VALUES (325, 'prq.to', true);
INSERT INTO url VALUES (326, 'adbrite.com', true);
INSERT INTO url VALUES (327, 'go.fark.com', true);
INSERT INTO url VALUES (328, 'img.fark.com', true);
INSERT INTO url VALUES (329, 'static.fmpub.net', true);
INSERT INTO url VALUES (330, 'yimg.com', true);
INSERT INTO url VALUES (331, 'adgardener.com', true);
INSERT INTO url VALUES (332, 'hb.lycos.com', true);
INSERT INTO url VALUES (333, 'ratings.lycos.com', true);
INSERT INTO url VALUES (334, 'scripts.lycos.com', true);
INSERT INTO url VALUES (335, '.lygo.com', true);
INSERT INTO url VALUES (336, '.marketplace.net', true);
INSERT INTO url VALUES (337, '.hitbox.com', true);
INSERT INTO url VALUES (338, '.businessweek.com', true);
INSERT INTO url VALUES (339, 'yapceurope.org', true);
INSERT INTO url VALUES (340, 'personals.yahoo.com', true);
INSERT INTO url VALUES (341, 'shutterfly.com', true);
INSERT INTO url VALUES (342, 'oingo.com', true);
INSERT INTO url VALUES (343, 'youtube.com', true);
INSERT INTO url VALUES (344, 'perlworkshop.no', true);
INSERT INTO url VALUES (345, 'travelpost.com', true);
INSERT INTO url VALUES (346, 'myway.com', true);
INSERT INTO url VALUES (347, 't-mobile.com', true);
INSERT INTO url VALUES (348, '.live.com', true);
INSERT INTO url VALUES (349, '.hotmail.com', true);
INSERT INTO url VALUES (350, '.passport.com', true);
INSERT INTO url VALUES (351, 'ebaystatic.com', true);
INSERT INTO url VALUES (352, 'ads.google.com', true);
INSERT INTO url VALUES (353, 'gmail.com', true);
INSERT INTO url VALUES (354, '.meebo.com', true);
INSERT INTO url VALUES (355, 'mail.google.com', true);
INSERT INTO url VALUES (356, 'mail.yahoo.com', true);
INSERT INTO url VALUES (357, 'login.yahoo.com', true);
INSERT INTO url VALUES (358, '.clientsection.com', true);
INSERT INTO url VALUES (359, '.projectpath.com', true);
INSERT INTO url VALUES (360, '.doubleclick.net', true);
INSERT INTO url VALUES (361, 'google-analytics.com', true);
INSERT INTO url VALUES (362, 'googlesyndication.com', true);
INSERT INTO url VALUES (363, '.adsonar.com', true);
INSERT INTO url VALUES (364, '.akamai.net', true);
INSERT INTO url VALUES (365, '.247realmedia.com', true);
INSERT INTO url VALUES (366, '.atdmt.com', true);
INSERT INTO url VALUES (367, '.zedo.com', true);
INSERT INTO url VALUES (368, 'ads.cnn.com', true);
INSERT INTO url VALUES (369, 'cl.cnn.com', true);
INSERT INTO url VALUES (370, '2o7.net', true);
INSERT INTO url VALUES (371, 'a.cnn.net', true);
INSERT INTO url VALUES (372, 'dyn.cnn.com', true);
INSERT INTO url VALUES (373, '.advertising.com', true);
INSERT INTO url VALUES (374, '.eproof.com', true);
INSERT INTO url VALUES (375, '.2mdn.net', true);
INSERT INTO url VALUES (376, '.mercuras.com', true);
INSERT INTO url VALUES (377, '.tribalfusion.com', true);
INSERT INTO url VALUES (378, '.fmpub.net', true);
INSERT INTO url VALUES (379, '.tacoda.net', true);
INSERT INTO url VALUES (380, 'linksynergy.com', true);
INSERT INTO url VALUES (381, '.tkqlhce.com', true);
INSERT INTO url VALUES (382, 'coremetrics.com', true);
INSERT INTO url VALUES (383, '.falkag.net', true);
INSERT INTO url VALUES (384, 'earthlink.net', true);
INSERT INTO url VALUES (385, 'rpc.bloglines.com', true);
INSERT INTO url VALUES (386, 'silverliningnetworks.com', true);


--
-- Name: url_index; Type: INDEX; Schema: public; Owner: fred; Tablespace: 
--

CREATE INDEX url_index ON url USING btree (url);


--
-- Name: url_uniq_index; Type: INDEX; Schema: public; Owner: fred; Tablespace: 
--

CREATE UNIQUE INDEX url_uniq_index ON url USING btree (url);


--
-- PostgreSQL database dump complete
--

