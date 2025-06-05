import readyHandler from "../lib/readyHandler";
import gifvVideos from "./embeds/gifvVideos";
import mastodonEmbeds from "./embeds/mastodonEmbeds";
import responsiveEmbeds from "./embeds/responsiveEmbeds";

interface PostCache {
  height: number;
  order: number;
}

interface Cache {
  posts: Record<number, PostCache>;
  anchorPostId: number;
  anchorPostOrder: number;
  scrollY: number;
}

function setupEmbeds() {
  gifvVideos();
  mastodonEmbeds();
  responsiveEmbeds();
}

/**
 * Handlers for scripted embed (social) quirks
 */
readyHandler.ready(function () {
  // Fix for misbehaving or missing scroll anchoring
  const postsPage = document.querySelector(".posts");
  if (postsPage) {
    /**
     * Retrieved a post ID from a string which may
     * include a "post-" prefix.
     */
    const parsePostIdString = (idString: string): number => {
      const idNum = idString.match(/(post-)?(\d+)/i);
      if (idNum && idNum.length) {
        return parseInt(idNum[2]);
      }
      return 0;
    };

    /**
     * Retrieve a post ID from its node, handling mobile
     * template and potential changes
     */
    const getPostId = (post: HTMLElement) => {
      let postId = 0;
      if (post.dataset.post_id) {
        postId = parseInt(post.dataset.post_id);
      } else if (post.id.includes("post-")) {
        postId = parsePostIdString(post.id);
      } else {
        const anchor = post.querySelector(".anchor");
        if (anchor) {
          const anchorName = anchor.getAttribute("name");
          if (anchorName) {
            postId = parsePostIdString(anchorName);
          }
        }
      }
      return postId;
    };

    const cache: Cache = {
      posts: {},
      anchorPostId: parsePostIdString(window.location.hash),
      anchorPostOrder: 0,
      scrollY: window.scrollY
    };

    const resizeObserver = new ResizeObserver((posts) => {
      posts.forEach((entry) => {
        const post = entry.target as HTMLDivElement;
        const postId = getPostId(post);
        const pCache = cache.posts[postId];

        // Do not act on posts after or including our anchor
        if (!pCache || pCache.order >= cache.anchorPostOrder) {
          return;
        }

        // Prevent editing from triggering scroll
        const pBody = post.querySelector(".body") as HTMLDivElement;
        if (!pBody || pBody.offsetHeight < 1) {
          return;
        }

        let boxSize = pCache.height;
        if (entry.borderBoxSize && entry.borderBoxSize.length) {
          boxSize = entry.borderBoxSize[0].blockSize;
        } else {
          boxSize = entry.contentRect.height;
        }

        const offset = boxSize - pCache.height;

        if (cache.scrollY !== window.scrollY) {
          // Chrome updates the scroll position, but not the scroll!
          window.scrollTo(window.scrollX, window.scrollY);
        } else {
          // otherwise, scroll by our height offset
          window.scrollBy(0, offset);
        }

        cache.scrollY = window.scrollY;
        cache.posts[postId].height = boxSize;
      });
    });

    /**
     * Loop through all posts on the page, store their
     * initial height and order in the cache, and attach
     * the resize observer.
     */
    postsPage.querySelectorAll(".post").forEach((post: HTMLDivElement, i) => {
      const postId = getPostId(post);
      // We only need posts before our anchor
      if (cache.anchorPostOrder && i >= cache.anchorPostOrder) {
        return;
      }
      cache.posts[postId] = {
        height: post.getBoundingClientRect().height,
        order: i
      };
      if (postId === cache.anchorPostId) {
        cache.anchorPostOrder = i;
      }
      resizeObserver.observe(post);
    });
  }

  document.addEventListener("postsloaded", setupEmbeds);

  setupEmbeds();
});
