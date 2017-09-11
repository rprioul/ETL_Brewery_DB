CREATE OR REPLACE FUNCTION beer_insert_brewery(
	webId TEXT
	, name TEXT
	, established INT
	, countryid UUID
	, locationtypeid UUID
	, lat NUMERIC(10,6)
	, long NUMERIC(10,6)
	, description TEXT
	, website TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	breweryid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.breweries
		(webid, name, established, countryid, locationid, lat, long, description, website, created) VALUES
		(%L, %L, %L, %L, %L, %L, %L, %L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING breweries.id;', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
	EXECUTE query
	INTO breweryid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.breweries WHERE webid = %L;', $1);
		EXECUTE query INTO breweryid;
	END IF;

	RETURN breweryid;

END;
$$ LANGUAGE 'plpgsql';