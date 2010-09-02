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
    network_id SERIAL NOT NULL,
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

