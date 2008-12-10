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
-- Name: router_history; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router_history (
    router_id integer NOT NULL,
    cts timestamp without time zone DEFAULT now() NOT NULL,
    bytes_up integer DEFAULT 0 NOT NULL,
    clients integer DEFAULT 0 NOT NULL,
    gateway_ping_time integer DEFAULT 0 NOT NULL,
    load double precision DEFAULT 0 NOT NULL,
    freemem integer DEFAULT 0 NOT NULL,
    tcp_conns integer DEFAULT 0 NOT NULL,
    bytes_down integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.router_history OWNER TO phred;

--
-- Data for Name: router_history; Type: TABLE DATA; Schema: public; Owner: phred
--

COPY router_history (router_id, cts, bytes_up, clients, gateway_ping_time, load, freemem, tcp_conns, bytes_down) FROM stdin;
\.


--
-- Name: router_history_router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router_history
    ADD CONSTRAINT router_history_router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id);


--
-- PostgreSQL database dump complete
--

