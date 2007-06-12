CREATE TABLE router__reg (
    router_id      integer NOT NULL,
    reg_id          integer NOT NULL
);

ALTER TABLE ONLY router__reg
    ADD CONSTRAINT router__reg__pkey PRIMARY KEY (router_id, reg_id);

ALTER TABLE ONLY router__reg
    ADD CONSTRAINT router__reg__reg_id_fkey 
	FOREIGN KEY (reg_id) REFERENCES reg(reg_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY router__reg
    ADD CONSTRAINT router__reg__router_id_fkey 
	FOREIGN KEY (router_id) REFERENCES router(router_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

