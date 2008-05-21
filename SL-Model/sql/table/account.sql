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
-- Name: account; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE account (
    account_id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.account OWNER TO phred;

--
-- Name: account_account_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE account_account_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.account_account_id_seq OWNER TO phred;

--
-- Name: account_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE account_account_id_seq OWNED BY account.account_id;


--
-- Name: account_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE account ALTER COLUMN account_id SET DEFAULT nextval('account_account_id_seq'::regclass);


--
-- Name: account_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY account
    ADD CONSTRAINT account_pkey PRIMARY KEY (account_id);


--
-- PostgreSQL database dump complete
--

