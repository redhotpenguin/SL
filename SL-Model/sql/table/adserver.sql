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
-- Name: adserver; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE adserver (
    adserver_id serial NOT NULL,
    reg_id INTEGER NOT NULL,
    type text not null,
    login text not null,
    pass text not null,
    url text not null,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now()
);

ALTER TABLE adserver add constraint reg_id_fkey FOREIGN KEY (reg_id) 
REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.adserver OWNER TO phred;

--
-- Name: adserver_adserver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('adserver', 'adserver_id'), 1, true);


--
-- Data for Name: adserver; Type: TABLE DATA; Schema: public; Owner: phred
--

--
-- Name: adserver_id_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY adserver
    ADD CONSTRAINT adserver_id_pkey PRIMARY KEY (adserver_id);


--
-- PostgreSQL database dump complete
--

