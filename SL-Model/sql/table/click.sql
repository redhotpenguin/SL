
CREATE TABLE click (
    click_id serial NOT NULL,
    cts timestamp without time zone DEFAULT now(),
    ad_id integer NOT NULL default 1,
    location_id integer NOT NULL default 1,
    user_id integer NOT NULL default 1,
    router_id integer NOT NULL default 1,
    referer text NOT NULL DEFAULT '',
	ip inet
);

ALTER TABLE ONLY click
    ADD CONSTRAINT click_pkey PRIMARY KEY (click_id);

ALTER TABLE ONLY click
    ADD CONSTRAINT ad_id_fkey FOREIGN KEY (ad_id) 
    REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY click
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id) 
    REFERENCES user(user_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY click
    ADD CONSTRAINT router_id_fkey FOREIGN KEY (router_id) 
    REFERENCES router(router_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY click
            ADD CONSTRAINT location_id_fkey FOREIGN KEY (location_id) 
            REFERENCES location(location_id) ON UPDATE CASCADE ON DELETE CASCADE;
