module.exports = function(grunt) {
    grunt.initConfig({
        jade: {
            compile: {
                options: {
                    pretty: true,
                    data: {
                        debug: false
                    }
                },
                files: {
                    "pub/arranger.html": "src/jade/arranger.jade"
                }
            }
        },
        less: {
            development: {
                options: {
                    paths: ["src/less"]
                },
                files: {
                }
            },
            production: {
                options: {
                    paths: ["src/less"],
                    cleancss: true,
                    modifyVars: {
                        //imgPath: '"http://mycdn.com/path/to/images"',
                        //bgColor: 'red'
                    }
                },
                files: {
                    "pub/css/arranger.css": "src/less/arranger.less"
                }
            }
        },
        coffee: {
            compileBare: {
                options: {
                    bare: true
                },
                files: {
                    'pub/js/arranger.js': 'src/coffee/arranger.coffee', // 1:1 compile
                }
            }
        },
        watch: {
            scripts: {
                files: ['src/**'],
                tasks: ['default'],
                options: {
                    spawn: false,
                    interrupt: true,
                    debounceDelay: 250,
                    event: ['changed'], //changed, added, deleted, all
                },
            },
            configFiles: {
                files: [ 'Gruntfile.js', 'config/*.js' ],
                options: {
                    reload: true
                }
            },
        },
    });
    // Load the plugin that provides the "less" task.
    grunt.loadNpmTasks('grunt-contrib-jade');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-watch');

    // Default task(s).
    grunt.registerTask('default', ['jade','less','coffee']);
};
