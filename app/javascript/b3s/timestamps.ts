import readyHandler from "../lib/readyHandler";
import RelativeTime from "../components/RelativeTime";

import { createElement } from "react";
import { createRoot } from "react-dom/client";

function applyTimestamps() {
  const tags = document.querySelectorAll("time.relative");
  tags.forEach((elem: HTMLTimeElement) => {
    const date = elem.getAttribute("datetime");
    if (date && !elem.dataset.react) {
      const root = createRoot(elem);
      root.render(createElement(RelativeTime, { time: date }, null));
      elem.dataset.react = "true";
    }
  });
}

applyTimestamps();
readyHandler.ready(applyTimestamps);
document.addEventListener("postsloaded", applyTimestamps);
