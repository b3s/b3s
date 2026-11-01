declare const window: Window & {
  mutedUsers?: number[];
};

export default function mute(post: HTMLElement) {
  const mutedUsers = window.mutedUsers;
  const userId = parseInt(post.dataset.userId, 10);

  if (mutedUsers && mutedUsers.indexOf(userId) !== -1) {
    const notice = document.createElement("div");
    const showLink = document.createElement("a");
    let username: string;
    if (post.classList.contains("me_post")) {
      username = post.querySelector(".content a.poster").textContent;
    } else {
      username = post.querySelector(".username a").textContent;
    }

    showLink.innerHTML = "Show";
    showLink.addEventListener("click", (evt) => {
      evt.preventDefault();
      post.classList.remove("muted");
    });

    notice.classList.add("muted-notice");
    const name = document.createElement("strong");
    name.textContent = username;
    notice.append("This post by ", name, " has been muted. ", showLink);

    post.classList.add("muted");
    post.append(notice);
  }
}
