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

CREATE TABLE reg (
    reg_id integer NOT NULL,
    email character varying(64) DEFAULT ''::character varying NOT NULL,
    paypal_id character varying(64) DEFAULT ''::character varying,
    zipcode character varying(10) DEFAULT ''::character varying,
    firstname character varying(32),
    lastname character varying(32),
    description text,
    street_addr character varying(64),
    apt_suite character varying(5),
    referer character varying(32),
    phone character varying(14),
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    sponsor character varying(64),
    street_addr2 character varying(64),
    city character varying(64),
    state character(2),
    active boolean DEFAULT true,
    report_email character varying(64) DEFAULT ''::character varying,
    password_md5 character varying(32),
    send_reports_daily boolean DEFAULT false,
    send_reports_weekly boolean DEFAULT false,
    send_reports_monthly boolean DEFAULT false,
    send_reports_quarterly boolean DEFAULT false,
    report_email_frequency character varying(16) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.reg OWNER TO fred;

--
-- Name: reg_reg_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('reg', 'reg_id'), 14, true);


--
-- Data for Name: reg; Type: TABLE DATA; Schema: public; Owner: fred
--

INSERT INTO reg VALUES (33, 'tahoetae@yahoo.com', '', 'Garrett', 'Suchecki', '', '', NULL, NULL, NULL, '2006-08-24 01:54:20.678205', '2006-08-24 01:54:20.678205', NULL, NULL, NULL, NULL, true, '', NULL, false, false, false, false, '');
INSERT INTO reg VALUES (18, 'peterschultz_1999@yahoo.com', '93514', 'Peter', 'Schultz', 'bishoproasters.com/store', '236 N 3rd st', '', 'Stephen Edwards', '5305425000', '2006-05-06 18:10:05.688252', '2006-05-06 18:10:05.688252', NULL, 'The Shops at Heavenly Valley', 'Bisop', 'CA', true, '', NULL, false, false, false, false, '');
INSERT INTO reg VALUES (15, 'jeff@redhotpenguin.com', '97212', 'Jeff', 'Lennan', '', '609 NE Graham St', '', '', '5037156293', '2006-05-02 00:10:03.469172', '2006-05-02 00:10:03.469172', NULL, NULL, NULL, NULL, true, '', NULL, false, false, false, false, '');
INSERT INTO reg VALUES (20, 'darren_waddell@yahoo.com', '94043', 'Darren', 'Wadell', '', 'VeriSign, Inc.', '', '', '5037156293', '2006-05-06 18:17:08.950402', '2006-05-06 18:17:08.950402', NULL, '685 E. Middlefield Rd.', 'Mountain View', 'ca', false, '', NULL, false, false, false, false, '');
INSERT INTO reg VALUES (19, 'garrettsuchecki@gmail.com', '', 'Garrett', 'Suchecki', '', '', '', '', '', '2006-05-06 18:14:02.564637', '2006-05-06 18:14:02.564637', NULL, '', 'Glendale', '  ', true, '', '4311f23273098108fc2d9d0da78b38a8', false, false, false, false, '');
INSERT INTO reg VALUES (17, 'hanseric@earthlink.net', '33755', 'Hans', 'Eisenmann', '', '1610 Karlyn Drive', '', '', '7274525241', '2006-05-06 17:58:01.72004', '2006-05-06 17:58:01.72004', NULL, NULL, 'Clearwater', NULL, true, '', NULL, false, false, false, false, '');
INSERT INTO reg VALUES (44, 'alex@walkwire.com', '93514', 'Peter', 'Schultz', 'bishoproasters.com/store', '', NULL, NULL, NULL, '2006-10-03 22:38:27.991434', '2006-10-03 22:38:27.991434', NULL, NULL, NULL, NULL, true, '', '10b83e92255fe5db3b642bbeb4e2b031', false, false, false, false, '');
INSERT INTO reg VALUES (46, 'j.brostoff@gmail.com', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2006-12-19 23:53:10.854079', '2006-12-19 23:53:10.854079', NULL, NULL, NULL, NULL, true, '', '761e0148b2ea4621bb8ca49a4f9af77e', false, false, false, false, '');
INSERT INTO reg VALUES (47, 'todd.bryson@yahoo.com', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2007-02-04 12:47:11.958701', '2007-02-04 12:47:11.958701', NULL, NULL, NULL, NULL, true, '', 'e252a5167841b3d3a28e9030615964fa', false, false, true, false, 'weekly');
INSERT INTO reg VALUES (14, 'phredwolf@yahoo.com', '94109', 'Fred', 'Moyer', '', '1440 Union Street', '302', '', '415.720.2103', '2006-04-29 18:49:08.215417', '2006-04-29 18:49:08.215417', NULL, NULL, NULL, NULL, true, '', 'e6b72eed22ee2bc2acaa232c9f77064f', true, true, true, true, 'daily');
INSERT INTO reg VALUES (48, 'aabramson@wi-figuys.com', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2007-03-28 10:36:24.20188', '2007-03-28 10:36:24.20188', NULL, NULL, NULL, NULL, true, '', 'd12094215c31b363b21f5e7503fd03b8', false, false, false, false, '');
INSERT INTO reg VALUES (30, 'jeff@leknott.com', '97205', 'Jeff', 'Lennan', '', 'Winning Mark LLC', '910', NULL, '5037156293', '2006-08-09 00:20:03.715632', '2006-08-09 00:20:03.715632', NULL, '1220 SW Morrison', 'Portland', 'OR', true, '', '4700e66aeb44ab7674e2e3e61fa91c1f', true, false, false, false, 'weekly');


--
-- Name: reg_id_pkey; Type: CONSTRAINT; Schema: public; Owner: fred; Tablespace: 
--

ALTER TABLE ONLY reg
    ADD CONSTRAINT reg_id_pkey PRIMARY KEY (reg_id);


--
-- PostgreSQL database dump complete
--

