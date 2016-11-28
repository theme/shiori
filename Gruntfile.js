module.exports = function(grunt) {
    grunt.initConfig({
        coffee: {
            compile: {
                options: {
                    pretty: true
                },
                files: [{
                    expand: true,
                    cwd: 'src/',
                    src: ['**/*.coffee' ],
                    dest: 'pub/',
                    rename: function(dest,src){
                        return dest + src.replace(/.coffee$/, '.js');
                    }
                }],
            }
        },
        jade: {
            compile: {
                options: { pretty: true },
                files: [{
                    expand: true,
                    cwd: 'src/',
                    src: ['**/*.jade' ],
                    dest: 'pub/',
                    rename: function(dest,src){
                        return dest + src.replace(/.jade$/, '.html');
                    }
                }],
            }
        },
        less: {
            compile: {
                options: {
                    paths: ["css"],
                    cleancss: true,
                    modifyVars: { /* /imgPath: '"http://site/images"' */ }
                },
                files: [{
                    expand: true,
                    cwd: 'src/',
                    src: ['**/*.less' ],
                    dest: 'pub/',
                    rename: function(dest,src){
                        return dest + src.replace(/.less$/, '.css');
                    }
                }],
            }
        },
        watch: {
            sync: {
                files: [
                    'src/**/*.json',
                    'src/**/*.html',
                    'src/**/*.js',
                    'src/**/*.css',
                    'src/**/*.md'
                ],
                tasks: ['sync'],
                options: { spawn: false, interrupt: true, debounceDelay: 250, event: ['changed'] //changed, added, deleted, all
                }
            },
            coffee: {
                files: ['src/**/*.coffee'],
                tasks: ['coffee'],
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
                        '!**/*.jade', /* exclude jade files */
                        '!**/*.less',
                        '!**/*.coffee',
                        '!**/*.blend',
                        '!**/*.blend1',
                        '!**/*.svg',
                        '!**/*.swp', // ignore vim swap file
                        '!**/*\~'
                    ],
                    dest: 'pub'
                }],
                pretend: false, // !!! Don't do any disk operations - just write log
                verbose: true, // Display log messages when copying files
                //ignoreInDest: "**/*.png", // Never remove js files from destination
                updateAndDelete: false// Remove all files from dest that are not found in src
            }
        }
    });
    // Load the plugin that provides the "less" task.
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-jade');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-exec');
    grunt.loadNpmTasks('grunt-sync');


    // Default task(s).
    grunt.registerTask('make', ['sync','jade','less','coffee','exec:svg2png']);
};
