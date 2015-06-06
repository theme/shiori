chrome.browserAction.onClicked.addListener(function(activeTab)
{
    var newURL = "chrome://bookmarks/";
    chrome.tabs.create({ url: newURL });
});
