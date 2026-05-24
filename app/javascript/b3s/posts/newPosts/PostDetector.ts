import type { Subscription } from "@rails/actioncable";
import consumer from "../../channels/consumer";

const PostDetector = {
  id: null as string | null,
  paused: false,
  subscription: null as Subscription | null,
  total_posts: null as number | null,
  read_posts: null as number | null,
  type: "Discussion" as "Discussion" | "Conversation",

  receive(data: { posts_count: number }) {
    if (this.paused) return;
    const new_posts = data.posts_count - this.total_posts;
    if (new_posts <= 0) return;

    this.total_posts = data.posts_count;
    document.dispatchEvent(
      new CustomEvent("newposts", {
        detail: {
          total: this.total_posts,
          newPosts: new_posts,
          unread: this.total_posts - this.read_posts
        }
      })
    );
  },

  start(container: HTMLDivElement) {
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

    if (!this.subscription) {
      this.subscription = consumer.subscriptions.create(
        { channel: "ExchangeChannel", id: this.id },
        { received: (data) => PostDetector.receive(data) }
      );
    }
  },

  stop() {
    this.paused = true;
    this.subscription?.unsubscribe();
    this.subscription = null;
  },

  pause() {
    this.paused = true;
  },

  resume() {
    this.paused = false;
  },

  mark_posts_read(count: number) {
    this.read_posts += count;
    if (this.total_posts < this.read_posts) {
      this.total_posts = this.read_posts;
    }
  }
};

export default PostDetector;
