var gulp = require('gulp');
var clean = require('gulp-clean');
var uglify = require('gulp-uglify');
var rename = require('gulp-rename');
var minifyHtml = require("gulp-minify-html");
var concat = require('gulp-concat');
var replace = require('gulp-replace');
var inject = require('gulp-inject');
var gulpSequence = require('gulp-sequence');

// for rich text editor

var editorBase = '../EditorAssets';
gulp.task('concatJsRich', function() {
    var jss = [
        'jquery.js',
        'js-beautifier.js',
        'underscore-min.js',
        'shortcode.js',
        'jquery.mobile-events.min.js',
        'WPHybridCallbacker.js',
        'WPHybridLogger.js',
        'ZSSRichTextEditor.js',
        'wpload.js',
        'wpsave.js',
        'rangy-core.js',
        'rangy-classapplier.js',
        'rangy-highlighter.js',
        'rangy-selectionsaverestore.js',
        'rangy-serializer.js',
        'rangy-textrange.js',
    ];

    for(var i in jss) {
        jss[i] = editorBase + '/' + jss[i];
    }

    return gulp
        .src(jss)
        .pipe(uglify())
        .pipe(concat('all.js'))
        .pipe(gulp.dest(editorBase));
});

gulp.task('htmlRich', function() {
    var sources = gulp.src([editorBase + '/all.js'], {read: false});

    return gulp
        .src(editorBase + '/editor.html')
        .pipe(replace(/<script.*>.*<\/script>/g, '')) // 除去<script></script>
        .pipe(inject(sources, {relative: true}))
        .pipe(minifyHtml())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest(editorBase));
});


// for markdown


var markdownRaw = '../MarkdownAssetsRaw';
var markdownMin = '../MarkdownAssets';

// min main.js, 无用
gulp.task('jsmin', function() {
    return gulp
        .src(markdownRaw + '/main.js')
        .pipe(uglify())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest(markdownMin));
});

// 合并Js
gulp.task('concatJs', function() {
    return gulp
        .src([markdownRaw + '/res-min/jquery.min.js', markdownRaw + '/res-min/before.js', markdownRaw + '/res-min/require.min.js', markdownRaw + '/res-min/main.js', markdownRaw + '/res-min/editor.js'])
        .pipe(uglify())
        .pipe(concat('all.js'))
        .pipe(gulp.dest(markdownMin));
});

// 合并css
gulp.task('concatCss', function() {
    return gulp
        .src([markdownRaw + '/css/default.css', markdownRaw + '/css/md.css'])
        .pipe(concat('all.css'))
        .pipe(gulp.dest(markdownMin));
});

// 优化html, 替换css, js
gulp.task('html', function() {
	var sources = gulp.src([markdownMin + '/all.js', markdownMin + '/all.css'], {read: false});

    return gulp
        .src(markdownRaw + '/editor-mobile.html')
        .pipe(replace(/<textarea(\s|\S)+?<\/textarea>/g, ''))
        .pipe(replace(/<div style="display: none">(\s|\S)+?<\/div>/g, '')) // 除去未例
        .pipe(replace(/<link.+?\/>/g, '')) // 除去<link />
        .pipe(replace(/<script.*>.*<\/script>/g, '')) // 除去<script></script>
        .pipe(inject(sources, {relative: true}))
        .pipe(replace(/..\/MarkdownAssets\//g, '')) // 是因为inject后, 是相对路径
        .pipe(minifyHtml())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest(markdownMin));
});

gulp.task('concat', ['concatJs', 'concatCss']);

gulp.task('markdown', gulpSequence('concat', 'html')); // markdown
gulp.task('rich', gulpSequence('concatJsRich', 'htmlRich')); // rich editor

gulp.task('default', ['markdown', 'rich']);

