
CREATE TABLE linkshare (
    linkshare_id serial NOT NULL,
    mname varchar(128) NOT NULL,
	mid integer NOT NULL,
	linkID integer NOT NULL,
	linkName varchar(128),
	linkUrl varchar(256),
	trackUrl varchar(256),
	category varchar(64),
    displayText varchar(256),
    active boolean default 't',
    ts timestamp without time zone default now()
);

ALTER TABLE ONLY linkshare
    ADD CONSTRAINT linkshare_pkey PRIMARY KEY (linkshare_id);

