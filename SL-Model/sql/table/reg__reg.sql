CREATE TABLE reg__reg (
    first_reg_id INTEGER NOT NULL,
    sec_reg_id INTEGER NOT NULL
);
 
ALTER TABLE ONLY reg__reg
    ADD CONSTRAINT reg__reg__pkey PRIMARY KEY (first_reg_id, sec_reg_id);

ALTER TABLE ONLY reg__reg
    ADD CONSTRAINT first_reg_fkey FOREIGN KEY (first_reg_id) 
	REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY reg__reg
    ADD CONSTRAINT sec_reg_fkey FOREIGN KEY (sec_reg_id) 
	REFERENCES reg(reg_id) ON UPDATE CASCADE ON DELETE CASCADE;

