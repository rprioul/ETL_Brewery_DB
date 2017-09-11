CREATE OR REPLACE FUNCTION beer_insert_country(
	name TEXT
	, isoCode TEXT
	, created TIMESTAMPTZ
) RETURNS UUID AS
$$
DECLARE
	countryid UUID;
	query TEXT;
BEGIN

	query :=
	format('INSERT INTO beer.countries
		(name, isoCode, created) VALUES
		(%L, %L, %L)
		ON CONFLICT DO NOTHING
		RETURNING countries.id;', $1, $2, $3);
	EXECUTE query
	INTO countryid;

	IF NOT FOUND THEN
		query := format('SELECT id FROM beer.countries WHERE name = %L AND isocode = %L;', $2, $3);
		EXECUTE query INTO countryid;
	END IF;

	RETURN countryid;

END;
$$ LANGUAGE 'plpgsql';