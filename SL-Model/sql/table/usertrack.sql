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
-- Name: usertrack; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE usertrack (
    usertrack_id integer NOT NULL,
    router_id integer DEFAULT 1 NOT NULL,
    totalkb integer DEFAULT 0 NOT NULL,
    hostname text DEFAULT ''::text NOT NULL,
    kbup integer DEFAULT 0 NOT NULL,
    kbdown integer DEFAULT 0 NOT NULL,
    kbtotal integer DEFAULT 0 NOT NULL,
    mac macaddr,
    cts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.usertrack OWNER TO phred;

--
-- Name: usertrack_usertrack_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE usertrack_usertrack_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.usertrack_usertrack_id_seq OWNER TO phred;

--
-- Name: usertrack_usertrack_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE usertrack_usertrack_id_seq OWNED BY usertrack.usertrack_id;


--
-- Name: usertrack_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE usertrack ALTER COLUMN usertrack_id SET DEFAULT nextval('usertrack_usertrack_id_seq'::regclass);


--
-- Name: usertrack_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY usertrack
    ADD CONSTRAINT usertrack_pkey PRIMARY KEY (usertrack_id);


--
-- Name: router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY usertrack
    ADD CONSTRAINT usertrack__router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

