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
-- Name: payment; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE payment (
    payment_id integer NOT NULL,
    reg_id integer NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    approved_ts timestamp without time zone,
    approved boolean DEFAULT false,
    approved_reg_id integer DEFAULT 1 NOT NULL,
    num_views integer NOT NULL,
    cpm money NOT NULL,
    amount money NOT NULL,
    pp_timestamp timestamp with time zone,
    pp_correlation_id text DEFAULT ''::text,
    pp_version text DEFAULT ''::text,
    pp_build text DEFAULT ''::text,
    payable boolean DEFAULT false NOT NULL,
    receivable boolean DEFAULT false NOT NULL,
    collected boolean DEFAULT false NOT NULL,
    paid boolean DEFAULT false NOT NULL
);


ALTER TABLE public.payment OWNER TO phred;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE payment_payment_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.payment_payment_id_seq OWNER TO phred;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE payment_payment_id_seq OWNED BY payment.payment_id;


--
-- Name: payment_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval('payment_payment_id_seq', 1, true);


--
-- Name: payment_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE payment ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);


--
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: phred
--

INSERT INTO payment VALUES (1, 14, '2008-01-04 01:17:32.667096', NULL, true, 14, 10000, '$1.00', '$0.01', NULL, '', '', '', false, false, false, false);


--
-- Name: payment_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- Name: reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

