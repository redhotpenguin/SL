CREATE TABLE payment (
    payment_id serial NOT NULL,
    reg_id integer NOT NULL,
    cts timestamp without time zone default now(),
    start_ts timestamp without time zone,
    finish_ts timestamp without time zone,
    paid_ts timestamp without time zone,
    approved_ts timestamp without time zone,
    approved boolean default 'f',
    approved_reg_id integer not null default 1,
    num_views integer not null,
    cpm money not null,
    amount money not null,
    pp_timestamp timestamp with time zone,
    pp_correlation_id text default '',
    pp_version text default '',
    pp_build text default '',
    paid boolean default 'f'
);


ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);

ALTER TABLE ONLY payment
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


