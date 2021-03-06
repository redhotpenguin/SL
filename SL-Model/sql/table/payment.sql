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
-- Name: payment; Type: TABLE; Schema: public; Owner: phred; Tablespace: 
--

CREATE TABLE payment (
    payment_id integer NOT NULL,
    account_id integer NOT NULL,
    amount money NOT NULL,
    start timestamp without time zone DEFAULT now() NOT NULL,
    stop timestamp without time zone NOT NULL,
    authorization_code text,
    error_message text,
    cts timestamp without time zone DEFAULT now() NOT NULL,
    approved boolean,
    last_four integer NOT NULL,
    card_type text NOT NULL,
    mac macaddr NOT NULL,
    ip inet NOT NULL,
    email text NOT NULL,
    md5 text NOT NULL,
    token_processed boolean DEFAULT false NOT NULL,
    expires text,
    voided boolean DEFAULT false,
    order_number text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.payment OWNER TO phred;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: phred
--

CREATE SEQUENCE payment_payment_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.payment_payment_id_seq OWNER TO phred;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phred
--

ALTER SEQUENCE payment_payment_id_seq OWNED BY payment.payment_id;


--
-- Name: payment_id; Type: DEFAULT; Schema: public; Owner: phred
--

ALTER TABLE payment ALTER COLUMN payment_id SET DEFAULT nextval('payment_payment_id_seq'::regclass);


--
-- Name: payment_pkey; Type: CONSTRAINT; Schema: public; Owner: phred; Tablespace: 
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- Name: payment_d5; Type: TRIGGER; Schema: public; Owner: phred
--

CREATE TRIGGER payment_d5
    BEFORE INSERT OR UPDATE ON payment
    FOR EACH ROW
    EXECUTE PROCEDURE payment_md5();


--
-- Name: payment_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: phred
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_account_id_fkey FOREIGN KEY (account_id) REFERENCES account(account_id);


--
-- PostgreSQL database dump complete
--

