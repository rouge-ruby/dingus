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
      flash.style.display = "none";
      const data = JSON.parse(request.responseText);
      source.value = data.source;
      result.innerHTML = "<code>" + data.result + "</code>";
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
});

// Update on source change
source.addEventListener("input", function(e) {
  submit("/parse", { lang: lang.value, source: source.value });
});
