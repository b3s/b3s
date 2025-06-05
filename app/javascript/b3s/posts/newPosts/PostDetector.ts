const PostDetector = {
  id: null,
  paused: false,
  interval: null,
  total_posts: null,
  read_posts: null,
  type: "Discussion",

  refresh: async function () {
    if (!this.paused) {
      try {
        const response = await fetch(this.postsCountUrl());
        const json = await response.json();
        const new_posts = json.posts_count - this.total_posts;

        if (new_posts > 0) {
          this.total_posts = json.posts_count;
          document.dispatchEvent(
            new CustomEvent("newposts", {
              detail: {
                total: this.total_posts,
                newPosts: new_posts,
                unread: this.total_posts - this.read_posts
              }
            })
          );
        }
      } catch (error) {
        console.error("Failed to fetch posts:", error);
      }
    }
  },

  postsCountUrl: function () {
    const baseUrl =
      this.type === "Conversation" ? "/conversations" : "/discussions";
    return `${baseUrl}/${this.id}/posts/count.json?` + new Date().getTime();
  },

  start: function (container: HTMLDivElement) {
    this.paused = false;

    if (container.dataset.type === "Conversation") {
      this.type = "Conversation";
    }

    this.id = container.dataset.id;

    if (!this.read_posts) {
      this.read_posts = parseInt(container.dataset.postsCount);
    }

    if (!this.total_posts) {
      this.total_posts = this.read_posts;
    }

    if (!this.interval) {
      this.interval = setInterval(function () {
        PostDetector.refresh();
      }, 5000);
    }
  },

  stop: function () {
    this.paused = true;
    clearInterval(this.interval);
    this.interval = null;
  },

  pause: function () {
    this.paused = true;
  },

  resume: function () {
    this.paused = false;
  },

  mark_posts_read: function (count: number) {
    this.read_posts += count;
    if (this.total_posts < this.read_posts) {
      this.total_posts = this.read_posts;
    }
  }
};

export default PostDetector;
