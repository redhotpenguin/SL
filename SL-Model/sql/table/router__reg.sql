CREATE TABLE router_reg (
    router_id      integer NOT NULL,
    reg_id          integer NOT NULL
);

ALTER TABLE ONLY router_reg
    ADD CONSTRAINT router_reg_pkey PRIMARY KEY (router_id, reg_id);

ALTER TABLE ONLY router_reg
    ADD CONSTRAINT router_ad_id_fkey 
	FOREIGN KEY (reg_id) REFERENCES reg(reg_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY router_reg
    ADD CONSTRAINT router_id_fkey 
	FOREIGN KEY (router_id) REFERENCES router(router_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

