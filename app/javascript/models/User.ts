import B3S from "../b3s";

interface IUser {
  id: number;
  attributes: UserAttributes;
}

export default class User implements IUser {
  id: number;
  attributes: UserAttributes;

  constructor(attrs: UserAttributes) {
    this.id = attrs.id;
    this.attributes = attrs;
  }

  isAdmin = () => {
    return this.attributes.admin;
  };

  isModerator = () => {
    return this.attributes.moderator || this.isAdmin();
  };
}

export function currentUser() {
  if (B3S.Configuration.currentUser) {
    return new User(B3S.Configuration.currentUser);
  } else {
    return null;
  }
}
