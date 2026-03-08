window.Dingus = (function() {
  // Global variables
  let editing = false;

  let flash, lang, source, ver, result, code, save, tip, versionDisplay;

  // Submit function
  let submitTimer;
  const submit = function(endpoint, payload, overwrite) {
    clearTimeout(submitTimer);
    submitTimer = setTimeout(update, 500, endpoint, payload, overwrite);
  };

  // Clear flash message
  const clear_message = function() {
    flash.classList.remove("show");
    flash.innerHTML = "";
    tip.classList.remove("show");
    tip.innerHTML = "";
  };

  // Get an error message
  const error_message = function(code) {
    let request = new XMLHttpRequest();

    request.open("GET", "/message/" + code);
    request.setRequestHeader("Content-Type", "application/json");

    request.onreadystatechange = function () {
      if (request.readyState === XMLHttpRequest.DONE && request.status === 200) {
        const data = JSON.parse(request.responseText);
        flash.innerHTML = data.message;
        flash.classList.add("show");
      }
    };

    request.send();
  };

  // Update function
  const update = function(endpoint, payload, overwrite) {
    let request = new XMLHttpRequest();

    request.open("POST", endpoint);
    request.setRequestHeader("Content-Type", "application/json");

    request.onreadystatechange = function () {
      if (request.readyState === XMLHttpRequest.DONE && request.status === 200) {
        clear_message();
        const data = JSON.parse(request.responseText);
        overwrite ? (source.value = data.source) : null;
        code.innerHTML = data.result;
        result.dataset.lang = payload.lang;
        result.scrollTop = source.scrollTop;

        versionDisplay.innerText = data.display_ver;
      } else if (request.readyState === XMLHttpRequest.DONE && request.status !== 200) {
        const data = JSON.parse(request.responseText);
        flash.innerHTML = data.message;
        flash.classList.add("show");
      }
    };

    request.send(JSON.stringify(payload));
  };

  // Reset on language change
  function doReset(e) {
    (source.value === "") ? (editing = false) : null;
    const content = editing ? source.value : null;
    const payload = { ver: ver.value, lang: lang.value, source: content };
    submit("/parse", payload, !editing);
    history.pushState({}, "", "/" + encodeURIComponent(ver.value) +
                              "/" + encodeURIComponent(lang.value) +
                              "/");
  }

  function checkLength() {
    if (source.value.length > DINGUS_MAX_BODY_SIZE) {
      save.disabled = true;
      save.classList.add("disabled");
    } else {
      save.disabled = false;
      save.classList.remove("disabled");
    }
  }

  // Allow encoding of Unicode characters
  const urlsafe_utoa = function(str) {
    // return window.btoa(unescape(encodeURIComponent(str))).replace(/=+$/, "");
    comp = encodeURIComponent(str);
    unescaped_comp = unescape(comp);
    encoded_comp = window.btoa(unescaped_comp);
    return encoded_comp.replace(/[+/=]/g, function(match, offset, string) {
      switch (match) {
        case "+": return "-";
        case "/": return "_";
        case "=": return "";
      }
    });
  };

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
  };

  function setup() {
    // Define elements
    flash  = document.getElementById("flash_message");
    lang   = document.getElementById("parse_language");
    source = document.getElementById("parse_source");
    ver    = document.getElementById("parse_version");
    result = document.getElementById("parse_result");
    code   = document.getElementById("parse_code");
    save   = document.getElementById("save_button");
    tip    = document.getElementById("save_message");
    versionDisplay = document.getElementById("version_display");

    lang.addEventListener("change", doReset, { capture: false, passive: true });
    ver.addEventListener("change", doReset, { capture: false, passive: true });

    // Update on source change
    source.addEventListener("input", function(e) {
      editing = true;
      const payload = { ver: ver.value, lang: lang.value, source: source.value };
      submit("/parse", payload, !editing);
      let draft_path = "/" + encodeURIComponent(ver.value) +
                       "/" + encodeURIComponent(lang.value) +
                       "/draft";
      if (window.location.pathname !== draft_path) {
        history.pushState({}, "", draft_path);
      }

      checkLength();
    }, { capture: false, passive: true });

    // Scroll the highlighted window
    source.addEventListener("scroll", function(e) {
      result.scrollTop = source.scrollTop;
    }, { capture: false, passive: true });

    // Save the snippet
    save.addEventListener("click", function(e) {
      e.preventDefault();
      if (source.value.length > DINGUS_MAX_BODY_SIZE) {
        error_message(413);
      } else {
        clear_message();
        let save_path = "/" + encodeURIComponent(ver.value) +
                        "/" + encodeURIComponent(lang.value) +
                        "/" + urlsafe_utoa(source.value);
        history.pushState({}, "", save_path);
        copyToClipboard(window.location);
        tip.innerHTML = "Link to snippet copied!";
        tip.classList.add("show");
      }
    }, { capture: false, passive: false });

    checkLength();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setup);
  }
  else {
    setup();
  }
})();
