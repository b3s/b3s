import readyHandler from "../../lib/readyHandler";

readyHandler.ready(() => {
  const buttonContainer = document.querySelector("#button-container");

  function showStatus(message: string) {
    buttonContainer.querySelector(".status").innerHTML = message;

    buttonContainer.querySelectorAll("button").forEach((button) => {
      button.style.display = "none";
    });

    buttonContainer.classList.add("posting");
  }

  function clearStatus() {
    buttonContainer.querySelector(".status").innerHTML = "";
    buttonContainer.querySelectorAll("button").forEach((button) => {
      button.style.display = "inline-block";
    });
    buttonContainer.classList.remove("posting");

    if (document.querySelector(".posts #previewPost")) {
      buttonContainer.querySelector(".preview span").innerHTML =
        "Update Preview";
    } else {
      buttonContainer.querySelector(".preview span").innerHTML = "Preview";
    }
  }

  document.addEventListener("posting-status", (event: PostingStatusEvent) => {
    showStatus(event.detail);
  });

  document.addEventListener("posting-complete", () => {
    clearStatus();
  });
});
