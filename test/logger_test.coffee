Logger = require('../src/utils/logger')
mylog = new Logger(level = 'debug',filename = '/tmp/testlog.log')
log = mylog.log

log.debug('preparing email');
log.info('sending email');
log.error('failed to send email');


