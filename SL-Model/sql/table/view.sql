CREATE TABLE view (
    view_id serial NOT NULL,
    ad_id integer NOT NULL default 1,
    location_id integer NOT NULL default 1,
    user_id integer NOT default 1,
    router_id integer NOT NULL default 1,
    url text NOT NULL DEFAULT '',
    referer text NOT NULL DEFAULT '',
    cts timestamp without time zone default now()
);


ALTER TABLE ONLY view
    ADD CONSTRAINT view_pkey PRIMARY KEY (view_id);

ALTER TABLE ONLY view
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY view
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) REFERENCES user(user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY view
    ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY view
    ADD CONSTRAINT location_id_fkey FOREIGN KEY (location_id) REFERENCES location(location_id) ON UPDATE CASCADE ON DELETE CASCADE;

