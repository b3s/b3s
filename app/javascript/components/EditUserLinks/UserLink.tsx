import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";

import { isHttpUrl, normalizeUrl } from "./url";

type Props = {
  dispatch: (action: UserLink.Action) => void;
  position: number;
  userLink: UserLink.Link;
};

function label(userLink: UserLink.Link) {
  return userLink.name || userLink.url.replace(/^(f|ht)tps?:\/\//i, "");
}

export default function UserLink(props: Props) {
  const { dispatch, userLink } = props;
  const href = normalizeUrl(userLink.url || "");

  const {
    attributes,
    isDragging,
    listeners,
    setNodeRef,
    transform,
    transition
  } = useSortable({ id: userLink.handle });

  const style = { transform: CSS.Transform.toString(transform), transition };

  const handleEdit = (evt: React.MouseEvent) => {
    evt.preventDefault();
    dispatch({ type: "edit", payload: userLink });
  };

  const handleDelete = (evt: React.MouseEvent) => {
    evt.preventDefault();
    dispatch({ type: "delete", payload: userLink });
  };

  const classNames = ["user-link"];
  if (isDragging) {
    classNames.push("dragging");
  }

  return (
    <div
      className={classNames.join(" ")}
      ref={setNodeRef}
      style={style}
      {...attributes}>
      <div className="drag-handle" {...listeners}>
        <i className="fa-solid fa-grip-lines"></i>
      </div>
      <div className="info">
        <div className="label">{userLink.label}</div>
        <div className="link">
          {!isHttpUrl(href) && label(userLink)}
          {isHttpUrl(href) && <a href={href}>{label(userLink)}</a>}
        </div>
        {userLink.errors.length > 0 && (
          <div className="link-errors">{userLink.errors.join(", ")}</div>
        )}
      </div>
      {!isDragging && (
        <div className="buttons">
          <button type="button" onClick={handleEdit}>
            Edit
          </button>
          <button type="button" onClick={handleDelete}>
            Remove
          </button>
        </div>
      )}
    </div>
  );
}
