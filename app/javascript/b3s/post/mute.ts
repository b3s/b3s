declare const window: Window & {
  mutedUsers?: number[];
};

export default function mute(post: HTMLElement) {
  const mutedUsers = window.mutedUsers;
  const userId = parseInt(post.dataset.user_id, 10);

  if (mutedUsers && mutedUsers.indexOf(userId) !== -1) {
    const notice = document.createElement("div");
    const showLink = document.createElement("a");
    let username = "";
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
    notice.innerHTML = `This post by <strong>${username}</strong> has been muted. `;
    notice.appendChild(showLink);

    post.classList.add("muted");
    post.append(notice);
  }
}
