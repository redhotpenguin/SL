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
-- Name: reg; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE reg (
    reg_id integer DEFAULT nextval('reg_reg_id_seq'::regclass) NOT NULL,
    email character varying(64) DEFAULT ''::character varying NOT NULL,
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
    report_email_frequency character varying(16) DEFAULT ''::character varying NOT NULL,
    paypal_id text,
    payment_threshold integer DEFAULT 5 NOT NULL,
    custom_ads boolean DEFAULT false
);


ALTER TABLE public.reg OWNER TO phred;

--
-- Name: reg_id_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY reg
    ADD CONSTRAINT reg_id_pkey PRIMARY KEY (reg_id);


--
-- PostgreSQL database dump complete
--

