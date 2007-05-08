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
-- Name: root; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE root (
    root_id serial NOT NULL,
    reg_id INTEGER NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now()
);

ALTER TABLE root add constraint reg_id_fkey FOREIGN KEY (reg_id) 
REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.root OWNER TO phred;

--
-- Name: root_root_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('root', 'root_id'), 14, true);


--
-- Data for Name: root; Type: TABLE DATA; Schema: public; Owner: phred
--

--
-- Name: root_id_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY root
    ADD CONSTRAINT root_id_pkey PRIMARY KEY (root_id);


--
-- PostgreSQL database dump complete
--

