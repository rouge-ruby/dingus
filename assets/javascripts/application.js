// Define error messages
const error_message_length =
  `<strong>Too Long</strong>: This form accepts a maximum of 1500 characters of text.
  Please reduce the amount of text and try again.`

const error_message_server =
  `<strong>Server Error</strong>: A server error occurred while processing your input.`

// Define elements
const flash  = document.getElementById("flash_message");
const lang   = document.getElementById("parse_language");
const source = document.getElementById("parse_source");
const result = document.getElementById("parse_result");
const save   = document.getElementById("save_button");
const tip    = document.getElementById("save_message");

// Submit function
let submitTimer;
const submit = function(endpoint, payload) {
  clearTimeout(submitTimer);
  submitTimer = setTimeout(update, 500, endpoint, payload);
};

// Update function
const update = function(endpoint, payload) {
  let request = new XMLHttpRequest();

  request.open("POST", endpoint);
  request.setRequestHeader("Content-Type", "application/json");

  request.onreadystatechange = function () {
    if (request.readyState === XMLHttpRequest.DONE && request.status === 200) {
      const data = JSON.parse(request.responseText);
      source.value = data.source;
      result.innerHTML = "<code>" + data.result + "</code>";
      flash.style.display = "none";
    } else if (request.readyState === XMLHttpRequest.DONE && request.status === 413) {
      flash.innerHTML = error_message_length;
      flash.style.display = "block";
    } else if (request.readyState === XMLHttpRequest.DONE && request.status === 500) {
      flash.innerHTML = error_message_server;
      flash.style.display = "block";
    }
  };

  request.send(JSON.stringify(payload));
};

// Reset on language change
lang.addEventListener("change", function(e) {
  submit("/parse", { lang: lang.value });
  history.pushState({}, "", "/" + encodeURIComponent(lang.value) + "/");
});

// Update on source change
source.addEventListener("input", function(e) {
  submit("/parse", { lang: lang.value, source: source.value });
  let draft_path = "/" + encodeURIComponent(lang.value) + "/draft";
  if (window.location.pathname !== draft_path) {
    history.pushState({}, "", draft_path);
  }
});

// Allow encoding of Unicode characters
const utoa = function(str) {
  return window.btoa(unescape(encodeURIComponent(str))).replace(/=+$/, "");
}

// Copy to clipboard
const copyToClipboard = function(text) {
  if (window.clipboardData && window.clipboardData.setData) {
    // IE specific code path to prevent textarea being shown while dialog is visible.
    return clipboardData.setData("Text", text);
  } else if (document.queryCommandSupported && document.queryCommandSupported("copy")) {
    let textarea = document.createElement("textarea");
    textarea.textContent = text;
    textarea.style.position = "fixed";  // Prevent scrolling to bottom of page in MS Edge.
    document.body.appendChild(textarea);
    textarea.select();
    try {
      return document.execCommand("copy");  // Security exception may be thrown by some browsers.
    } catch (ex) {
      console.warn("Copy to clipboard failed.", ex);
      return false;
    } finally {
      document.body.removeChild(textarea);
    }
  }
}

// Save the snippet
save.addEventListener("click", function(e) {
  e.preventDefault();
  let save_path = "/" + encodeURIComponent(lang.value) + "/" + utoa(source.value);
  history.pushState({}, "", save_path);
  copyToClipboard(window.location);
  tip.innerHTML = "Link to snippet copied!";
  tip.style.display = "inline-block";
});
