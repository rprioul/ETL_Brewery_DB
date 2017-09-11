CREATE OR REPLACE FUNCTION beer_insert_locationtype(
	name TEXT
	, displaytext TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	locationtypeid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.locationtypes
		(name, displaytext, created) VALUES
		(%L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING locationtypes.id;', $1, $2, $3);
	EXECUTE query
	INTO locationtypeid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.locationtypes WHERE name = %L;', $1);
		EXECUTE query INTO locationtypeid;
	END IF;

	RETURN locationtypeid;

END;
$$ LANGUAGE 'plpgsql';