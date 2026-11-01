import { useReducer } from "react";
import { v4 as uuidv4 } from "uuid";

function updateLink(state: UserLink.State, link: UserLink.Link) {
  return {
    ...state,
    userLinks: state.userLinks.map((ul) => {
      if (ul.handle === link.handle) {
        return link;
      } else {
        return ul;
      }
    })
  };
}

function newUserLink(): UserLink.Link {
  return {
    id: null,
    label: "",
    name: "",
    url: "",
    deleted: false,
    errors: [],
    handle: uuidv4()
  };
}

function saveUserLink(state: UserLink.State, userLink: UserLink.Link) {
  let userLinks = state.userLinks;
  if (userLinks.filter((a) => a.handle == userLink.handle).length > 0) {
    userLinks = userLinks.map((a) => {
      if (a.handle == userLink.handle) {
        return userLink;
      } else {
        return a;
      }
    });
  } else {
    userLinks = userLinks.concat({ ...userLink });
  }
  return { ...state, userLinks: userLinks, editing: null };
}

function reducer(
  state: UserLink.State,
  action: UserLink.Action
): UserLink.State {
  switch (action.type) {
    case "add":
      return { ...state, editing: newUserLink() };
    case "cancel":
      return { ...state, editing: null };
    case "delete":
      if (action.payload.id) {
        return updateLink(state, { ...action.payload, deleted: true });
      } else {
        return {
          ...state,
          userLinks: state.userLinks.filter(
            (ul) => ul.handle !== action.payload.handle
          )
        };
      }
    case "edit":
      return { ...state, editing: action.payload };
    case "reorder":
      return { ...state, userLinks: action.payload };
    case "save":
      return saveUserLink(state, action.payload);
    case "update":
      return updateLink(state, action.payload);
  }
}

function createInitialState(userLinks: UserLink.Link[]): UserLink.State {
  return {
    editing: null,
    userLinks: userLinks.map((ul) => {
      return {
        ...ul,
        deleted: ul.deleted ?? false,
        errors: ul.errors ?? [],
        handle: uuidv4()
      };
    })
  };
}

function ensureDeletedLastReducer(
  state: UserLink.State,
  action: UserLink.Action
): UserLink.State {
  const nextState = reducer(state, action);
  return {
    ...nextState,
    userLinks: [
      ...nextState.userLinks.filter((l) => !l.deleted),
      ...nextState.userLinks.filter((l) => l.deleted)
    ]
  };
}

export default function useUserLinks(
  userLinks: UserLink.Link[]
): [UserLink.State, (action: UserLink.Action) => void] {
  const [state, dispatch] = useReducer(
    ensureDeletedLastReducer,
    userLinks,
    createInitialState
  );
  return [state, dispatch];
}
