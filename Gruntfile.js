module.exports = function(grunt) {
    grunt.initConfig({
        copy: {
            js: {
                files: [{ expand:true, cwd:'src/js/', src:['**'],
                    dest:'pub/js/', filter:'isFile' }]
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
        watch: {
            js: {
                files: ['src/**/*.js'],
                tasks: ['copy:js'],
                options: { spawn: false, interrupt: true, debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            jade: {
                files: ['src/**/*.jade'],
                tasks: ['jade'],
                options: { spawn: false, interrupt: true, debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            less: {
                files: ['src/**/*.less'],
                tasks: ['less'],
                options: { spawn: false, interrupt: true, debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            coffee: {
                files: ['src/**/*.coffee'],
                tasks: ['coffee'],
                options: { spawn: false, interrupt: true, debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            svg: {
                files: ['src/**/*.svg'],
                tasks: ['exec:svg2png'],
                options: { spawn: false, interrupt: true, debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            configFiles: {
                files: [ 'Gruntfile.js', 'config/*.js' ],
                options: { reload: true }
            }
        },
        exec :{
            echo_something: 'echo "this is something"',
            svg2png: {
                cmd: function(){
                    var os = require('os'),
                        path = require('path');
                    var inkscape = '';
                    var cmds = [];
                    var pngsize = [ 16, 19, 48, 128 ]
                    if( /^win/.test(os.platform()) ){
                        inkscape = '"C:\\Program Files\\Inkscape\\inkscape.exe"';
                    } else { inkscape = 'inkscape'; }
                    pngsize.forEach( function( s ) {
                        var dest = path.resolve('pub/img/icon'+s.toString()+'.png');
                        var src = path.resolve('src/svg/leaf-shadow.svg');
                        cmds.push( inkscape +
                            ' --export-png ' + ' "'+ dest + '" ' +
                            ' -w ' + s.toString() +
                            ' "' + src + '" ' );
                    } )
                    console.log(cmds.join('  &&  '));
                    return cmds.join('  &&  ');
                }
            }
        }
    });
    // Load the plugin that provides the "less" task.
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-jade');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-exec');


    // Default task(s).
    grunt.registerTask('make', ['copy','jade','less','coffee','exec:svg2png']);
};
