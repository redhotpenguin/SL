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
    reg_id serial NOT NULL,
    ip inet NOT NULL,
    password_md5 character varying(32),
	email character varying(64) NOT NULL,
    zipcode character varying(10) NOT NULL,
    serial_number character(12) NOT NULL,
    macaddr macaddr NOT NULL,
    firstname character varying(32) NOT NULL,
    lastname character varying(32) NOT NULL,
    description text,
    street_addr character varying(64) NOT NULL,
    apt_suite character varying(5),
    referer character varying(32),
    phone character varying(14),
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active smallint DEFAULT 0,
    sponsor character varying(64),
    code integer NOT NULL
);


ALTER TABLE public.reg OWNER TO fred;

--
-- Name: reg_reg_id_seq; Type: SEQUENCE SET; Schema: public; Owner: fred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('reg', 'reg_id'), 14, true);


--
-- Data for Name: reg; Type: TABLE DATA; Schema: public; Owner: fred
--

INSERT INTO reg VALUES (14, '10.0.0.3', 'fred@redhotpenguin.com', '94109', 'CL7A0F219620', '00:16:b6:28:85:02', 'Fred', 'Moyer', '', '1440 Union Street', '302', '', '415.720.2103', '2006-04-29 18:49:08.215417', '2006-04-29 18:49:08.215417', 1, NULL, 12345678);


--
-- Name: reg_id_pkey; Type: CONSTRAINT; Schema: public; Owner: fred; Tablespace: 
--

ALTER TABLE ONLY reg
    ADD CONSTRAINT reg_id_pkey PRIMARY KEY (reg_id);


--
-- PostgreSQL database dump complete
--

