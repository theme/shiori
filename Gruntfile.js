module.exports = function(grunt) {
    grunt.initConfig({
        jade: {
            compile: {
                options: { pretty: true, data: { debug: false } },
                files: { "pub/arranger.html": "src/arranger.jade" }
            }
        },
        less: {
            compile: {
                options: {
                    paths: ["css"],
                    cleancss: true,
                    modifyVars: { /* /imgPath: '"http://site/images"' */ }
                },
                files: { "pub/css/arranger.css": "css/arranger.less" }
            }
        },
        watch: {
            sync: {
                files: ['src/js/**/*.js', 'src/manifest.json'],
                tasks: ['sync'],
                options: { spawn: false, interrupt: true, debounceDelay: 250,
                    event: ['changed'] //changed, added, deleted, all
                }
            },
            jade: {
                files: ['src/*.jade'],
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
                        var dest = path.resolve('pub/icons/icon'+s.toString()+'.png');
                        var src = path.resolve('src/icons/leaf-shadow.svg');
                        cmds.push( inkscape +
                                  ' --export-png ' + ' "'+ dest + '" ' +
                                  ' -w ' + s.toString() +
                                  ' "' + src + '" ' );
                    } )
                    console.log(cmds.join('  &&  '));
                    return cmds.join('  &&  ');
                }
            }
        },
        sync: {
            main: {
                files: [{
                    cwd: 'src',
                    src: [
                        '**', /* Include everything */
                        '!**/*.jade', /* but exclude jade files */
                        '!**/*.less',
                        '!**/*.coffee',
                        '!**/*.svg',
                        '!**/*.png',
                        '!**/*\~'
                    ],
                    dest: 'pub'
                }],
                pretend: false, // !!! Don't do any disk operations - just write log
                verbose: true, // Display log messages when copying files 
                ignoreInDest: "**/*.js", // Never remove js files from destination 
                updateAndDelete: false// Remove all files from dest that are not found in src 
            }
        }
    });
    // Load the plugin that provides the "less" task.
    grunt.loadNpmTasks('grunt-contrib-jade');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-exec');
    grunt.loadNpmTasks('grunt-sync');


    // Default task(s).
    grunt.registerTask('make', ['sync','jade','less','exec:svg2png']);
};
