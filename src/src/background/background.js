function getArrangerUrl() {
  var url = chrome.extension.getURL('src/override/bookmarks.html');
  return url;
}

function isArrangerUrl(url) {
  return url.indexOf(getArrangerUrl()) == 0;
}

function goToArranger() {
  chrome.tabs.query({}, function(tabs) {
    // focus, if bookmarks tab exist.
    for (var i = 0, tab; tab = tabs[i]; i++) {
      if (tab.url && isArrangerUrl(tab.url)) {
        chrome.tabs.update(tab.id, {highlighted: true});
        return;
      }
    }
    // create, if no bookmarks tab.
    chrome.tabs.create({url: getArrangerUrl()});
  });
}

chrome.browserAction.onClicked.addListener(goToArranger);
