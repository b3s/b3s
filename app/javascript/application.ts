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

import "./b3s/exchanges/newDiscussion";
import "./b3s/hotkeys";
import "./b3s/embeds";
import "./b3s/posts/buttons";
import "./b3s/posts/newPosts";
import "./b3s/posts/preview";
import "./b3s/posts/submit";
import "./b3s/referrals";
import "./b3s/search";
import "./b3s/style";
import "./b3s/timestamps";
import "./b3s/users/editProfile";

readyHandler.start(() => {
  B3S.init();
  applyRichTextArea();
});

// React
import * as Tombolo from "tombolo";
import * as Components from "./components";
Tombolo.start(Components);
