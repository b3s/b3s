import $ from "jquery";
import readyHandler from "../lib/readyHandler";

function toggleNavigation() {
  $("#navigation").toggleClass("active");
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

  $(".toggle-navigation").click(function () {
    toggleNavigation();
  });

  // Open images when clicked
  $(".post .body img").click(function (_, img: HTMLImageElement) {
    document.location = img.src;
  });

  // Larger click targets on discussion overview
  $(".discussions .discussion h2 a").each(function (_, link: HTMLLinkElement) {
    $(this.parentNode.parentNode).click(function () {
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
  $(".post .functions a.quote_post").click(function () {
    const stripWhitespace = function (str: string) {
      return str.replace(/^[\s]*/, "").replace(/[\s]*$/, "");
    };

    const post = $(this).closest(".post");
    const username = post.find(".post_info .username a").text();
    const permalinkElem = post
      .find(".post_info .permalink")
      .get()[0] as HTMLLinkElement;
    const permalink = permalinkElem.href.replace(
      /^https?:\/\/([\w\d.:-]*)/,
      ""
    );

    let html = stripWhitespace(post.find(".body").html());

    // Hide spoilers
    html = html.replace(/class="spoiler revealed"/g, 'class="spoiler"');

    document.dispatchEvent(
      new CustomEvent("quote", {
        detail: {
          username: username,
          permalink: permalink,
          html: html
        }
      })
    );

    return false;
  });

  // Muted posts
  $(".post").each(function () {
    const userId = $(this).data("user_id") as string;
    const mutedUsers = window.mutedUsers as number[] | null;
    if (mutedUsers && mutedUsers.indexOf(userId) !== -1) {
      const notice = document.createElement("div");
      const showLink = document.createElement("a");
      const username = this.querySelector(".username a").textContent;

      showLink.innerHTML = "Show";
      showLink.addEventListener("click", (evt) => {
        evt.preventDefault();
        this.classList.remove("muted");
      });

      notice.classList.add("muted-notice");
      notice.innerHTML = `This post by <strong>${username}</strong> has been muted. `;
      notice.appendChild(showLink);

      this.classList.add("muted");
      this.appendChild(notice);
    }
  });

  // Posting
  $("form.new_post").submit(function () {
    // let body = $(this).find("#compose-body");
    return true;
  });

  // Spoiler tags
  $(".spoiler").click(function () {
    $(this).toggleClass("revealed");
  });

  // Login
  $("section.login").each(function () {
    function forgotPassword() {
      $("#login").toggle();
      $("#password-reminder").toggle();
    }
    $("#password-reminder").hide();
    $(".forgot-password").click(forgotPassword);
  });

  // Confirm regular site
  $("a.regular_site").click(function () {
    return confirm(
      "Are you sure you want to navigate away from the mobile version?"
    );
  });

  wrapEmbeds();
});
