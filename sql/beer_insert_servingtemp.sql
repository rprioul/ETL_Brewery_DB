CREATE OR REPLACE FUNCTION beer_insert_servingtemp(
	name TEXT
	, displaytext TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	servingtempid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.servingtemp
		(name, displaytext, created) VALUES
		(%L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING servingtemp.id;', $1, $2, $3);
	EXECUTE query
	INTO servingtempid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.servingtemp WHERE name = %L;', $1);
		EXECUTE query INTO servingtempid;
	END IF;

	RETURN servingtempid;

END;
$$ LANGUAGE 'plpgsql';