
CREATE TABLE url (
    url_id serial NOT NULL,
    url character varying(256),
    blacklisted boolean DEFAULT true
);
create index url_index on url (url);
create unique index url_uniq_index on url(url);
