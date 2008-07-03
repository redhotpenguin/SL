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
-- Name: account__ad_zone; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE account__ad_zone (
    account_id integer NOT NULL,
    ad_zone_id integer NOT NULL
);


ALTER TABLE public.account__ad_zone OWNER TO phred;

--
-- Name: account__ad_zone__pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY account__ad_zone
    ADD CONSTRAINT account__ad_zone__pkey PRIMARY KEY (account_id, ad_zone_id);


--
-- Name: account__ad_zone__ad_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY account__ad_zone
    ADD CONSTRAINT account__ad_zone__ad_zone_id_fkey FOREIGN KEY (ad_zone_id) REFERENCES ad_zone(ad_zone_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: account__ad_zone__account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY account__ad_zone
    ADD CONSTRAINT account__ad_zone__account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

