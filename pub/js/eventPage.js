var id = chrome.i18n.getMessage("@@extension_id");

function getArrangerUrl() {
    var url = 'chrome-extension://__ID__/arranger.html';
    return url.replace( '__ID__', id);
}

function isArrangerUrl(url) {
    return url.indexOf( getArrangerUrl()) == 0;
}

function goToArranger(){
    console.log('Going to Arranger...');
    chrome.tabs.query( {}, function(tabs) {
        for ( var i = 0, tab; tab = tabs[i]; i++) {
            if ( tab.url && isArrangerUrl(tab.url)){
                console.log( 'Found Arranger tab: ' + tab.url + '. ' +
                            'Focusing ...');
                chrome.tabs.update( tab.id, {highlighted: true});
                return;
            }
        }
        console.log( 'Could not find Arranger tab. Create one... ');
        chrome.tabs.create({url:getArrangerUrl()});
    });
}

chrome.browserAction.onClicked.addListener(goToArranger);
