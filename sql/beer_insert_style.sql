CREATE OR REPLACE FUNCTION beer_insert_style(
	webId INT
	, name TEXT
	, description TEXT
	, categoryid UUID
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	styleid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.styles
		(webid, name, description, categoryid, created) VALUES
		(%L, %L, %L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING styles.id;', $1, $2, $3, $4, $5);
	EXECUTE query
	INTO styleid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.styles WHERE name = %L AND categoryid = %L;', $2, $4);
		EXECUTE query INTO styleid;
	END IF;

	RETURN styleid;

END;
$$ LANGUAGE 'plpgsql';