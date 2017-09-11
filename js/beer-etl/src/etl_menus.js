// First part of etl process 
// Data that can be retrieved through /menu/
const request = require('request-promise');
const pg = require('pg')
const dbconf = require('../config/DBCONFIG_DEV.json');

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

const dbQuery = (statement, params, client) => {
return new Promise((resolve, reject) => {
	return client.query(statement, params, (err, res) => {
		if (err) return reject(err);
			return resolve(res);
		}); // client.query
	}); // return new Promise
}; // dbQuery

const load = (data, menu) => {
	pool.connect((err, client, done) => {
		if (err) return console.error(err);
		const errs = [];
		if(menu == 'beer-temperature' || menu == 'location-types') {
			console.log(Object.keys(data).length + ' ' + menu + ' retrieved from the API');
			Object.keys(data).reduce((p,c) => {
				return p.then(() => {
					return dbQuery(sqlHandler, [{"name":c, "displaytext":data[c]}, menu], client); 
				}).catch((err) => {
					errs.push(err, c);
				}); // return p.then
			}, Promise.resolve())
	    	.then(() => {
	       		done();
	       		return console.log(`inserted ${ Object.keys(data).length } rows with ${ errs.length } errs: ${ errs }`);
			}).catch((err) => {
	        	done();
	        	return console.error(`error in loading: ${ err }`);
			}); // data.reduce
		} // if
		else {
			console.log(data.length + ' ' + menu + ' retrieved from the API');
			data.reduce((p, c) => {
				return p.then(() => {
					return dbQuery(sqlHandler, [c, menu], client); 
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
		} // else
	});
}

//Serving temp & location types are problematic, not same structure as others, need to do specific workaround
const apiMenuQuery = (menu) => {
	return new Promise((resolve) => {
		reqOpts.url = ENDPOINT + 'menu/' + menu + '/?key=' + key;
		request(reqOpts).then((body) => {
			data = JSON.parse(body).data;
			return resolve(load(data, menu));
		}) // request.then
		.catch((err) => {
			return console.error(`request for ${ reqOpts.url } failed: ${ err }`); // eslint-disable-line
		}); // request.catch
	}); // new Promise
}; //apiMenuQuery

// ETL for the menu variables
console.log('---- MENU TABLES ETL PROCESS ----');

return function () {
	Object.keys(menuNames).reduce((p, c) => {
		return p.then(() => {
			console.log('Requesting ' + menuNames[c]);
			return apiMenuQuery(menuNames[c]);
		}); // p.then
	}, Promise.resolve())
	.then(() => {
		return Promise.resolve();
	}); // keys.reduce
}; // return