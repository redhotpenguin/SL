
CREATE TABLE user_blacklist (
    -- user_id must be long enough for 1 ip, a domain, and a long user-agent
    user_id varchar(256) PRIMARY KEY,
    ts timestamp without time zone DEFAULT now()
);
