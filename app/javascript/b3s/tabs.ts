type TabOptions = {
  showFirstTab: boolean;
};

type TabLink = HTMLAnchorElement & {
  tabId: string;
};

function setDisplay(elem: HTMLDivElement | null, style: string) {
  if (elem) {
    elem.style.display = style;
  }
}

export function setupTabs(
  controls: HTMLElement,
  options: TabOptions
): [TabLink[], (tab: TabLink) => void] {
  const tabs: TabLink[] = [];

  const settings = { showFirstTab: true, ...options };

  let anchorTab = null;
  let tabShown = false;

  const hideAllTabs = () => {
    tabs.forEach((tab: TabLink) => {
      setDisplay(document.querySelector(tab.tabId) as HTMLDivElement, "none");
      if (tab.parentNode) {
        (tab.parentNode as HTMLElement).classList.remove("active");
      }
    });
  };

  const showTab = (tab: TabLink) => {
    hideAllTabs();
    setDisplay(document.querySelector(tab.tabId) as HTMLDivElement, "block");
    if (tab.parentNode) {
      (tab.parentNode as HTMLElement).classList.add("active");
    }
  };

  controls.querySelectorAll("a").forEach((link: TabLink) => {
    link.tabId = link.href.match(/(#[\w\d\-_]+)$/)[1];
    tabs.push(link);
    link.addEventListener("click", (evt) => {
      evt.preventDefault();
      showTab(link);
    });
  });

  hideAllTabs();

  if (document.location.toString().match(/(#[\w\d\-_]+)$/)) {
    anchorTab = document.location.toString().match(/(#[\w\d\-_]+)$/)[1];

    for (let a = 0; a < tabs.length; a++) {
      if (tabs[a].tabId === anchorTab) {
        showTab(tabs[a]);
        tabShown = true;
      }
    }
  }
  if (!tabShown && settings.showFirstTab) {
    showTab(tabs[0]);
  }

  return [tabs, showTab];
}
