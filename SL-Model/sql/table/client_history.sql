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
-- Name: client_history; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE client_history (
    mac macaddr,
    cts timestamp without time zone DEFAULT now() NOT NULL,
    bytes_up integer DEFAULT 0 NOT NULL,
    bytes_down integer DEFAULT 0 NOT NULL,
    router_id integer NOT NULL
);


ALTER TABLE public.client_history OWNER TO phred;

--
-- Data for Name: client_history; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY client_history (mac, cts, bytes_up, bytes_down, router_id) FROM stdin;
\.


--
-- Name: client_history_router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY client_history
    ADD CONSTRAINT client_history_router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id);


--
-- PostgreSQL database dump complete
--

