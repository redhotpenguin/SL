--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

--
-- Name: ad_md5(); Type: FUNCTION; Schema: public; Owner: phred
--

CREATE FUNCTION ad_md5() RETURNS "trigger"
    AS $$
    BEGIN
    NEW.md5 = md5(NEW.cts);
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.ad_md5() OWNER TO phred;

--
-- Name: forgot_md5(); Type: FUNCTION; Schema: public; Owner: phred
--

CREATE FUNCTION forgot_md5() RETURNS "trigger"
    AS $$
    BEGIN
    UPDATE forgot SET expired = 't' WHERE reg_id = NEW.reg_id AND expired = 'f';
    NEW.link_md5 = md5(NEW.reg_id || NEW.ts || random());
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.forgot_md5() OWNER TO phred;

--
-- Name: link_md5(); Type: FUNCTION; Schema: public; Owner: phred
--

CREATE FUNCTION link_md5() RETURNS "trigger"
    AS $$
    BEGIN
    NEW.md5 = md5(NEW.uri);
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.link_md5() OWNER TO phred;

--
-- Name: update_modified_column(); Type: FUNCTION; Schema: public; Owner: phred
--

CREATE FUNCTION update_modified_column() RETURNS "trigger"
    AS $$ BEGIN
NEW.mts = now();
return new;
END;
$$
    LANGUAGE plpgsql;


ALTER FUNCTION public.update_modified_column() OWNER TO phred;

--
-- Name: ad_ad_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_ad_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_ad_id_seq OWNER TO phred;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: ad; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad (
    ad_id integer DEFAULT nextval('ad_ad_id_seq'::regclass) NOT NULL,
    active boolean DEFAULT false,
    md5 character varying(32),
    cts timestamp without time zone DEFAULT now(),
    ad_group_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.ad OWNER TO phred;

--
-- Name: ad_group; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_group (
    ad_group_id integer NOT NULL,
    active boolean DEFAULT true,
    name character varying(256),
    cts timestamp without time zone DEFAULT now(),
    css_url text DEFAULT 'http://www.redhotpenguin.com/css/sl.css'::text NOT NULL,
    "template" text DEFAULT 'text_ad.tmpl'::text NOT NULL,
    bug_id integer DEFAULT 1 NOT NULL,
    is_default boolean DEFAULT false,
    reg_id integer DEFAULT 14 NOT NULL
);


ALTER TABLE public.ad_group OWNER TO phred;

--
-- Name: ad_group_ad_group_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_group_ad_group_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_group_ad_group_id_seq OWNER TO phred;

--
-- Name: ad_group_ad_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE ad_group_ad_group_id_seq OWNED BY ad_group.ad_group_id;


--
-- Name: ad_linkshare_ad_linkshare_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_linkshare_ad_linkshare_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_linkshare_ad_linkshare_id_seq OWNER TO phred;

--
-- Name: ad_linkshare; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_linkshare (
    ad_linkshare_id integer DEFAULT nextval('ad_linkshare_ad_linkshare_id_seq'::regclass) NOT NULL,
    ad_id integer NOT NULL,
    mname character varying(128) NOT NULL,
    mid integer NOT NULL,
    linkid integer NOT NULL,
    linkname character varying(128),
    linkurl character varying(256),
    trackurl character varying(256),
    category character varying(64),
    displaytext character varying(256),
    mts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ad_linkshare OWNER TO phred;

--
-- Name: ad_sl_ad_sl_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE ad_sl_ad_sl_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.ad_sl_ad_sl_id_seq OWNER TO phred;

--
-- Name: ad_sl; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE ad_sl (
    ad_sl_id integer DEFAULT nextval('ad_sl_ad_sl_id_seq'::regclass) NOT NULL,
    ad_id integer NOT NULL,
    text character varying(256),
    reg_id integer DEFAULT 1 NOT NULL,
    uri character varying(512),
    mts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ad_sl OWNER TO phred;

--
-- Name: bug; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE bug (
    bug_id integer NOT NULL,
    image_href text DEFAULT 'http://www.redhotpenguin.com/images/sl/free_wireless.gif'::text NOT NULL,
    link_href text DEFAULT 'http://64.151.90.20:81/click/795da10ca01f942fd85157d8be9e832e'::text,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    reg_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.bug OWNER TO phred;

--
-- Name: bug_bug_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE bug_bug_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.bug_bug_id_seq OWNER TO phred;

--
-- Name: bug_bug_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE bug_bug_id_seq OWNED BY bug.bug_id;


--
-- Name: click_click_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE click_click_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.click_click_id_seq OWNER TO phred;

--
-- Name: click; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE click (
    click_id integer DEFAULT nextval('click_click_id_seq'::regclass) NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    ad_id integer NOT NULL,
    ip inet
);


ALTER TABLE public.click OWNER TO phred;

--
-- Name: forgot_forgot_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE forgot_forgot_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.forgot_forgot_id_seq OWNER TO phred;

--
-- Name: forgot; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE forgot (
    forgot_id integer DEFAULT nextval('forgot_forgot_id_seq'::regclass) NOT NULL,
    reg_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    link_md5 character varying(32) NOT NULL,
    expired boolean DEFAULT false
);


ALTER TABLE public.forgot OWNER TO phred;

--
-- Name: location; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE "location" (
    location_id integer NOT NULL,
    ip inet NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    street_addr character varying(64),
    apt_suite character varying(5),
    zip character varying(9),
    city character varying(128),
    state character varying(2),
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    active boolean DEFAULT true,
    default_ok boolean DEFAULT true,
    custom_rate_limit character varying(10)
);


ALTER TABLE public."location" OWNER TO phred;

--
-- Name: location__ad_group; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE location__ad_group (
    location_id integer NOT NULL,
    ad_group_id integer NOT NULL
);


ALTER TABLE public.location__ad_group OWNER TO phred;

--
-- Name: location_location_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE location_location_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.location_location_id_seq OWNER TO phred;

--
-- Name: location_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE location_location_id_seq OWNED BY "location".location_id;


--
-- Name: rate_limit; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE rate_limit (
    user_id character varying(150) NOT NULL,
    ts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.rate_limit OWNER TO phred;

--
-- Name: reg_reg_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE reg_reg_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.reg_reg_id_seq OWNER TO phred;

--
-- Name: reg; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE reg (
    reg_id integer DEFAULT nextval('reg_reg_id_seq'::regclass) NOT NULL,
    email character varying(64) DEFAULT ''::character varying NOT NULL,
    zipcode character varying(10) DEFAULT ''::character varying,
    firstname character varying(32),
    lastname character varying(32),
    description text,
    street_addr character varying(64),
    apt_suite character varying(5),
    referer character varying(32),
    phone character varying(14),
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now(),
    sponsor character varying(64),
    street_addr2 character varying(64),
    city character varying(64),
    state character(2),
    active boolean DEFAULT true,
    report_email character varying(64) DEFAULT ''::character varying,
    password_md5 character varying(32),
    send_reports_daily boolean DEFAULT false,
    send_reports_weekly boolean DEFAULT false,
    send_reports_monthly boolean DEFAULT false,
    send_reports_quarterly boolean DEFAULT false,
    report_email_frequency character varying(16) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.reg OWNER TO phred;

--
-- Name: reg__ad_group; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE reg__ad_group (
    reg_id integer NOT NULL,
    ad_group_id integer NOT NULL
);


ALTER TABLE public.reg__ad_group OWNER TO phred;

--
-- Name: reg__reg; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE reg__reg (
    first_reg_id integer NOT NULL,
    sec_reg_id integer NOT NULL
);


ALTER TABLE public.reg__reg OWNER TO phred;

--
-- Name: root_root_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE root_root_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.root_root_id_seq OWNER TO phred;

--
-- Name: root; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE root (
    root_id integer DEFAULT nextval('root_root_id_seq'::regclass) NOT NULL,
    reg_id integer NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    mts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.root OWNER TO phred;

--
-- Name: router_router_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE router_router_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.router_router_id_seq OWNER TO phred;

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
    replace_port smallint DEFAULT 8135,
    description text,
    name text,
    feed_google boolean DEFAULT false,
    feed_linkshare boolean DEFAULT false,
    splash_timeout integer DEFAULT 60,
    splash_href text DEFAULT ''::text,
    firmware_version character varying(4) DEFAULT ''::character varying,
    ssid text DEFAULT ''::text,
    firmware_event text DEFAULT ''::text,
    ssid_event text DEFAULT ''::text,
    passwd_event text DEFAULT ''::text
);


ALTER TABLE public.router OWNER TO phred;

--
-- Name: router__ad_group; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router__ad_group (
    router_id integer NOT NULL,
    ad_group_id integer NOT NULL
);


ALTER TABLE public.router__ad_group OWNER TO phred;

--
-- Name: router__location; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router__location (
    router_id integer NOT NULL,
    location_id integer NOT NULL
);


ALTER TABLE public.router__location OWNER TO phred;

--
-- Name: router__reg; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE router__reg (
    router_id integer NOT NULL,
    reg_id integer NOT NULL
);


ALTER TABLE public.router__reg OWNER TO phred;

--
-- Name: subrequest; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE subrequest (
    url text NOT NULL,
    ts timestamp without time zone DEFAULT now(),
    tag character varying(10) DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.subrequest OWNER TO phred;

--
-- Name: url_url_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE url_url_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.url_url_id_seq OWNER TO phred;

--
-- Name: url; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE url (
    url_id integer DEFAULT nextval('url_url_id_seq'::regclass) NOT NULL,
    url character varying(256),
    blacklisted boolean DEFAULT true,
    reg_id integer NOT NULL,
    ts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.url OWNER TO phred;

--
-- Name: user_blacklist; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE user_blacklist (
    user_id character varying(256) NOT NULL,
    ts timestamp without time zone DEFAULT now()
);


ALTER TABLE public.user_blacklist OWNER TO phred;

--
-- Name: view_view_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE view_view_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.view_view_id_seq OWNER TO phred;

--
-- Name: view; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE "view" (
    view_id integer DEFAULT nextval('view_view_id_seq'::regclass) NOT NULL,
    ad_id integer NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    ip inet
);


ALTER TABLE public."view" OWNER TO phred;

--
-- Name: ad_group_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE ad_group ALTER COLUMN ad_group_id SET DEFAULT nextval('ad_group_ad_group_id_seq'::regclass);


--
-- Name: bug_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE bug ALTER COLUMN bug_id SET DEFAULT nextval('bug_bug_id_seq'::regclass);


--
-- Name: location_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE "location" ALTER COLUMN location_id SET DEFAULT nextval('location_location_id_seq'::regclass);


--
-- Name: ad_group_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group_pkey PRIMARY KEY (ad_group_id);


--
-- Name: ad_linkshare_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad_linkshare
    ADD CONSTRAINT ad_linkshare_pkey PRIMARY KEY (ad_linkshare_id);


--
-- Name: ad_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad_pkey PRIMARY KEY (ad_id);


--
-- Name: ad_sl_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY ad_sl
    ADD CONSTRAINT ad_sl_pkey PRIMARY KEY (ad_sl_id);


--
-- Name: bug_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY bug
    ADD CONSTRAINT bug_pkey PRIMARY KEY (bug_id);


--
-- Name: click_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY click
    ADD CONSTRAINT click_pkey PRIMARY KEY (click_id);


--
-- Name: forgot_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY forgot
    ADD CONSTRAINT forgot_pkey PRIMARY KEY (forgot_id);


--
-- Name: location__ad_group__pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY location__ad_group
    ADD CONSTRAINT location__ad_group__pkey PRIMARY KEY (location_id, ad_group_id);


--
-- Name: location_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY "location"
    ADD CONSTRAINT location_pkey PRIMARY KEY (location_id);


--
-- Name: rate_limit_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY rate_limit
    ADD CONSTRAINT rate_limit_pkey PRIMARY KEY (user_id);


--
-- Name: reg__reg__pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY reg__reg
    ADD CONSTRAINT reg__reg__pkey PRIMARY KEY (first_reg_id, sec_reg_id);


--
-- Name: reg_ad_group_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY reg__ad_group
    ADD CONSTRAINT reg_ad_group_pkey PRIMARY KEY (reg_id, ad_group_id);


--
-- Name: reg_id_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY reg
    ADD CONSTRAINT reg_id_pkey PRIMARY KEY (reg_id);


--
-- Name: root_id_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY root
    ADD CONSTRAINT root_id_pkey PRIMARY KEY (root_id);


--
-- Name: router__location__pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router__location
    ADD CONSTRAINT router__location__pkey PRIMARY KEY (router_id, location_id);


--
-- Name: router_ad_group_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router__ad_group
    ADD CONSTRAINT router_ad_group_pkey PRIMARY KEY (router_id, ad_group_id);


--
-- Name: router_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router
    ADD CONSTRAINT router_pkey PRIMARY KEY (router_id);


--
-- Name: router_reg_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY router__reg
    ADD CONSTRAINT router_reg_pkey PRIMARY KEY (router_id, reg_id);


--
-- Name: subrequest_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY subrequest
    ADD CONSTRAINT subrequest_pkey PRIMARY KEY (url);


--
-- Name: url_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY url
    ADD CONSTRAINT url_pkey PRIMARY KEY (url_id);


--
-- Name: user_blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY user_blacklist
    ADD CONSTRAINT user_blacklist_pkey PRIMARY KEY (user_id);


--
-- Name: view_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY "view"
    ADD CONSTRAINT view_pkey PRIMARY KEY (view_id);


--
-- Name: click_ip_idx; Type: INDEX; Schema: public; Owner: phred; Tablespace: 
--

CREATE INDEX click_ip_idx ON click USING btree (ip);


--
-- Name: url_index; Type: INDEX; Schema: public; Owner: phred; Tablespace: 
--

CREATE INDEX url_index ON url USING btree (url);


--
-- Name: url_uniq_index; Type: INDEX; Schema: public; Owner: phred; Tablespace: 
--

CREATE UNIQUE INDEX url_uniq_index ON url USING btree (url);


--
-- Name: view_ip_idx; Type: INDEX; Schema: public; Owner: phred; Tablespace: 
--

CREATE INDEX view_ip_idx ON "view" USING btree (ip);


--
-- Name: forgot_md5; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER forgot_md5
    BEFORE INSERT ON forgot
    FOR EACH ROW
    EXECUTE PROCEDURE forgot_md5();


--
-- Name: md5; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER md5
    BEFORE INSERT OR UPDATE ON ad
    FOR EACH ROW
    EXECUTE PROCEDURE ad_md5();


--
-- Name: update_router_mts; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER update_router_mts
    BEFORE UPDATE ON router
    FOR EACH ROW
    EXECUTE PROCEDURE update_modified_column();


--
-- Name: ad__ad_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad
    ADD CONSTRAINT ad__ad_group_id_fkey FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_group__bug_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group__bug_id_fkey FOREIGN KEY (bug_id) REFERENCES bug(bug_id) ON UPDATE CASCADE;


--
-- Name: ad_group__reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group__reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE;


--
-- Name: ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_linkshare
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_sl
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY click
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY "view"
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ad_sl_reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY ad_sl
    ADD CONSTRAINT ad_sl_reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: bug__reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY bug
    ADD CONSTRAINT bug__reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE;


--
-- Name: first_reg_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY reg__reg
    ADD CONSTRAINT first_reg_fkey FOREIGN KEY (first_reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: location__ad_group__ad_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY location__ad_group
    ADD CONSTRAINT location__ad_group__ad_group_id_fkey FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: location__ad_group__location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY location__ad_group
    ADD CONSTRAINT location__ad_group__location_id_fkey FOREIGN KEY (location_id) REFERENCES "location"(location_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reg__ad_group__ad_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY reg__ad_group
    ADD CONSTRAINT reg__ad_group__ad_group_id_fkey FOREIGN KEY (ad_group_id) REFERENCES ad_group(ad_group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY root
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY forgot
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY url
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reg_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY reg__ad_group
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router__location__location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__location
    ADD CONSTRAINT router__location__location_id_fkey FOREIGN KEY (location_id) REFERENCES "location"(location_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router__location__router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__location
    ADD CONSTRAINT router__location__router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router_ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__reg
    ADD CONSTRAINT router_ad_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__ad_group
    ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: router_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY router__reg
    ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sec_reg_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY reg__reg
    ADD CONSTRAINT sec_reg_fkey FOREIGN KEY (sec_reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

