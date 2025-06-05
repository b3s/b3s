import { startPosts } from "./b3s/post";

type Icon = {
  name: string;
  image: string;
};

type B3SConfiguration = {
  emoticons: Icon[];
  amazonAssociatesId?: string;
  currentUser?: UserAttributes;
  currentUserId?: number;
  preferredFormat?: string;
  uploads?: boolean;
};

const B3S = {
  Configuration: {} as B3SConfiguration,

  init() {
    startPosts();
  }
};

export default B3S;
