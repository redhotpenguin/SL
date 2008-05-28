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
-- Name: router; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router (
    router_id integer DEFAULT nextval('router_router_id_seq'::regclass) NOT NULL,
    serial_number character(12),
    macaddr macaddr,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true,
    proxy inet,
    description text,
    name text,
    splash_timeout integer DEFAULT 60,
    splash_href text DEFAULT 'http://www.silverliningnetworks.com/network/'::text,
    firmware_version character varying(4) DEFAULT ''::character varying,
    ssid text DEFAULT ''::text,
    passwd_event text DEFAULT ''::text,
    firmware_event text DEFAULT ''::text,
    ssid_event text DEFAULT ''::text,
    reboot_event text DEFAULT ''::text,
    halt_event text DEFAULT ''::text,
    last_ping timestamp without time zone DEFAULT now(),
    views_daily integer DEFAULT 0 NOT NULL,
    account_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.router OWNER TO phred;

--
-- Name: router_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router
    ADD CONSTRAINT router_pkey PRIMARY KEY (router_id);


--
-- Name: madaddr_uniq; Type: INDEX; Schema: public; Owner: phred; Tablespace: 
--

CREATE UNIQUE INDEX madaddr_uniq ON router USING btree (macaddr);


--
-- Name: update_router_mts; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER update_router_mts
    BEFORE UPDATE ON router
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();


--
-- Name: account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router
    ADD CONSTRAINT account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

