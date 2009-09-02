CREATE TABLE checkin (
    checkin_id serial NOT NULL PRIMARY KEY,
    router_id integer NOT NULL default 1,
    memfree integer NOT NULL default 0,
    users integer NOT NULL default 0,
    kbup integer NOT NULL default 0,
    kbdown integer NOT NULL default 0,
    cts timestamp without time zone default now()
);


ALTER TABLE ONLY checkin
    ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;
