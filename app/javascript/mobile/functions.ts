import readyHandler from "../lib/readyHandler";

declare const window: Window & {
  mutedUsers?: number[];
};

function toggleNavigation() {
  const nav = document.getElementById("navigation");
  if (nav) {
    nav.classList.toggle("active");
  }
}

function permalink(post: HTMLDivElement) {
  const link: HTMLAnchorElement = post.querySelector(".post_info .permalink");
  if (link && "href" in link) {
    return link.href.replace(/^https?:\/\/([\w\d.:-]*)/, "");
  }
}

function wrapEmbeds() {
  const selectors: string[] = [
    'iframe[src*="bandcamp.com"]',
    'iframe[src*="player.vimeo.com"]',
    'iframe[src*="youtube.com"]',
    'iframe[src*="youtube-nocookie.com"]',
    'iframe[src*="kickstarter.com"][src*="video.html"]'
  ];

  const embeds = [...document.querySelectorAll(selectors.join(","))];

  function wrapEmbed(embed: HTMLElement): HTMLDivElement {
    const wrapper = document.createElement("div");
    embed.parentNode.replaceChild(wrapper, embed);
    wrapper.appendChild(embed);
    return wrapper;
  }

  embeds.forEach(function (embed: HTMLElement) {
    const parent = embed.parentNode as HTMLElement;
    if (parent && parent.classList.contains("responsive-embed")) {
      return;
    }

    const width = embed.offsetWidth;
    const height = embed.offsetHeight;
    const ratio = height / width;
    const wrapper = wrapEmbed(embed);

    wrapper.classList.add("responsive-embed");
    wrapper.style.position = "relative";
    wrapper.style.width = "100%";
    wrapper.style.paddingBottom = `${ratio * 100}%`;

    embed.style.position = "absolute";
    embed.style.width = "100%";
    embed.style.height = "100%";
    embed.style.top = "0";
    embed.style.left = "0";
  });
}

readyHandler.start(function () {
  const updateLayout = function () {
    if (window.orientation != null) {
      if (window.orientation === 90 || window.orientation === -90) {
        document.body.setAttribute("orient", "landscape");
      } else {
        document.body.setAttribute("orient", "portrait");
      }
    }
  };

  window.addEventListener("orientationchange", updateLayout);
  window.addEventListener("resize", updateLayout);
  updateLayout();

  document.querySelectorAll(".toggle-navigation").forEach((el) => {
    el.addEventListener("click", toggleNavigation);
  });

  // Open images when clicked
  document
    .querySelectorAll(".post .body img")
    .forEach((img: HTMLImageElement) => {
      img.addEventListener("click", () => {
        document.location = img.src;
      });
    });

  // Larger click targets on discussion overview
  document
    .querySelectorAll(".discussions .discussion h2 a")
    .forEach((link: HTMLAnchorElement) => {
      link.parentNode.parentNode.addEventListener("click", () => {
        document.location = link.href;
      });
    });

  // Scroll past the Safari chrome
  if (!document.location.toString().match(/#/)) {
    setTimeout(scrollTo, 100, 0, 1);
  }

  // Search mode
  document
    .querySelectorAll("#search_mode")
    .forEach((elem: HTMLSelectElement) => {
      const parent = elem.parentNode as HTMLFormElement;
      elem.addEventListener("change", () => {
        parent.action = elem.value;
      });
    });

  // Post quoting
  document.querySelectorAll(".post").forEach((post: HTMLDivElement) => {
    const quoteLink = post.querySelector(".functions a.quote_post");
    if (quoteLink) {
      quoteLink.addEventListener("click", (evt) => {
        evt.preventDefault();
        const username = post.querySelector(
          ".post_info .username a"
        ).textContent;
        const html = post
          .querySelector(".body")
          .innerHTML.trim()
          .replace(/class="spoiler revealed"/g, 'class="spoiler"');
        document.dispatchEvent(
          new CustomEvent("quote", {
            detail: {
              username: username,
              permalink: permalink(post),
              html: html
            }
          })
        );
      });
    }
  });

  // Muted posts
  document.querySelectorAll(".post").forEach((post: HTMLDivElement) => {
    const userId = parseInt(post.dataset.userId);
    const mutedUsers = window.mutedUsers as number[] | null;

    if (mutedUsers && mutedUsers.indexOf(userId) !== -1) {
      const notice = document.createElement("div");
      const showLink = document.createElement("a");
      const username = post.querySelector(".username a").textContent;

      showLink.innerHTML = "Show";
      showLink.addEventListener("click", (evt) => {
        evt.preventDefault();
        post.classList.remove("muted");
      });

      notice.classList.add("muted-notice");
      notice.innerHTML = `This post by <strong>${username}</strong> has been muted. `;
      notice.appendChild(showLink);

      post.classList.add("muted");
      post.appendChild(notice);
    }
  });

  // Spoiler tags
  document.querySelectorAll(".spoiler").forEach((spoiler) => {
    spoiler.addEventListener("click", () => {
      spoiler.classList.toggle("revealed");
    });
  });

  // Confirm regular site
  document.querySelector("a.regular_site").addEventListener("click", (evt) => {
    if (
      !confirm(
        "Are you sure you want to navigate away from the mobile version?"
      )
    ) {
      evt.preventDefault();
    }
  });

  wrapEmbeds();
});
