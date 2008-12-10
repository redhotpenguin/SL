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
-- Name: network; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE network (
    network_id integer NOT NULL,
    account_id integer NOT NULL,
    display_name text NOT NULL,
    net_name text NOT NULL,
    alert_email text NOT NULL,
    net_location text NOT NULL,
    essid text NOT NULL,
    splash_href text DEFAULT 'http://www.silverliningnetworks.com/splash.html'::text NOT NULL,
    node_pwd text NOT NULL,
    splash_timeout text DEFAULT 15 NOT NULL,
    bytes_day text DEFAULT 0 NOT NULL,
    bytes_week text DEFAULT 0 NOT NULL,
    bytes_month text DEFAULT 0 NOT NULL,
    clients_day text DEFAULT 0 NOT NULL,
    clients_week text DEFAULT 0 NOT NULL,
    clients_month text DEFAULT 0 NOT NULL
);


ALTER TABLE public.network OWNER TO phred;

--
-- Name: network_network_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE network_network_id_seq
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

SELECT pg_catalog.setval('network_network_id_seq', 7, true);


--
-- Name: network_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE network ALTER COLUMN network_id SET DEFAULT nextval('network_network_id_seq'::regclass);


--
-- Data for Name: network; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY network (network_id, account_id, display_name, net_name, alert_email, net_location, essid, splash_href, node_pwd, splash_timeout, bytes_day, bytes_week, bytes_month, clients_day, clients_week, clients_month) FROM stdin;
1	1	Silver Lining Networks San Francisco	SLNSF	fred@silverliningnetworks.com	0,0,0	SLN Free WiFi	http://www.silverliningnetworks.com/aircloud/splash.html	node_pwd	30	0	0	0	0	0	0
\.


--
-- Name: network_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_pkey PRIMARY KEY (network_id);


--
-- Name: network_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY network
    ADD CONSTRAINT network_account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id);


--
-- PostgreSQL database dump complete
--

