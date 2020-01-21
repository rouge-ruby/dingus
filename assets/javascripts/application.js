// Define elements
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
      const data = JSON.parse(request.responseText);
      source.value = data.source;
      result.innerHTML = "<code>" + data.result + "</code>";
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
