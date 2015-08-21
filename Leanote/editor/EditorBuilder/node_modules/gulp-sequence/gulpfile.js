'use strict'

var gulp = require('gulp')
var gulpSequence = require('./index')
var test = require('./test/index')

test()

gulp.task('default', gulpSequence('test'))
