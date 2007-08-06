CREATE TABLE ad_group (
    ad_group_id serial NOT NULL,
	active boolean DEFAULT true,
    name character varying(256),
    cts timestamp without time zone default now (),
    mts timestamp without time zone default now (),
    css_url text default 'http://www.redhotpenguin.com/css/sl.css' NOT NULL,
    template text default 'text_ad.tmpl' NOT NULL,
    is_default boolean default 'f',
    bug_id integer not null default 1,
    reg_id integer not null default 14
);

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group_pkey PRIMARY KEY (ad_group_id);

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group__bug_id_fkey 
	FOREIGN KEY (bug_id) REFERENCES bug(bug_id) 
	ON UPDATE CASCADE;

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group__reg_id_fkey 
	FOREIGN KEY (reg_id) REFERENCES reg(reg_id) 
	ON UPDATE CASCADE;

