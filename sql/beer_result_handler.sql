CREATE OR REPLACE FUNCTION beer_result_handler(
	result JSON
	, resultName TEXT
) RETURNS UUID AS
$$
DECLARE
	created TIMESTAMPTZ;
	returnCode UUID;
	categoryid UUID;
	styleid UUID;
	srmid UUID;
	servingtempid UUID;
	locationtypeid UUID;
	countryid UUID;
	organic TEXT;
	description TEXT;

BEGIN
	
	created := now();

	CASE
		WHEN resultName = 'countries' THEN
			returnCode := beer_insert_country(result->>'displayName'::TEXT, result->>'isoCode'::TEXT, created);
		WHEN resultName = 'srm' THEN
			returnCode := beer_insert_srm((result->>'id'::TEXT)::INT, result->>'name'::TEXT, result->>'hex'::TEXT, created);
		WHEN resultName = 'styles' THEN
			categoryid := beer_insert_category((((result#>'{category}')->>'id')::TEXT)::INT, ((result#>'{category}')->>'name')::TEXT, created);
			returnCode = beer_insert_style((result->>'id'::TEXT)::INT, result->>'name'::TEXT, result->>'description'::TEXT, categoryid, created);
		WHEN resultName = 'beer-temperature' THEN
			returnCode := beer_insert_servingtemp(result->>'name'::TEXT, result->>'displaytext'::TEXT, created);
		WHEN resultName = 'location-types' THEN
			returnCode := beer_insert_locationtype(result->>'name'::TEXT, result->>'displaytext'::TEXT, created);
		WHEN resultName = 'beers' THEN
			-- srm, serving temperature, organic and description info are not always present in the API
			-- necessary though ? Worth investigating later on
			IF result->>'srmId' IS NOT NULL THEN
				srmid := beer_insert_srm((result->>'srmId'::TEXT)::INT, ''::TEXT, ''::TEXT, created);
			ELSE srmid := NULL;
			END IF;
			
			IF result->>'servingTemperature' IS NOT NULL THEN
				servingtempid := beer_insert_servingtemp(result->>'servingTemperature'::TEXT, ''::TEXT, created);
			ELSE servingtempid := NULL;
			END IF;

			IF result->>'organic' IS NOT NULL THEN
				organic := result->>'organic'::TEXT;
			ELSE organic := 'N';
			END IF;

			IF result->>'description' IS NOT NULL THEN
				description := result->>'description'::TEXT;
			ELSE description := '';
			END IF;

			categoryid := beer_insert_category(
				(((result#>'{style, category}')->>'id')::TEXT)::INT
				, ((result#>'{style, category}')->>'name')::TEXT
				, created
			);
			styleid := beer_insert_style(
				(((result#>'{style}')->>'id')::TEXT)::INT
				, ((result#>'{style}')->>'name')::TEXT
				, ((result#>'{style}')->>'description')::TEXT
				, categoryid
				, created
			);
			
			returnCode := beer_insert_beer(
				result->>'id'::TEXT
				, result->>'name'::TEXT
				, styleid
				, ((result->>'ibu')::TEXT)::NUMERIC(5, 0)
				, ((result->>'abv')::TEXT)::NUMERIC(3, 1)
				, srmid
				, servingtempid
				, organic -- comes under string Y or N
				, description
				, created
			);
		WHEN resultName = 'breweries' THEN
			
			IF result->>'country' IS NOT NULL THEN
				countryid := beer_insert_country(
					((result#>'{country}')->>'displayName')::TEXT
					, ((result#>'{country}')->>'isoCode')::TEXT
					, created
				);
			ELSE countryid := NULL;
			END IF;

			IF result->>'locationType' IS NOT NULL THEN
				locationtypeid := beer_insert_locationtype(
					result->>'locationType'::TEXT
					, created
				);
			ELSE locationtypeid := NULL;
			END IF;

			returnCode := beer_insert_brewery(
				result->>'id'::TEXT
				, result->>'name'::TEXT
				, (result->>'established'::TEXT)::INT
				, countryid
				, locationtypeid
				, ((result->>'latitude')::TEXT)::NUMERIC(10,6)
				, ((result->>'longitude')::TEXT)::NUMERIC(10,6)
				, result->>'description'::TEXT
				, result->>'website'::TEXT
				, created
			);
	END CASE;

	RETURN returnCode;

END;
$$ LANGUAGE 'plpgsql';
