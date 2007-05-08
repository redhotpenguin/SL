
CREATE TABLE url (
    url_id serial NOT NULL,
    url character varying(256),
    blacklisted boolean DEFAULT true,
    ts timestamp without time zone default now(),
    reg_id INTEGER NOT NULL
);

alter table only url add constraint url_pkey PRIMARY KEY (url_id);
create index url_index on url (url);
create unique index url_uniq_index on url(url);

ALTER TABLE ONLY url
    ADD CONSTRAINT reg_id_fkey FOREIGN KEY (reg_id) REFERENCES reg(reg_id)
    ON UPDATE CASCADE ON DELETE CASCADE;