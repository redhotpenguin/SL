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
-- Name: cc; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE cc (
    cc_id integer NOT NULL,
    account_id integer NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    data bytea NOT NULL
);


ALTER TABLE public.cc OWNER TO phred;

--
-- Data for Name: cc; Type: TABLE DATA; Schema: public; Owner: phred
--



--
-- Name: account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY cc
    ADD CONSTRAINT account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

