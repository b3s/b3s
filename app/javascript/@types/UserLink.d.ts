declare namespace UserLink {
  type Link = {
    id: number | null;
    label: string;
    name: string;
    url: string;
    deleted: boolean;
    errors: string[];
    handle: string;
  };

  type State = {
    editing: Link | null;
    userLinks: Link[];
  };

  type Action =
    | { type: "add" | "cancel" }
    | { type: "delete" | "edit" | "save" | "update"; payload: Link }
    | { type: "reorder"; payload: Link[] };
}
