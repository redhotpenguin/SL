CREATE TABLE router__location (
    router_id      integer NOT NULL,
    location_id          integer NOT NULL,
    mts timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY router__location
    ADD CONSTRAINT router__location__pkey PRIMARY KEY (router_id, location_id);

ALTER TABLE ONLY router__location
    ADD CONSTRAINT router__location__location_id_fkey 
	FOREIGN KEY (location_id) REFERENCES location(location_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY router__location
    ADD CONSTRAINT router__location__router_id_fkey 
	FOREIGN KEY (router_id) REFERENCES router(router_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

