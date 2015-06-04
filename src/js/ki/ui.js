ki.define('ki.ui', function() {
	var dbg = function(){
		console.log( 'ui module exist.');
	};

/**
* define an UI element constructor (HTML element)
*/
	var define = function( tagName ){
		var cnst = function(){
			var el = document.createElement(tagName);
			if (el){ return el;}
			else return document.createElement('div');
		};
		return cnst;
	};

	return {
		dbg: dbg,
		define: define
	};
});
