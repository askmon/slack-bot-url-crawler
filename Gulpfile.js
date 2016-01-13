require('coffee-script/register')

var gulp = require('gulp');
var mocha = require('gulp-mocha');


gulp.task('test', function () {
  return gulp.src('./tests/{,**/}*tests.coffee')
    .pipe(mocha({
      reporter: 'spec',
      timeout: 10000
    }))
    .once('error', function (err) {
      if (err.stack) {
        console.log("--- \n" + err.stack + "\n---");
      } else if(err.message) {
        console.log("--- \n" + err.message + "\n---");
      }
      process.exit(1);
    })
    .once('end', function () {
        process.exit();
    });
});
