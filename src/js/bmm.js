/**
* @fileoverview Bookmark module
* BookmarkTree
* BookmarkList
* BookmarkModel ( not now , this is simple chrome extension)
*/

ki.define('bmm.bookmarks', function() {
	var bmCache = {};
	var getChildren = function(id, fun) {
		var c = bmCache[id];
		if (c) {
			fun(c);
		} else {
			chrome.bookmarks.getChildren(id, function(array) {
				bmCache[id] = array;
				fun(array);
			});
		}
	};

	var BookmarkTree = function(){
	  this.el_ = new ki.ui.Tree();
	};

	BookmarkTree.prototype = Object.create(ki.ui.Tree);
	BookmarkTree.prototype.setViewModel = function(vm){
		this.vm_ = vm;
		vm.addEventListener('update', this.reload );
	};
	BookmarkTree.prototype.reload = function(vm){
		console.log('DBG: BookmarkTree.prototype.reload()');
	};

	var createTreeView = function(){
		return new BookmarkTree();
	};

	var createTreeViewModel = function(){
		return {};
	};

	return {
		getChildren : getChildren,
		createTreeView : createTreeView
	};
});
