#!/usr/bin/env node

"use strict";

process.chdir(__dirname);

const fs = require("fs");
const pkg = require("../package.json");

const smallPkg = {
	private: true,
	dependencies: {
		sqlite3: pkg.optionalDependencies.sqlite3,
	},
};

fs.writeFile("package.json", JSON.stringify(smallPkg), function(err) {
	if (err) {
		console.error(err); // eslint-disable-line
		process.exit(1);
	}
});
