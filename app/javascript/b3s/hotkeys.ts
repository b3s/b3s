import readyHandler from "../lib/readyHandler";
import { loadNewPosts } from "./posts/newPosts";
import quote from "./post/quote";

import bindKey from "./hotkeys/bindKey";
import specialKeys from "./hotkeys/specialKeys";

type KeySequence = [RegExp, () => void];

(function () {
  let currentTarget: HTMLElement | null = null;
  let keySequence = "";
  const keySequences: KeySequence[] = [];

  const bindKeySequence = (expression: RegExp, fn: () => void) =>
    keySequences.push([expression, fn]);

  const exchangeId = (target: HTMLElement): string | undefined => {
    return target.closest("tr")?.dataset.exchangeId;
  };

  const clearNewPostsFromDiscussion = (target: HTMLElement): void => {
    const id = exchangeId(target);
    if (!id) return;

    document.querySelectorAll(`.discussion${id}`).forEach((el) => {
      el.classList.remove("new_posts");
    });

    document.querySelectorAll(`.discussion${id} .new_posts`).forEach((el) => {
      el.innerHTML = "";
    });
  };

  const defaultTarget = (): HTMLElement | undefined => {
    const hash = document.location.hash;
    const match = hash.match(/^#post-([\d]+)$/);

    if (match) {
      const postId = match[1];
      return (
        document.querySelector(`.post[data-post_id="${postId}"]`) || undefined
      );
    }
  };

  const elemOutOfWindow = (elem: HTMLElement): boolean => {
    const rect = elem.getBoundingClientRect();
    const windowHeight = window.innerHeight;
    return rect.top < 0 || rect.bottom > windowHeight;
  };

  const focusElement = (event: Event, selector: string): void => {
    const element = document.querySelector<HTMLElement>(selector);
    element?.focus();
    event.preventDefault();
  };

  const isDiscussion = (target: HTMLElement): boolean => {
    return target.closest("tr")?.classList.contains("discussion") || false;
  };

  const keypressToCharacter = (event: KeyboardEvent): string | undefined => {
    if (event.key in specialKeys) {
      return undefined;
    }
    return event.shiftKey ? event.key.toUpperCase() : event.key.toLowerCase();
  };

  const markAsRead = async (target: HTMLElement): Promise<void> => {
    if (isDiscussion(target)) {
      const id = exchangeId(target);
      if (!id) return;

      const path = `/discussions/${id}/mark_as_read`;
      try {
        await fetch(path);
        clearNewPostsFromDiscussion(target);
      } catch (error) {
        console.error("Failed to mark as read:", error);
      }
    }
  };

  const isExchangesView = (): boolean => {
    return document.querySelector("table.discussions") !== null;
  };

  const isPostsView = (): boolean => {
    return document.querySelectorAll(".posts .post").length > 0;
  };

  const onlyExchanges = (fn) => {
    if (isExchangesView()) {
      return fn();
    }
  };

  const onlyPosts = (fn) => {
    if (isPostsView()) {
      return fn();
    }
  };

  const visitPath = (path) => (document.location = path);

  const visitLink = (selector: string): void => {
    const element = document.querySelector<HTMLAnchorElement>(selector);
    if (element?.href) {
      document.location = element.href;
    }
  };

  const trackKeySequence = (event: KeyboardEvent): void => {
    const target = event.target as HTMLElement;
    if (target.matches("input, textarea, select")) {
      keySequence = "";
    } else {
      const character = keypressToCharacter(event);
      if (!event.metaKey && character?.match(/^[\w\d]$/)) {
        keySequence += character;
        keySequence = keySequence.match(/([\w\d]{0,5})$/)?.[1] || "";

        keySequences.forEach(([expression, fn]) => {
          if (keySequence.match(expression)) {
            fn();
          }
        });
      }
    }
  };

  const targets = (): HTMLElement[] => {
    const discussionTargets = Array.from(
      document.querySelectorAll<HTMLElement>("table.discussions td.name a")
    );
    const postTargets = Array.from(
      document.querySelectorAll<HTMLElement>(".posts .post")
    );
    return [...discussionTargets, ...postTargets];
  };

  const markTarget = (target: HTMLElement): void => {
    if (isExchangesView()) {
      document
        .querySelectorAll("tr.discussion, tr.conversation")
        .forEach((el) => el.classList.remove("targeted"));

      const id = exchangeId(target);
      document
        .querySelectorAll(`tr.discussion${id}, tr.conversation${id}`)
        .forEach((el) => el.classList.add("targeted"));
    } else {
      targets().forEach((el) => el.classList.remove("targeted"));
      target.classList.add("targeted");
    }

    if (elemOutOfWindow(target)) {
      target.scrollIntoView();
    }
  };

  const withTarget = <T>(fn: (target: HTMLElement) => T): T | void => {
    if (currentTarget) {
      return fn(currentTarget);
    }
  };

  const ifTargets = (fn: () => void): void => {
    if (targets().length > 0) {
      fn();
    }
  };

  const getRelative = <T>(
    collection: T[],
    item: T | undefined | null,
    offset: number
  ): T => {
    if (!item) return collection[0];
    const index = collection.indexOf(item);
    return collection[(index + offset + collection.length) % collection.length];
  };

  const nextTarget = (): HTMLElement =>
    getRelative(
      targets(),
      currentTarget || defaultTarget() || targets().slice(-1)[0],
      1
    );

  const previousTarget = (): HTMLElement =>
    getRelative(
      targets(),
      currentTarget || defaultTarget() || targets()[0],
      -1
    );

  const setTarget = (target: HTMLElement): void => {
    currentTarget = target;
    markTarget(target);
  };

  const resetTarget = (): void => {
    currentTarget = null;
  };

  const openTarget = (target: HTMLElement): void => {
    const anchor = target as HTMLAnchorElement;
    if (anchor.href) {
      document.location = anchor.href;
    }
  };

  const openTargetNewTab = (target: HTMLElement): void => {
    const anchor = target as HTMLAnchorElement;
    if (anchor.href) {
      window.open(anchor.href);
    }
  };

  document.addEventListener("keydown", trackKeySequence);

  bindKeySequence(/gd$/, () => visitPath("/discussions"));
  bindKeySequence(/gf$/, () => visitPath("/discussions/following"));
  bindKeySequence(/gF$/, () => visitPath("/discussions/favorites"));
  bindKeySequence(/gc$/, () => visitPath("/conversations"));
  bindKeySequence(/gi$/, () => visitPath("/invites"));
  bindKeySequence(/gu$/, () => visitPath("/users/online"));

  bindKey("shift+p", () => visitLink(".prev_page_link"));
  bindKey("shift+k", () => visitLink(".prev_page_link"));
  bindKey("shift+n", () => visitLink(".next_page_link"));
  bindKey("u", () => visitLink("#back_link"));
  bindKey("shift+j", () => visitLink(".next_page_link"));

  bindKey("p", () => ifTargets(() => setTarget(previousTarget())));
  bindKey("k", () => ifTargets(() => setTarget(previousTarget())));
  bindKey("n", () => ifTargets(() => setTarget(nextTarget())));
  bindKey("j", () => ifTargets(() => setTarget(nextTarget())));

  bindKey("r", () => onlyPosts(() => loadNewPosts()));
  bindKey("q", () =>
    onlyPosts(() => withTarget((t: HTMLDivElement) => quote(t)))
  );

  bindKey("o", () => onlyExchanges(() => withTarget((t) => openTarget(t))));
  bindKey("shift+o", () =>
    onlyExchanges(() => withTarget((t) => openTargetNewTab(t)))
  );
  bindKey("Return", () =>
    onlyExchanges(() => withTarget((t) => openTarget(t)))
  );
  bindKey("shift+Return", () =>
    onlyExchanges(() => withTarget((t) => openTargetNewTab(t)))
  );

  bindKey("y", () => onlyExchanges(() => withTarget((t) => markAsRead(t))));
  bindKey("m", () => onlyExchanges(() => withTarget((t) => markAsRead(t))));

  bindKey("c", (event) => {
    onlyExchanges(() => visitLink(".functions .create"));
    onlyPosts(() => focusElement(event, "#compose-body"));
  });

  readyHandler.ready(resetTarget);
}).call(this);
