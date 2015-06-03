module.exports = function(grunt) {
    grunt.initConfig({
        copy: {
            main: {
                files: [{ expand:true, cwd:'src/js/', src:['**'], dest:'pub/js/', filter:'isFile' }]
            }
        },
        jade: {
            compile: {
                options: { pretty: true, data: { debug: false } },
                files: { "pub/arranger.html": "src/jade/arranger.jade" }
            }
        },
        less: {
            development: { options: { paths: ["src/less"] }, files: { } },
            production: {
                options: {
                    paths: ["src/less"],
                    cleancss: true,
                    modifyVars: {
                        //imgPath: '"http://mycdn.com/path/to/images"',
                        //bgColor: 'red'
                    }
                },
                files: { "pub/css/arranger.css": "src/less/arranger.less" }
            }
        },
        coffee: {
            compileBare: {
                options: { bare: false },
                files: { /*'pub/js/arranger.js': ['src/coffee/arranger.coffee'] */}
            },
        },
        svg2png: ( function(){
            var pngsize = [ 16, 19, 48, 128 ];
            var svgsize = 128.0;
            // construct task object for grunt task : svg2png
            var o = {};
            pngsize.forEach( function( s ) {
                o['p'+ s.toString(10)] = {
                    options: { scale: s/svgsize },
                    files: [ {
                        cwd: 'src/svg/',
                        src: 'leaf-shadow.svg',
                        dest: 'pub/img/icon' + s.toString() + '.png'
                    } ]
                };
            });
            return o;
        })(),
        watch: {
            srouceFiles: {
                files: ['src/**'],
                tasks: ['default'],
                options: {
                    spawn: false,
                    interrupt: true,
                    debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            configFiles: {
                files: [ 'Gruntfile.js', 'config/*.js' ],
                options: { reload: true }
            }
        }
    });
    // Load the plugin that provides the "less" task.
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-jade');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-svg2png');

    // Default task(s).
    grunt.registerTask('default', ['copy','jade','less','coffee','svg2png']);
};
