// seoncd part of the ETL process
// scraping all the beers using the list of styles
const request = require('request-promise');
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
				return dbQuery(sqlHandler, [c, 'beers'], client); 
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

const apiBeerQuery = (style) => {
	const doReq = (pageIterator, style, cb) => {
		reqOpts.url = ENDPOINT + 'beers/?styleId=' + style + '&' + 'p=' + pageIterator + '&' + 'key=' + key;
		request(reqOpts).then((body) => {
			body = JSON.parse(body);
			totaldata[style] = totaldata[style].concat(body.data);
			if (pageIterator < body.numberOfPages) {
				return doReq(pageIterator + 1, style, cb);
			} // if
			return cb();
		}); // request
	}; // doReq

	return new Promise((resolve) => {
		request(reqOpts).then((body) => {
			return doReq(1, style, () => {
				console.log(totaldata[style].length + ' beers to insert in the database.');
				return resolve(load(totaldata[style]));
			})
		}) // request.then
		.catch((err) => {
			return console.error(`request for ${ reqOpts.url } failed: ${ err }`); // eslint-disable-line
		}); // request.catch
	}); // new Promise
}; //apiBeerQuery

// ETL for the beers
console.log('---- BEER TABLE ETL PROCESS ----');

return pool.connect((err, client, done) => {
	return client.query('SELECT webid, name FROM beer.styles WHERE webid::INT >= ' + parseInt(history['styleWebId']) + ' ORDER BY webid::INT ASC;', '', (err, res) => {
		console.log(res.rows.length + ' styles to iterate through ...');
		return Object.keys(res.rows).reduce((p, c) => {
			return p.then(() => {
				history['styleWebId'] = parseInt(res.rows[c].webid);
				fs.writeFile('../config/HISTORY.json', JSON.stringify(history), function (err) {
					if (err) return console.log(err);
				});
				totaldata[res.rows[c].webid] = [];
				console.log('Style : ' + res.rows[c].name + ' with webid : ' + res.rows[c].webid);
				return apiBeerQuery(res.rows[c].webid, client);
			}).catch((err) => {
				return console.error(err);
			}); // p.then
		}, Promise.resolve())
		.then(() => {
			done();
		});
	}); // client.query
}); // pool connect