CREATE OR REPLACE FUNCTION beer_insert_category(
	webId INT
	, name TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	categoryid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.categories
		(webid, name, created) VALUES
		(%L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING categories.id;', $1, $2, $3);
	EXECUTE query
	INTO categoryid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.categories WHERE name = %L', $2);
		EXECUTE query INTO categoryid;
	END IF;

	RETURN categoryid;

END;
$$ LANGUAGE 'plpgsql';