import { useState } from "react";

import TypeaheadTextField from "./Input/TypeaheadTextField";

interface Props {
  url: string;
}

export default function InviteParticipant(props: Props) {
  const { url } = props;

  const [loading, setLoading] = useState(false);
  const [username, setUsername] = useState("");
  const [users, setUsers] = useState<UserAttributes[]>([]);

  const loadUsernames = async () => {
    if (!loading) {
      setLoading(true);
      const response = await fetch("/users.json");
      setUsers((await response.json()) as UserAttributes[]);
    }
  };

  const usernames = users.map((u) => u.username);

  return (
    <div className="invite">
      <h2>Invite someone</h2>
      <form method="POST" action={url}>
        <TypeaheadTextField
          label="Username"
          name="username"
          onChange={setUsername}
          onFocus={loadUsernames}
          onKeyDown={loadUsernames}
          options={usernames}
          value={username}
        />
        <button type="submit">Invite</button>
      </form>
    </div>
  );
}
