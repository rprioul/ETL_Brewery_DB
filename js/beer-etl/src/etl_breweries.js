// last part of the etl process
// scraping all the breweries using year criteria
const request = require('request-promise');
const moment = require('moment');
const pg = require('pg');
const fs = require('fs');
const dbconf = require('../config/DBCONFIG_DEV.json');

let history = require('../config/HISTORY.json');

const ENDPOINT = 'http://api.brewerydb.com/v2/';
const key = 'INSERT YOUR KEY HERE';

const menuNames = {
	BEERTEMP : 'beer-temperature',
	LOCTYPE : 'location-types',
	STYLE : 'styles',
	COUNTRY : 'countries',
	SRM : 'srm',
};

const pool = new pg.Pool(dbconf);
sqlHandler = 'SELECT * FROM beer_result_handler($1, $2);';

const reqOpts = {
    method: 'GET',
    url: ENDPOINT,
};

const totaldata = {};

const dbQuery = (statement, params, client) => {
	return new Promise((resolve, reject) => {
		return client.query(statement, params, (err, res) => {
			if (err) return reject(err);
			return resolve(res);
		}); // client.query
	}); // return new Promise
}; // dbQuery

const load = (data) => {
	pool.connect((err, client, done) => {
		if (err) return console.error(err);
		const errs = [];
		data.reduce((p, c) => {
			return p.then(() => {
				return dbQuery(sqlHandler, [c, 'breweries'], client); 
			}).catch((err) => {
				errs.push(err, c);
			}); // return p.then
		}, Promise.resolve())
    	.then(() => {
       		done();
       		return console.log(`inserted ${ data.length } rows with ${ errs.length } errs: ${ errs }`);
		}).catch((err) => {
        	done();
        	return console.error(`error in loading: ${ err }`);
		}); // data.reduce
	});
}

const apiBreweryQuery = (year) => {
	const doReq = (pageIterator, year, cb) => {
		reqOpts.url = ENDPOINT + 'breweries/?established=' + year + '&' + 'p=' + pageIterator + '&' + 'key=' + key;
		request(reqOpts).then((body) => {
			body = JSON.parse(body);
			if (body.hasOwnProperty('data')) {
				totaldata[year] = totaldata[year].concat(body.data);
			}
			if (pageIterator < body.numberOfPages) {
				return doReq(pageIterator + 1, year, cb);
			}
			return cb();
		}); // request
	}; // doReq

	return new Promise((resolve) => {
		request(reqOpts).then((body) => {
			return doReq(1, year, () => {
				if(totaldata[year].length == 0) {
					console.log('No breweries to insert in the database, moving to next year');
					return resolve();
				}
				else {
					console.log(totaldata[year].length + ' breweries to insert in the database.');
					return resolve(load(totaldata[year]));
				}
			});
		}) // request.then
		.catch((err) => {
			return console.error(`request for ${ reqOpts.url } failed: ${ err }`); // eslint-disable-line
		}); // request.catch
	}); // new Promise
}; // apiBreweryQuery

const doYears = ((stored) => {
	let earliest = Math.min(history['breweryYear'], stored);
	let years = [];
	while (earliest <= parseInt(moment().format('YYYY'))) {
		years.push(earliest++);
	}
	console.log('Iterating through ' + years.length + ' years starting with ' + history['breweryYear']);
	return years;
});

// ETL for the breweries
console.log('---- BREWERY TABLE ETL PROCESS ----');

pool.connect((err, client, done) => {
	return client.query('SELECT MAX(established) as max FROM beer.breweries;', '', (err, res) => {
		return doYears(res.rows[0].max).reduce((p, c) => {
			totaldata[c] = [];
			return p.then(() => {
				history['breweryYear'] = parseInt(c);
				fs.writeFile('../config/HISTORY.json', JSON.stringify(history), function (err) {
					if (err) return console.log(err);
				});
				console.log('Year : ' + c);
				return apiBreweryQuery(c, client);
			}).catch((err) => {
				return console.error(err);
			}); // p.then
		}, Promise.resolve())
		.then(() => {
			done();
		});
	});
}); // pool connect