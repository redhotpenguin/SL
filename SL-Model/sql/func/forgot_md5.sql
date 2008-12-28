CREATE OR REPLACE FUNCTION forgot_md5() RETURNS trigger as $_$
    BEGIN
    UPDATE forgot SET expired = 't' WHERE reg_id = NEW.reg_id AND expired = 'f';
    NEW.link_md5 = md5(' || NEW.reg_id || NEW.ts || random() || ');
    RETURN NEW;
END;
$_$
language plpgsql;

