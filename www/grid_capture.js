(function () {
  function buildFilename() {
    const nEl = document.getElementById("n");
    const n = nEl && nEl.value ? nEl.value : "grid";
    const snailInput = document.querySelector('input[name="snail_method"]:checked');
    const snail = snailInput && snailInput.value === "yes";
    const violation = document.querySelector(".status-footer.error") !== null;
    const layout = snail ? "snail" : "classic";
    const status = violation ? "violation" : "ok";
    return "rcls-grid-n" + n + "-" + layout + "-" + status + ".png";
  }

  function substituteInputs(root) {
    const replacements = [];
    root.querySelectorAll("input").forEach(function (input) {
      const span = document.createElement("span");
      const computed = window.getComputedStyle(input);
      span.className = "grid-capture-value";
      span.textContent = input.value;
      span.style.display = "inline-block";
      span.style.width = computed.width;
      span.style.minHeight = computed.height;
      span.style.lineHeight = computed.height;
      span.style.textAlign = "center";
      span.style.fontSize = computed.fontSize;
      span.style.fontFamily = computed.fontFamily;
      span.style.fontWeight = computed.fontWeight;
      span.style.color = computed.color;
      span.style.backgroundColor = computed.backgroundColor;
      span.style.border = computed.border;
      span.style.borderRadius = computed.borderRadius;
      span.style.boxSizing = "border-box";
      span.style.padding = computed.padding;
      span.style.margin = computed.margin;
      input.style.display = "none";
      input.parentElement.insertBefore(span, input);
      replacements.push({ input: input, span: span });
    });
    return replacements;
  }

  function restoreInputs(replacements) {
    replacements.forEach(function (item) {
      item.input.style.display = "";
      item.span.remove();
    });
  }

  async function captureGrid() {
    const target = document.getElementById("grid_capture");
    if (!target) {
      return;
    }
    if (typeof html2canvas === "undefined") {
      window.alert("Grid capture library failed to load. Please refresh and try again.");
      return;
    }

    const replacements = substituteInputs(target);
    try {
      const canvas = await html2canvas(target, {
        backgroundColor: "#ffffff",
        scale: 2,
        logging: false,
        useCORS: true
      });
      await new Promise(function (resolve, reject) {
        canvas.toBlob(function (blob) {
          if (!blob) {
            reject(new Error("Could not create PNG blob."));
            return;
          }
          const url = URL.createObjectURL(blob);
          const link = document.createElement("a");
          link.download = buildFilename();
          link.href = url;
          document.body.appendChild(link);
          link.click();
          link.remove();
          URL.revokeObjectURL(url);
          resolve();
        }, "image/png");
      });
    } catch (err) {
      window.alert("Could not save grid image. Please try again.");
      console.error(err);
    } finally {
      restoreInputs(replacements);
    }
  }

  $(document).on("click", "#save_grid", function (e) {
    e.preventDefault();
    $("#grid_capture").find("input").trigger("blur");
    window.setTimeout(captureGrid, 50);
  });
})();
