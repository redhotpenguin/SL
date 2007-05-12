CREATE OR REPLACE FUNCTION ad_md5() RETURNS trigger as $_$
    BEGIN
    NEW.md5 = md5(NEW.cts);
    RETURN NEW;
END;
$_$
language plpgsql;

