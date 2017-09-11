CREATE OR REPLACE FUNCTION beer_insert_srm(
	webId INT
	, name TEXT
	, hex TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	srmid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.srm
		(webid, name, hexColor, created) VALUES
		(%L, %L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING srm.id;', $1, $2, $3, $4);
	EXECUTE query
	INTO srmid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.srm WHERE webid = %L;', $1);
		EXECUTE query INTO srmid;
	END IF;

	RETURN srmid;

END;
$$ LANGUAGE 'plpgsql';