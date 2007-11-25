create or replace function update_modified_column() returns trigger as $$ BEGIN
create or replace function update_modified_column() returns trigger as $$ BEGIN
NEW.mts = now();
return new;
END;
$$ language 'plpgsql';