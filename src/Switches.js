// Generated by CoffeeScript 1.9.3
var extend, request, switchctrl, switches, util;

util = require('util');

request = require('request-json');

extend = require('util')._extend;

switchctrl = require('./builder/switchCtrl');

switches = (function() {
  function switches(sw) {
    var base;
    this.config = extend({}, sw);
    if ((base = this.config).make == null) {
      base.make = "bridge";
    }
    this.status = {};
    this.statistics = {};
    util.log(" switch config " + JSON.stringify(this.config));
  }

  switches.prototype.create = function(callback) {
    return switchctrl.create(this.config, (function(_this) {
      return function(res) {
        console.log("post switch response" + res);
        _this.uuid = res.id;
        return callback(res);
      };
    })(this));
  };

  switches.prototype.del = function(callback) {
    return switchctrl.del(this.uuid, (function(_this) {
      return function(res) {
        console.log(res);
        return callback(res);
      };
    })(this));
  };

  switches.prototype.get = function() {
    return {
      "uuid": this.uuid,
      "config": this.config,
      "status": this.status,
      "statistics": this.statistics
    };
  };

  switches.prototype.stop = function() {
    return switchctrl.stop(this.uuid, (function(_this) {
      return function(res) {
        console.log(res);
        return callback(res);
      };
    })(this));
  };

  switches.prototype.start = function() {
    return switchctrl.start(this.uuid, (function(_this) {
      return function(res) {
        console.log(res);
        return callback(res);
      };
    })(this));
  };

  switches.prototype.connect = function(ifname, callback) {
    var val;
    val = {
      "ifname": ifname
    };
    return switchctrl.addInterface(this.uuid, val, (function(_this) {
      return function(res) {
        console.log(res);
        return callback(res);
      };
    })(this));
  };

  switches.prototype.switchStatus = function() {};

  switches.prototype.statistics = function() {};

  return switches;

})();

module.exports = switches;