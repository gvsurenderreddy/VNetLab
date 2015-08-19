Log = require('log')
fs = require('fs')


@log = null

createLogger = (level = 'debug', filename = '/var/log/vnetlabs.log')->
	@log = new Log(level, fs.createWriteStream(filename))  
	@log  	  	

getLogger = ()->
	@log

#########
module.exports.createLogger = createLogger
module.exports.getLogger = getLogger
