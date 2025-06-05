// Entry point for the build script in your package.json

// Rails
import Rails from "@rails/ujs";
Rails.start();

import B3S from "./b3s";
declare const window: Window & {
  B3S: typeof B3S;
};
window.B3S = B3S;

import readyHandler from "./lib/readyHandler";
import { applyRichTextArea } from "./b3s/richTextArea";

import "./b3s/embeds";
import "./b3s/referrals";
import "./b3s/timestamps";

import "./mobile/functions";

readyHandler.start(() => {
  B3S.init();
  applyRichTextArea();
});

// React
import * as Components from "./components";
import ReactRailsUJS from "react_ujs";
ReactRailsUJS.getConstructor = (className: string) =>
  Components[className] as React.FC;
