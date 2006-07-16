-- table of URLs which are sub-requests (frames or iframes) and
-- shouldn't get ads

CREATE TABLE subrequest (
    url varchar(255) PRIMARY KEY,
    ts timestamp without time zone DEFAULT now()
);

