--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: network; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE network (
    network_id integer NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true,
    description text,
    name text,
    ssid text DEFAULT ''::text,
    account_id integer DEFAULT 1 NOT NULL,
    wan_ip inet,
    notes text DEFAULT ''::text NOT NULL,
    lat double precision,
    lng double precision,
    searches_daily integer DEFAULT 0 NOT NULL,
    users_daily integer DEFAULT 0 NOT NULL,
    searches_monthly integer DEFAULT 0 NOT NULL,
    users_monthly integer DEFAULT 0 NOT NULL,
    street_address text DEFAULT ''::text,
    city text DEFAULT ''::text,
    zip text DEFAULT ''::text,
    state text DEFAULT ''::text,
    country text DEFAULT ''::text,
    time_zone text DEFAULT 'America/Los_Angeles'::text
);


ALTER TABLE public.network OWNER TO phred;

--
-- Name: network_network_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE network_network_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.network_network_id_seq OWNER TO phred;

--
-- Name: network_network_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE network_network_id_seq OWNED BY network.network_id;


--
-- Name: network_network_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phred
--

SELECT pg_catalog.setval('network_network_id_seq', 2, true);


--
-- Name: network_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE network ALTER COLUMN network_id SET DEFAULT nextval('network_network_id_seq'::regclass);


--
-- Data for Name: network; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY network (network_id, cts, mts, active, description, name, ssid, account_id, wan_ip, notes, lat, lng, searches_daily, users_daily, searches_monthly, users_monthly, street_address, city, zip, state, country, time_zone) FROM stdin;
1	2010-09-02 12:23:11.079348	2010-09-02 12:23:11.079348	t	Free wifi network in the Russian Hill and Marina area near Van Ness and Union Streets	1440 Union	SL Free	202	67.169.76.3		\N	\N	0	0	0	0	1440 Union Street	San Francisco	94109	CA	US	America/Los_Angeles
2	2010-11-08 17:02:13.694221	2010-11-29 20:33:19.505676	t	\N	\N		1	127.0.0.1		\N	\N	0	0	0	0			94109			America/Los_Angeles
\.


--
-- Name: network_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_pkey PRIMARY KEY (network_id);


--
-- Name: update_network_mts; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER update_network_mts
    BEFORE UPDATE ON network
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();


--
-- Name: network_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

