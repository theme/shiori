ki.define('ki.ui', function() {
/**
* define an UI element constructor (HTML element)
*/
	var defineConstructor = function( tagName ){
		var cnst = function(){
			var el = document.createElement(tagName);
			if (el){ return el;}
			else return document.createElement('div');
		};
		return cnst;
	};

	return {
		defineConstructor: defineConstructor
	};
});
