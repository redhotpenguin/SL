CREATE TABLE router__account (
    router_id      integer NOT NULL,
    account_id          integer NOT NULL
);

ALTER TABLE ONLY router__account
    ADD CONSTRAINT router__account__pkey PRIMARY KEY (router_id, account_id);

ALTER TABLE ONLY router__account
    ADD CONSTRAINT router__account__account_id_fkey 
	FOREIGN KEY (account_id) REFERENCES account(account_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY router__account
    ADD CONSTRAINT router__account__router_id_fkey 
	FOREIGN KEY (router_id) REFERENCES router(router_id) 
	ON UPDATE CASCADE ON DELETE CASCADE;

