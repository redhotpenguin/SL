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
-- Name: ad_zone; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_zone (
    ad_zone_id integer NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    account_id integer NOT NULL,
    ad_size_id integer NOT NULL,
    active boolean DEFAULT true NOT NULL,
    bug_id integer DEFAULT 1 NOT NULL,
    reg_id integer DEFAULT 1 NOT NULL,
    code_double text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.ad_zone OWNER TO phred;

--
-- Name: ad_zone_ad_zone_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_zone_ad_zone_id_seq
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
-- Name: ad_size_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_zone
    ADD CONSTRAINT ad_size_id_fkey FOREIGN KEY (ad_size_id) REFERENCES ad_size(ad_size_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_zone_bug_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_zone
    ADD CONSTRAINT ad_zone_bug_id_fkey FOREIGN KEY (bug_id) REFERENCES bug(bug_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_zone_reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_zone
    ADD CONSTRAINT ad_zone_reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

