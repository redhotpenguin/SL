-- table of hits for detecting rate-limit violations, should be
-- cleaned out frequently for best performance

CREATE TABLE rate_limit (
    -- user_id must be long enough for 2 ips and a long user-agent
    user_id varchar(150) PRIMARY KEY, 
    ts timestamp without time zone DEFAULT now()
);
