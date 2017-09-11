// index regrouping the three main parts of etl process
// more to come ...

const request = require('request-promise');

const menus = require('./etl_menus.js');
const beers = require('./etl_beers.js');
//const breweries = require('./etl_breweries.js');

/*const etlSteps = [
	menus,
	beers,
	breweries
];*/

const doStep = function (step) {
  return new Promise((resolve, reject) => {
    return step();
  }); // return new Promise
}; // doStep

/*console.log('---- ETL PROCESS BREWERY DB ----');
return etlSteps.reduce((p,c) => {
	return p.then(() => {
		return doStep(c);
    }).catch((err) => {
    	return console.error(err);
    }); // return p.then
}, Promise.resolve());*/

doStep(beers);