CREATE OR REPLACE FUNCTION link_md5() RETURNS trigger as $_$
    BEGIN
    NEW.md5 = md5(NEW.uri);
    RETURN NEW;
END;
$_$
language plpgsql;

