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
    mts timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true,
    report_email character varying(64) DEFAULT ''::character varying,
    password_md5 character varying(32),
    send_reports_daily boolean DEFAULT false,
    send_reports_weekly boolean DEFAULT false,
    send_reports_monthly boolean DEFAULT false,
    send_reports_quarterly boolean DEFAULT false,
    report_email_frequency character varying(16) DEFAULT ''::character varying NOT NULL,
    account_id integer DEFAULT 1 NOT NULL,
    admin boolean DEFAULT false NOT NULL
);


ALTER TABLE public.reg OWNER TO phred;

--
-- Name: reg_id_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY reg
    ADD CONSTRAINT reg_id_pkey PRIMARY KEY (reg_id);


--
-- Name: reg__account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY reg
    ADD CONSTRAINT reg__account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

