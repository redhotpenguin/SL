-- table of URLs which are sub-requests (frames or iframes) and
-- shouldn't get ads

CREATE TABLE subrequest (
    url varchar(1024) PRIMARY KEY,
    tag varchar(10) NOT NULL DEFAULT '',
    ts timestamp without time zone DEFAULT now()
);

