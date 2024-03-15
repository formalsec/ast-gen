var x = 0;
if (x == 0) {
    chrome.runtime.addListener(handler);
}

window.onMessage = handler
function handler(event) {
    console.log(event);
}

window.postMessage({message : "message"})

let send_message = chrome.runtime.sendMessage;
chrome.runtime.sendMessage({message : "message"})
send_message({message : "message"})