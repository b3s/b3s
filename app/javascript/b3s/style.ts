import readyHandler from "../lib/readyHandler";
import { setupTabs } from "./tabs";

function wrapButtons() {
  document.querySelectorAll("a.button, button").forEach((button) => {
    if (!button.querySelector("span")) {
      const span = document.createElement("span");
      span.innerHTML = button.innerHTML;
      button.innerHTML = "";
      button.appendChild(span);
    }
  });
}

readyHandler.ready(() => {
  wrapButtons();
  const observer = new MutationObserver(wrapButtons);
  observer.observe(document.body, {
    attributes: true,
    childList: true,
    subtree: true
  });

  const discussionTable = document.querySelector(
    "table.discussions"
  ) as HTMLTableElement;
  if (discussionTable) {
    const content = document.getElementById("content");
    if (content) {
      content.style.minWidth = `${discussionTable.offsetWidth}px`;
    }
  }

  const sidebar = document.getElementById("sidebar");
  const content = document.getElementById("content");
  const wrapper = document.getElementById("wrapper");
  if (sidebar && content && wrapper) {
    const minWidth = content.offsetWidth + sidebar.offsetWidth;
    wrapper.style.minWidth = `${minWidth}px`;
  }

  const replyTabs = document.getElementById("reply-tabs");
  if (replyTabs) {
    const [tabs, showTab] = setupTabs(replyTabs, { showFirstTab: false });

    if (document.body.classList.contains("last_page")) {
      showTab(tabs[0]);
    }

    const textarea = document.querySelector("#replyText textarea");
    if (textarea) {
      textarea.addEventListener("focus", () => showTab(tabs[0]));
    }

    document.addEventListener("quote", () => showTab(tabs[0]));
  }

  const signupTabs = document.getElementById("signup-tabs");
  if (signupTabs) {
    setupTabs(signupTabs, { showFirstTab: true });
  }

  const configTabs = document.querySelector(
    ".admin.configuration .tabs"
  ) as HTMLElement;
  if (configTabs) {
    setupTabs(configTabs, { showFirstTab: true });
  }
});
