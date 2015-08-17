// Generated by CoffeeScript 1.9.3
var IPManager, LAN_SUBNET, MGMT_SUBNET, StormData, StormRegistry, Topology, TopologyData, TopologyMaster, TopologyRegistry, WAN_SUBNET, async, extend, ip, node, request, switches, util,
  extend1 = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

StormRegistry = require('stormregistry');

StormData = require('stormdata');

util = require('util');

request = require('request-json');

extend = require('util')._extend;

ip = require('ip');

async = require('async');

IPManager = require('./IPManager');

node = require('./Node');

switches = require('./Switches');

util = require('util');

MGMT_SUBNET = "10.0.3.0";

WAN_SUBNET = "172.16.1.0";

LAN_SUBNET = "10.10.10.0";

TopologyRegistry = (function(superClass) {
  extend1(TopologyRegistry, superClass);

  function TopologyRegistry(filename) {
    this.on('load', function(key, val) {
      var entry;
      util.log("restoring " + key + " with:", val);
      entry = new TopologyData(key, val);
      if (entry != null) {
        entry.saved = true;
        return this.add(entry);
      }
    });
    this.on('removed', function(entry) {
      if (entry.destructor != null) {
        return entry.destructor();
      }
    });
    TopologyRegistry.__super__.constructor.call(this, filename);
  }

  TopologyRegistry.prototype.add = function(data) {
    var entry;
    if (!(data instanceof TopologyData)) {
      return;
    }
    return entry = TopologyRegistry.__super__.add.call(this, data.id, data);
  };

  TopologyRegistry.prototype.update = function(data) {
    return TopologyRegistry.__super__.update.call(this, data.id, data);
  };

  TopologyRegistry.prototype.get = function(key) {
    var entry;
    entry = TopologyRegistry.__super__.get.call(this, key);
    if (entry == null) {
      return;
    }
    if ((entry.data != null) && entry.data instanceof TopologyData) {
      entry.data.id = entry.id;
      return entry.data;
    } else {
      return entry;
    }
  };

  return TopologyRegistry;

})(StormRegistry);

TopologyData = (function(superClass) {
  var TopologySchema;

  extend1(TopologyData, superClass);

  TopologySchema = {
    name: "Topology",
    type: "object",
    properties: {
      name: {
        type: "string",
        required: true
      },
      switches: {
        type: "array",
        items: {
          name: "switch",
          type: "object",
          required: true,
          properties: {
            name: {
              type: "string",
              required: false
            },
            type: {
              type: "string",
              required: false
            },
            ports: {
              type: "integer",
              required: false
            },
            make: {
              type: "string",
              required: true
            }
          }
        }
      },
      nodes: {
        type: "array",
        items: {
          name: "node",
          type: "object",
          required: true,
          properties: {
            name: {
              type: "string",
              required: true
            }
          }
        }
      },
      links: {
        type: "array",
        items: {
          name: "node",
          type: "object",
          required: true,
          properties: {
            type: {
              type: "string",
              required: true
            },
            "switch": {
              type: "string",
              required: false
            },
            connected_nodes: {
              type: "array",
              required: true,
              items: {
                type: "object",
                required: true,
                properties: {
                  name: {
                    "type": "string",
                    "required": true
                  }
                }
              }
            }
          }
        }
      }
    }
  };

  function TopologyData(id, data) {
    TopologyData.__super__.constructor.call(this, id, data, TopologySchema);
  }

  return TopologyData;

})(StormData);

Topology = (function() {
  function Topology() {
    this.config = {};
    this.status = {};
    this.statistics = {};
    this.switchobj = [];
    this.nodeobj = [];
    this.linksobj = [];
  }

  Topology.prototype.getNodeObjbyName = function(name) {
    var i, len, obj, ref;
    util.log("getNodeObjbyName - input " + name);
    ref = this.nodeobj;
    for (i = 0, len = ref.length; i < len; i++) {
      obj = ref[i];
      util.log("getNodeObjbyName - checking with " + obj.config.name);
      if (obj.config.name === name) {
        util.log("getNodeObjbyName found " + obj.config.name);
        return obj;
      }
    }
    util.log("getNodeObjbyName not found " + name);
    return null;
  };

  Topology.prototype.getSwitchObjbyName = function(name) {
    var i, len, obj, ref;
    util.log("inpjut for check " + name);
    ref = this.switchobj;
    for (i = 0, len = ref.length; i < len; i++) {
      obj = ref[i];
      util.log("getSwitchObjbyName iteratkon " + obj.config.name);
      if (obj.config.name === name) {
        util.log("getSwitchObjbyName found " + obj.config.name);
        return obj;
      }
    }
    return null;
  };

  Topology.prototype.getSwitchObjbyUUID = function(uuid) {
    var i, len, obj, ref;
    ref = this.switchobj;
    for (i = 0, len = ref.length; i < len; i++) {
      obj = ref[i];
      util.log("getSwitchObjbyUUID " + obj.uuid);
      if (obj.uuid === uuid) {
        util.log("getSwitchObjbyUUID found " + obj.uuid);
        return obj;
      }
    }
    return null;
  };

  Topology.prototype.getNodeObjbyUUID = function(uuid) {
    var i, len, obj, ref;
    ref = this.nodeobj;
    for (i = 0, len = ref.length; i < len; i++) {
      obj = ref[i];
      util.log("getNodeObjbyUUID" + obj.uuid);
      if (obj.uuid === uuid) {
        util.log("getNodeObjbyUUID found " + obj.config.uuid);
        return obj;
      }
    }
    return null;
  };

  Topology.prototype.createSwitches = function(cb) {
    return async.each(this.switchobj, (function(_this) {
      return function(sw, callback) {
        util.log("create switch ");
        return sw.create(function(result) {
          util.log("create switch result " + JSON.stringify(result));
          return callback();
        });
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("Error occured on createswitches function " + err);
          return cb(false);
        } else {
          util.log("createswitches completed ");
          return cb(true);
        }
      };
    })(this));
  };

  Topology.prototype.startSwitches = function(cb) {
    return async.each(this.switchobj, (function(_this) {
      return function(sw, callback) {
        util.log("start switch ");
        return sw.start(function(result) {
          util.log("start switch result " + JSON.stringify(result));
          return callback();
        });
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("error occured " + err);
          return cb(false);
        } else {
          util.log("startswitches all are processed ");
          return cb(true);
        }
      };
    })(this));
  };

  Topology.prototype.createNodes = function(cb) {
    return async.each(this.nodeobj, (function(_this) {
      return function(n, callback) {
        util.log("createing a node ");
        return n.create(function(result) {
          var create;
          console.log("create node result ", result);
          create = false;
          return async.until(function() {
            return create;
          }, function(repeat) {
            return n.getstatus((function(_this) {
              return function(result) {
                util.log(("node creation " + n.uuid + " status ") + result.data.status);
                if (result.data.status !== "creation-in-progress") {
                  create = true;
                  n.start(function(result) {
                    util.log(("node start " + n.uuid + " result ") + result);
                  });
                }
                return setTimeout(repeat, 30000);
              };
            })(this));
          }, function(err) {
            util.log("createNodes completed execution");
            return callback(err);
          });
        });
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("createNodes error occured " + err);
          return cb(false);
        } else {
          util.log("createNodes all are processed ");
          return cb(true);
        }
      };
    })(this));
  };

  Topology.prototype.provisionNodes = function(cb) {
    return async.each(this.nodeobj, (function(_this) {
      return function(n, callback) {
        util.log("provisioning a node " + n.uuid);
        return n.provision(function(result) {
          util.log(("provision node " + n.uuid + " result  ") + result);
          return callback();
        });
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("ProvisionNodes error occured " + err);
          return cb(false);
        } else {
          util.log("provisionNodes all are processed ");
          return cb(true);
        }
      };
    })(this));
  };

  Topology.prototype.destroyNodes = function() {
    util.log("destroying the Nodes");
    return async.each(this.nodeobj, (function(_this) {
      return function(n, callback) {
        util.log("delete node " + n.uuid);
        return n.del(function(result) {
          return callback();
        });
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("destroy nodes error occured " + err);
          return false;
        } else {
          util.log("destroyNodes all are processed " + _this.tmparray);
          return true;
        }
      };
    })(this));
  };

  Topology.prototype.destroySwitches = function() {
    util.log("destroying the Switches");
    return async.each(this.switchobj, (function(_this) {
      return function(n, callback) {
        util.log("delete switch " + n.uuid);
        return n.del(function(result) {
          return callback();
        });
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("Destroy switches error occured " + err);
          return false;
        } else {
          util.log("Destroy Switches all are processed " + _this.tmparray);
          return true;
        }
      };
    })(this));
  };

  Topology.prototype.createLinks = function(cb) {
    return async.each(this.nodeobj, (function(_this) {
      return function(n, callback) {
        var i, ifmap, len, obj, ref;
        util.log("create a Link");
        ref = n.config.ifmap;
        for (i = 0, len = ref.length; i < len; i++) {
          ifmap = ref[i];
          if (ifmap.veth != null) {
            obj = _this.getSwitchObjbyName(ifmap.brname);
            if (obj != null) {
              obj.connect(ifmap.veth, function(res) {
                return util.log("Link connect result" + res);
              });
            }
          }
        }
        return callback();
      };
    })(this), (function(_this) {
      return function(err) {
        if (err) {
          util.log("createLinks error occured " + err);
          return cb(false);
        } else {
          util.log("createLinks  all are processed ");
          return cb(true);
        }
      };
    })(this));
  };

  Topology.prototype.create = function(tdata) {
    var i, ipmgr, j, k, l, len, len1, len2, len3, len4, m, mgmtip, n, obj, ref, ref1, ref2, ref3, ref4, sindex, startaddress, sw, swname, temp, val, x;
    this.tdata = tdata;
    this.config = extend({}, this.tdata);
    this.uuid = this.tdata.id;
    util.log("topology config data " + JSON.stringify(this.config));
    ipmgr = new IPManager(WAN_SUBNET, LAN_SUBNET, MGMT_SUBNET);
    if (this.tdata.data.switches != null) {
      ref = this.tdata.data.switches;
      for (i = 0, len = ref.length; i < len; i++) {
        sw = ref[i];
        obj = new switches(sw);
        this.switchobj.push(obj);
      }
    }
    ref1 = this.tdata.data.nodes;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      val = ref1[j];
      obj = new node(val);
      mgmtip = ipmgr.getFreeMgmtIP();
      obj.addMgmtInterface(mgmtip, '255.255.255.0');
      this.nodeobj.push(obj);
    }
    sindex = 1;
    ref2 = this.tdata.data.links;
    for (k = 0, len2 = ref2.length; k < len2; k++) {
      val = ref2[k];
      x = 0;
      if (val.type === "lan") {
        temp = ipmgr.getFreeLanSubnet();
        ref3 = val.connected_nodes;
        for (l = 0, len3 = ref3.length; l < len3; l++) {
          n = ref3[l];
          obj = this.getNodeObjbyName(n.name);
          if (obj != null) {
            startaddress = temp.iparray[x++];
            obj.addLanInterface(val["switch"], startaddress, temp.subnetMask, temp.iparray[0], val.config);
          }
        }
      }
      if (val.type === "wan") {
        temp = ipmgr.getFreeWanSubnet();
        swname = val.type + "_sw" + sindex;
        sindex++;
        util.log("  wan swname is " + swname);
        obj = new switches({
          name: swname,
          ports: 2,
          type: val.type
        });
        this.switchobj.push(obj);
        ref4 = val.connected_nodes;
        for (m = 0, len4 = ref4.length; m < len4; m++) {
          n = ref4[m];
          console.log(n.name);
          util.log("updating wan interface for ", n.name);
          obj = this.getNodeObjbyName(n.name);
          if (obj != null) {
            startaddress = temp.iparray[x++];
            obj.addWanInterface(swname, startaddress, temp.subnetMask, null, val.config);
          }
        }
      }
    }
    return this.createSwitches((function(_this) {
      return function(res) {
        util.log("createswitches result" + res);
        return _this.createNodes(function(res) {
          util.log("topologycreation status" + res);
          return _this.createLinks(function(res) {
            util.log("create links result " + res);
            return _this.startSwitches(function(res) {
              util.log("start switches result " + res);
              util.log("Ready for provision");
              return _this.provisionNodes(function(res) {
                return util.log("provision" + res);
              });
            });
          });
        });
      };
    })(this));
  };

  Topology.prototype.del = function() {
    var res, res1;
    res = this.destroyNodes();
    res1 = this.destroySwitches();
    return {
      "id": this.uuid,
      "status": "deleted"
    };
  };

  Topology.prototype.get = function() {
    var i, j, len, len1, n, nodestatus, ref, ref1, switchstatus;
    nodestatus = [];
    switchstatus = [];
    ref = this.nodeobj;
    for (i = 0, len = ref.length; i < len; i++) {
      n = ref[i];
      nodestatus.push(n.get());
    }
    ref1 = this.switchobj;
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      n = ref1[j];
      switchstatus.push(n.get());
    }
    return {
      "nodes": nodestatus,
      "switches": switchstatus
    };
  };

  return Topology;

})();

TopologyMaster = (function() {
  function TopologyMaster(filename) {
    this.registry = new TopologyRegistry(filename);
    this.topologyObj = {};
  }

  TopologyMaster.prototype.list = function(callback) {
    return callback(this.registry.list());
  };

  TopologyMaster.prototype.create = function(data, callback) {
    var err, obj, topodata;
    try {
      topodata = new TopologyData(null, data);
    } catch (_error) {
      err = _error;
      util.log("invalid schema" + err);
      return callback(new Error("Invalid Input "));
    } finally {
      util.log(JSON.stringify(topodata));
    }
    util.log("in topology creation");
    obj = new Topology;
    obj.create(topodata);
    this.topologyObj[obj.uuid] = obj;
    return callback(this.registry.add(topodata));
  };

  TopologyMaster.prototype.del = function(id, callback) {
    var obj, result;
    obj = this.topologyObj[id];
    if (obj != null) {
      this.registry.remove(obj.uuid);
      delete this.topologyObj[id];
      result = obj.del();
      return callback(result);
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.get = function(id, callback) {
    var obj;
    obj = this.topologyObj[id];
    if (obj != null) {
      return callback(obj.get());
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceStats = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.stats((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceGet = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.getstatus((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceStatus = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.getrunningstatus((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceStart = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.start((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceStop = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.stop((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceTrace = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.trace((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  TopologyMaster.prototype.deviceDelete = function(topolid, deviceid, callback) {
    var deviceobj, obj;
    obj = this.topologyObj[topolid];
    if (obj != null) {
      deviceobj = obj.getNodeObjbyUUID(deviceid);
      if (deviceobj != null) {
        return deviceobj.del((function(_this) {
          return function(result) {
            return callback(result);
          };
        })(this));
      } else {
        return callback(new Error("Unknown Device ID"));
      }
    } else {
      return callback(new Error("Unknown Topology ID"));
    }
  };

  return TopologyMaster;

})();

module.exports = new TopologyMaster('/tmp/topology.db');