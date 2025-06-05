import readyHandler from "../../lib/readyHandler";
import { slideDown } from "../../lib/animation";
import PostDetector from "./newPosts/PostDetector";

export async function loadNewPosts() {
  const discussionLink = document.querySelector(
    "#discussionLink"
  ) as HTMLAnchorElement;
  if (!discussionLink) return;

  PostDetector.pause();
  document.dispatchEvent(new Event("postsloading"));

  const exchangeUrl = discussionLink.href;
  const [, exchangeType, exchangeId] = exchangeUrl.match(
    /\/\/[\w\d.:]+\/(discussions|conversations)\/([\d]+)/
  );

  const endpoint =
    `/${exchangeType}/${exchangeId}/posts` +
    `/since/${PostDetector.read_posts}`;

  try {
    const response = await fetch(endpoint, {
      headers: {
        "X-Requested-With": "XMLHttpRequest"
      }
    });
    const data = await response.text();

    // Create container if needed
    let ajaxPosts = document.querySelector(".posts #ajaxPosts");
    if (!ajaxPosts) {
      ajaxPosts = document.createElement("div");
      ajaxPosts.id = "ajaxPosts";
      document.querySelector(".posts").appendChild(ajaxPosts);
    }

    // Insert content
    ajaxPosts.insertAdjacentHTML("beforeend", data);
    const newPosts = ajaxPosts.querySelectorAll(
      ".post:not(.shown)"
    ) as NodeListOf<HTMLElement>;

    // Animate new posts
    newPosts.forEach((post) => {
      slideDown(post);
      post.classList.add("shown");
    });

    // Update read posts count
    PostDetector.mark_posts_read(newPosts.length);

    PostDetector.resume();
    document.dispatchEvent(
      new CustomEvent("postsloaded", {
        detail: Array.from(newPosts)
      })
    );
  } catch (error) {
    console.error("Failed to load new posts:", error);
  }
}

readyHandler.ready(() => {
  // Start the post detector
  const discussion = document.getElementById("discussion") as HTMLDivElement;
  const newPosts = document.getElementById("newPosts");

  if (discussion && newPosts && document.body.classList.contains("last_page")) {
    PostDetector.start(discussion);
  }

  const originalTitle = document.title;

  // Update the window title on new posts
  document.addEventListener("newposts", (event: NewPostsEvent) => {
    document.title = `(${event.detail.unread}) ${originalTitle}`;
  });

  // Reset the document title when posts are loaded
  document.addEventListener("postsloaded", () => {
    document.title = originalTitle;
  });

  // Update the total posts count on the paginator
  document.addEventListener("newposts", (event: NewPostsEvent) => {
    const totalCount = document.querySelector(".total_items_count");
    if (totalCount) totalCount.textContent = event.detail.total.toString();
  });

  // Update the number of shown posts
  document.addEventListener("postsloaded", () => {
    const shownCount = document.querySelectorAll(".shown_items_count");
    if (shownCount && PostDetector.read_posts) {
      shownCount.forEach((s) => {
        s.textContent = PostDetector.read_posts.toString();
      });
    }
  });

  // Show the notification on new posts
  document.addEventListener("newposts", (event: NewPostsEvent) => {
    let notificationString =
      event.detail.unread === 1
        ? "A new post has been made"
        : `${event.detail.unread} new posts have been made`;

    const discussionLink = document.querySelector(
      "#discussionLink"
    ) as HTMLAnchorElement;
    notificationString += `, <a href="${discussionLink.href}">click here to load</a>.`;

    newPosts.innerHTML = `<p>${notificationString}</p>`;

    const loadLink = newPosts.querySelector("a");
    if (loadLink) {
      loadLink.addEventListener("click", (e) => {
        e.preventDefault();
        loadNewPosts();
      });
    }

    if (!newPosts.classList.contains("new_posts_since_refresh")) {
      newPosts.classList.add("new_posts_since_refresh");
      newPosts.style.display = "block";
      slideDown(newPosts);
    }
  });

  // Show loading status
  document.addEventListener("postsloading", () => {
    newPosts.classList.add("new_posts_since_refresh");
    newPosts.innerHTML = "Loading&hellip;";
  });

  // Hide when posts are loaded
  document.addEventListener("postsloaded", () => {
    newPosts.classList.remove("new_posts_since_refresh");
    newPosts.innerHTML = "";
    newPosts.style.display = "none";
  });
});
