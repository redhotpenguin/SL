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
-- Name: ad_size; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_size (
    ad_size_id integer NOT NULL,
    name text,
    css_url text NOT NULL,
    template text DEFAULT ''::text NOT NULL,
    grouping integer DEFAULT 1 NOT NULL,
    js_url text DEFAULT ''::text NOT NULL,
    head_html text,
    persistent boolean DEFAULT true NOT NULL,
    hidden boolean DEFAULT false NOT NULL
);


ALTER TABLE public.ad_size OWNER TO phred;

--
-- Name: ad_size_ad_size_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_size_ad_size_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_size_ad_size_id_seq OWNER TO phred;

--
-- Name: ad_size_ad_size_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE ad_size_ad_size_id_seq OWNED BY ad_size.ad_size_id;


--
-- Name: ad_size_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE ad_size ALTER COLUMN ad_size_id SET DEFAULT nextval('ad_size_ad_size_id_seq'::regclass);


--
-- Name: ad_size_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad_size
    ADD CONSTRAINT ad_size_pkey PRIMARY KEY (ad_size_id);


--
-- PostgreSQL database dump complete
--

