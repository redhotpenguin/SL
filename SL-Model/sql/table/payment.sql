CREATE TABLE payment (
    payment_id serial NOT NULL,
    reg_id integer NOT NULL,
    cts timestamp without time zone default now(),
    pts timestamp without time zone,
    approved boolean default 'f',
    approved_reg_id integer
);


ALTER TABLE ONLY payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);

ALTER TABLE ONLY payment
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;


