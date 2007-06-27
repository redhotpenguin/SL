CREATE TABLE ad_group (
    ad_group_id serial NOT NULL,
	active boolean DEFAULT true,
    name character varying(256),
    cts timestamp without time zone default now (),
    mts timestamp without time zone default now (),
    css_url text default 'http://www.redhotpenguin.com/css/sl.css' NOT NULL,
    template text default 'text_ad.tmpl' NOT NULL
);

ALTER TABLE ONLY ad_group
    ADD CONSTRAINT ad_group_pkey PRIMARY KEY (ad_group_id);
