CREATE OR REPLACE FUNCTION beer_insert_beer(
	webId TEXT
	, name TEXT
	, styleid UUID
	, ibu NUMERIC(5, 0)
	, abv NUMERIC(3, 1)
	, srmid UUID
	, servingtempid UUID
	, organic TEXT
	, description TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	beerid UUID;
	query TEXT;
	isOrganic BOOL;
BEGIN
	
	IF organic = 'Y' THEN 
		isOrganic := TRUE;
	ELSE 
		isOrganic := FALSE;
	END IF;

	query :=
	format('INSERT INTO beer.beers
		(webid, name, styleid, ibu, abv, srmid, servingtempid, organic, description, created) VALUES
		(%L, %L, %L, %L, %L, %L, %L, %L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING beers.id;', $1, $2, $3, $4, $5, $6, $7, isOrganic, $9, $10);
	EXECUTE query
	INTO beerid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.beers WHERE webid = %L;', $1);
		EXECUTE query INTO beerid;
	END IF;

	RETURN beerid;

END;
$$ LANGUAGE 'plpgsql';