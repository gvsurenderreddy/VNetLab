// Generated by CoffeeScript 1.9.3
var Log, createLogger, fs, getLogger;

Log = require('log');

fs = require('fs');

this.log = null;

createLogger = function(level, filename) {
  if (level == null) {
    level = 'debug';
  }
  if (filename == null) {
    filename = '/var/log/vnetlabs.log';
  }
  this.log = new Log(level, fs.createWriteStream(filename));
  return this.log;
};

getLogger = function() {
  return this.log;
};

module.exports.createLogger = createLogger;

module.exports.getLogger = getLogger;
