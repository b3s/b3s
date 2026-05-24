import type { Subscription } from "@rails/actioncable";
import consumer from "../../channels/consumer";

interface BufferedPost {
  id: number;
  html: string;
}

const PostDetector = {
  id: null as string | null,
  paused: false,
  subscription: null as Subscription | null,
  total_posts: null as number | null,
  read_posts: null as number | null,
  type: "Discussion" as "Discussion" | "Conversation",
  buffer: [] as BufferedPost[],
  expected_next_count: null as number | null,
  has_gap: false,

  receive(data: { posts_count: number; post_id: number; html: string }) {
    if (this.paused) {
      this.has_gap = true;
      this.buffer = [];
      return;
    }
    const new_posts = data.posts_count - this.total_posts;
    if (new_posts <= 0) return;

    if (
      this.expected_next_count !== null &&
      data.posts_count === this.expected_next_count
    ) {
      this.buffer.push({ id: data.post_id, html: data.html });
    } else {
      this.has_gap = true;
      this.buffer = [];
    }
    this.expected_next_count = data.posts_count + 1;
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

  consume_buffer(): string | null {
    if (this.has_gap || this.buffer.length === 0) return null;
    const html = this.buffer.map((p) => p.html).join("");
    this.buffer = [];
    return html;
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

    if (this.expected_next_count === null) {
      this.expected_next_count = this.total_posts + 1;
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
    this.has_gap = false;
    this.buffer = [];
    this.expected_next_count = this.total_posts + 1;
  }
};

export default PostDetector;
