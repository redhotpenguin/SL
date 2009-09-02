CREATE TABLE usertrack (
    usertrack_id serial NOT NULL PRIMARY KEY,
    router_id integer NOT NULL default 1,
    totalkb integer NOT NULL default 0,
    hostname text not null default '',
    kbup integer NOT NULL default 0,
    kbdown integer NOT NULL default 0,
    mac macaddr,
    cts timestamp without time zone default now()
);


ALTER TABLE ONLY usertrack
    ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;
