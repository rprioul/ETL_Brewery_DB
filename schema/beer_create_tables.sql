CREATE TABLE IF NOT EXISTS beer.countries (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, isocode TEXT DEFAULT '' UNIQUE
);

CREATE TABLE IF NOT EXISTS beer.servingtemp (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, displaytext TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS beer.locationtypes (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, displaytext TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS beer.srm (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, webid TEXT NOT NULL DEFAULT '' UNIQUE -- id returned from the API
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, hexcolor TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS beer.categories ( 
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, webid TEXT NOT NULL DEFAULT '' UNIQUE -- id returned from the API
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
);

CREATE TABLE IF NOT EXISTS beer.styles (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, webid TEXT NOT NULL DEFAULT '' UNIQUE -- id returned from the API
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, description TEXT DEFAULT ''
	, categoryid UUID REFERENCES beer.categories (id)
);

CREATE TABLE IF NOT EXISTS beer.beers (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, webid TEXT NOT NULL DEFAULT '' UNIQUE -- id returned from the API
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, styleid UUID REFERENCES beer.styles (id)
	, ibu NUMERIC(5, 0) DEFAULT 0 CONSTRAINT beer_positive_ibu CHECK (ibu >= 0) -- ibu must be positive
	, abv NUMERIC(3, 1) DEFAULT 0 CONSTRAINT beer_positive_abv CHECK (abv >= 0) -- abv must be positive
	, srmid UUID REFERENCES beer.srm (id)
	, servingtempid UUID REFERENCES beer.servingtemp (id)
	, organic BOOL NOT NULL DEFAULT FALSE
	, description TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS beer.breweries (
	id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
	, webid TEXT NOT NULL DEFAULT '' UNIQUE -- id returned from the API
	, created TIMESTAMPTZ NOT NULL DEFAULT now()
	, name TEXT NOT NULL DEFAULT '' UNIQUE
	, established INT NOT NULL DEFAULT 0
	, countryid UUID REFERENCES beer.countries (id)
	, locationid UUID REFERENCES beer.locationtypes (id)
	, lat NUMERIC(10, 6) DEFAULT 0
	, long NUMERIC(10, 6) DEFAULT 0
	, description TEXT DEFAULT ''
	, website TEXT DEFAULT ''
);