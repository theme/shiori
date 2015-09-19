ki.define('ki.ui', function() {
  var Tree = ki.ui.defineConstructor('div');
  Tree.prototype  = Object.create(HTMLUnknownElement.prototype);

  return {
    Tree: Tree
  };
});
