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

create type ad_size as enum ( 'Leaderboard (728x90)', 'Full Banner (468x60)', 'Text Ad (600x30)');

--
-- Name: ad_zone; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_zone (
    ad_zone_id integer NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    account_id integer NOT NULL,
    type ad_size NOT NULL,
    active boolean NOT NULL default 't'
);


ALTER TABLE public.ad_zone OWNER TO phred;

--
-- Name: ad_zone_ad_zone_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_zone_ad_zone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_zone_ad_zone_id_seq OWNER TO phred;

--
-- Name: ad_zone_ad_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE ad_zone_ad_zone_id_seq OWNED BY ad_zone.ad_zone_id;


--
-- Name: ad_zone_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE ad_zone ALTER COLUMN ad_zone_id SET DEFAULT nextval('ad_zone_ad_zone_id_seq'::regclass);


--
-- Name: ad_zone_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad_zone
    ADD CONSTRAINT ad_zone_pkey PRIMARY KEY (ad_zone_id);


--
-- Name: account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_zone
    ADD CONSTRAINT account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

