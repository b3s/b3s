import { useState, ChangeEvent } from "react";

import TypeaheadTextField from "../Input/TypeaheadTextField";
import { normalizeUrl, validUrl } from "./url";

interface EditorProps {
  dispatch: (action: UserLink.Action) => void;
  labels: string[];
  newLink: boolean;
  userLink: UserLink.Link;
}

function preventSubmit(evt: React.KeyboardEvent) {
  if (evt.key === "Enter") {
    evt.preventDefault();
  }
}

export default function Editor(props: EditorProps) {
  const { dispatch, newLink } = props;

  const [userLink, setUserLink] = useState(props.userLink);

  const updateAttribute = (attr: string) => (value: string) => {
    setUserLink({ ...userLink, [attr]: value });
  };

  const handleChange =
    (attr: string) => (evt: ChangeEvent<HTMLInputElement>) => {
      updateAttribute(attr)(evt.target.value);
    };

  const handleCancel = (evt: React.MouseEvent) => {
    evt.preventDefault();
    dispatch({ type: "cancel" });
  };

  const handleSave = (evt: React.MouseEvent) => {
    evt.preventDefault();
    dispatch({
      type: "save",
      payload: { ...userLink, url: normalizeUrl(userLink.url) }
    });
  };

  const validUserLink = () => {
    if (userLink.url.trim() && !validUrl(userLink.url)) {
      return false;
    }
    return userLink.label && (userLink.name || userLink.url);
  };

  return (
    <div className="editor">
      <TypeaheadTextField
        label="Label"
        name="label"
        autoFocus={true}
        onChange={updateAttribute("label")}
        onKeyDown={preventSubmit}
        options={props.labels}
        size={40}
        value={userLink.label}
      />
      <div className="field">
        <label htmlFor="name">
          Name
          <div className="description">
            E.g. Link text, username, code or similar
          </div>
        </label>
        <input
          type="text"
          name="name"
          size={50}
          onChange={handleChange("name")}
          onKeyDown={preventSubmit}
          value={userLink.name}
        />
      </div>
      <div className="field">
        <label htmlFor="url">URL</label>
        <input
          type="text"
          name="url"
          size={50}
          onChange={handleChange("url")}
          onKeyDown={preventSubmit}
          value={userLink.url}
        />
      </div>
      <div className="buttons">
        <button type="button" onClick={handleSave} disabled={!validUserLink()}>
          {newLink ? "Add" : "Update"}
        </button>
        <button type="button" onClick={handleCancel}>
          Cancel
        </button>
      </div>
    </div>
  );
}
