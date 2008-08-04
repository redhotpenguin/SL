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
-- Name: router__ad_zone; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router__ad_zone (
    router_id integer NOT NULL,
    ad_zone_id integer NOT NULL
);


ALTER TABLE public.router__ad_zone OWNER TO phred;


COPY router__ad_zone (router_id, ad_zone_id) FROM stdin;
2	1
35	1
80	3
58	3
64	3
62	3
63	3
60	3
61	3
69	3
79	5
89	6
90	7
\.




--
-- Name: router__ad_zone__pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router__ad_zone
    ADD CONSTRAINT router__ad_zone__pkey PRIMARY KEY (router_id, ad_zone_id);


--
-- Name: router__ad_zone__ad_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__ad_zone
    ADD CONSTRAINT router__ad_zone__ad_zone_id_fkey FOREIGN KEY (ad_zone_id) REFERENCES ad_zone(ad_zone_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router__ad_zone__router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__ad_zone
    ADD CONSTRAINT router__ad_zone__router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

