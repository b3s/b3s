type ImgurEmbed = {
  tasks: number;
  createIframe?: () => void;
};

declare const window: Window & {
  bluesky?: { scan?: (node?: ParentNode) => void };
  instgrm?: { Embeds?: { process?: () => void } };
  FB?: { XFBML?: { parse?: (node?: Element) => void } };
  imgurEmbed?: ImgurEmbed;
};

type Provider = {
  name: string;
  selector: string;
  src: string;
  legacyScripts: string;
  crossOrigin?: string;
  loaded: () => boolean;
  process: () => void;
  prepare?: () => void;
  afterLoad?: () => void;
  reinject?: boolean;
};

type State = "idle" | "waiting" | "loading" | "loaded";

const states = new Map<string, State>();

function scoped(selector: string) {
  return selector
    .split(",")
    .map((s) => `.post .body div.embed[data-oembed-url] ${s.trim()}`)
    .join(", ");
}

function pendingEmbeds(provider: Provider) {
  return document.querySelectorAll(scoped(provider.selector));
}

function injectScript(provider: Provider, onLoad: () => void) {
  const script = document.createElement("script");

  script.src = provider.src;
  script.async = true;
  if (provider.crossOrigin) {
    script.crossOrigin = provider.crossOrigin;
  }
  script.addEventListener("load", onLoad, { once: true });
  script.addEventListener("error", () => states.set(provider.name, "idle"), {
    once: true
  });

  document.head.appendChild(script);
}

function processImgur() {
  const imgurEmbed = window.imgurEmbed;
  if (!imgurEmbed) {
    return;
  }
  const count = pendingEmbeds(imgur).length;
  if (imgurEmbed.createIframe) {
    for (let i = 0; i < count; i++) {
      imgurEmbed.createIframe();
    }
  } else {
    imgurEmbed.tasks = Math.max(imgurEmbed.tasks, count);
  }
}

function parseFacebook() {
  const containers = new Set<Element>();
  pendingEmbeds(facebook).forEach((elem) =>
    containers.add(elem.closest("div.embed[data-oembed-url]"))
  );
  containers.forEach((container) => window.FB?.XFBML?.parse?.(container));
}

const bluesky: Provider = {
  name: "bluesky",
  selector: "blockquote.bluesky-embed[data-bluesky-uri]",
  src: "https://embed.bsky.app/static/embed.js",
  legacyScripts: 'script[src*="embed.bsky.app/static/embed.js"]',
  loaded: () => typeof window.bluesky?.scan === "function",
  process: () => window.bluesky?.scan?.(),
  afterLoad: () => window.bluesky?.scan?.()
};

const instagram: Provider = {
  name: "instagram",
  selector: "blockquote.instagram-media",
  src: "https://www.instagram.com/embed.js",
  legacyScripts:
    'script[src*="instagram.com/embed.js"], ' +
    'script[src*="instagram.com/en_US/embeds.js"]',
  loaded: () => typeof window.instgrm?.Embeds?.process === "function",
  process: () => window.instgrm?.Embeds?.process?.(),
  afterLoad: () => window.instgrm?.Embeds?.process?.()
};

const facebook: Provider = {
  name: "facebook",
  selector:
    "div.fb-post:not([fb-xfbml-state]), div.fb-video:not([fb-xfbml-state])",
  src: "https://connect.facebook.net/en_US/sdk.js#version=v26.0",
  legacyScripts: 'script[src*="connect.facebook.net/"][src*="/sdk.js"]',
  crossOrigin: "anonymous",
  loaded: () => typeof window.FB?.XFBML?.parse === "function",
  process: parseFacebook,
  afterLoad: parseFacebook,
  prepare: () => {
    if (!document.getElementById("fb-root")) {
      const root = document.createElement("div");
      root.id = "fb-root";
      document.body.prepend(root);
    }
  }
};

const tumblr: Provider = {
  name: "tumblr",
  selector: 'div.tumblr-post[data-href*="tumblr.com/"]',
  src: "https://assets.tumblr.com/post.js",
  legacyScripts: 'script[src*="assets.tumblr.com/post.js"]',
  loaded: () => false,
  process: () => {},
  reinject: true
};

const imgur: Provider = {
  name: "imgur",
  selector: "blockquote.imgur-embed-pub",
  src: "https://s.imgur.com/min/embed.js",
  legacyScripts: 'script[src*="s.imgur.com/min/embed.js"]',
  loaded: () => !!window.imgurEmbed,
  process: processImgur,
  afterLoad: processImgur
};

const providers = [bluesky, instagram, facebook, tumblr, imgur];

function loadProvider(provider: Provider) {
  if (pendingEmbeds(provider).length === 0) {
    return;
  }

  const state = states.get(provider.name) || "idle";

  if (state === "waiting" || state === "loading") {
    return;
  }
  if (state === "loaded" && !provider.reinject) {
    provider.process();
    return;
  }

  if (state === "idle") {
    if (
      document.readyState !== "complete" &&
      document.querySelector(provider.legacyScripts)
    ) {
      states.set(provider.name, "waiting");
      window.addEventListener(
        "load",
        () => {
          states.set(provider.name, "idle");
          loadProvider(provider);
        },
        { once: true }
      );
      return;
    }

    if (provider.loaded()) {
      states.set(provider.name, "loaded");
      provider.process();
      return;
    }
  }

  provider.prepare?.();
  states.set(provider.name, "loading");
  injectScript(provider, () => {
    states.set(provider.name, "loaded");
    provider.afterLoad?.();
  });
}

export default function embedScripts() {
  providers.forEach(loadProvider);
}
