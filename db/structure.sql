SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: english_unaccent; Type: TEXT SEARCH CONFIGURATION; Schema: public; Owner: -
--

CREATE TEXT SEARCH CONFIGURATION public.english_unaccent (
    PARSER = pg_catalog."default" );

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR asciiword WITH english_stem;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR word WITH public.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR numword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR email WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR url WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR host WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR sfloat WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR version WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR hword_numpart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR hword_part WITH public.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR hword_asciipart WITH english_stem;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR numhword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR asciihword WITH english_stem;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR hword WITH public.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR url_path WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR file WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR "float" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR "int" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_unaccent
    ADD MAPPING FOR uint WITH simple;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: avatars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.avatars (
    id integer NOT NULL,
    content_hash character varying,
    content_type character varying,
    content_length integer,
    filename character varying,
    colorspace character varying,
    real_width integer,
    real_height integer,
    crop_width integer,
    crop_height integer,
    crop_start_x integer,
    crop_start_y integer,
    crop_gravity_x integer,
    crop_gravity_y integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: avatars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.avatars_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: avatars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.avatars_id_seq OWNED BY public.avatars.id;


--
-- Name: conversation_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_relationships (
    id integer NOT NULL,
    user_id integer,
    conversation_id integer,
    notifications boolean DEFAULT true NOT NULL,
    new_posts boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conversation_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_relationships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_relationships_id_seq OWNED BY public.conversation_relationships.id;


--
-- Name: discussion_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.discussion_relationships (
    id integer NOT NULL,
    user_id integer,
    discussion_id integer,
    participated boolean DEFAULT false NOT NULL,
    following boolean DEFAULT true NOT NULL,
    favorite boolean DEFAULT false NOT NULL,
    trusted boolean DEFAULT false NOT NULL,
    hidden boolean DEFAULT false NOT NULL
);


--
-- Name: discussion_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.discussion_relationships_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: discussion_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.discussion_relationships_id_seq OWNED BY public.discussion_relationships.id;


--
-- Name: dynamic_image_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dynamic_image_variants (
    id bigint NOT NULL,
    image_type character varying NOT NULL,
    image_id bigint NOT NULL,
    content_hash character varying NOT NULL,
    content_type character varying NOT NULL,
    content_length integer NOT NULL,
    filename character varying NOT NULL,
    format character varying NOT NULL,
    width integer NOT NULL,
    height integer NOT NULL,
    crop_width integer NOT NULL,
    crop_height integer NOT NULL,
    crop_start_x integer NOT NULL,
    crop_start_y integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: dynamic_image_variants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dynamic_image_variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dynamic_image_variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dynamic_image_variants_id_seq OWNED BY public.dynamic_image_variants.id;


--
-- Name: exchange_moderators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_moderators (
    id integer NOT NULL,
    exchange_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: exchange_moderators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exchange_moderators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exchange_moderators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exchange_moderators_id_seq OWNED BY public.exchange_moderators.id;


--
-- Name: exchange_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_views (
    id integer NOT NULL,
    user_id integer,
    exchange_id integer,
    post_id integer,
    post_index integer DEFAULT 0 NOT NULL
);


--
-- Name: exchange_views_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exchange_views_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exchange_views_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exchange_views_id_seq OWNED BY public.exchange_views.id;


--
-- Name: exchanges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchanges (
    id integer NOT NULL,
    title character varying,
    sticky boolean DEFAULT false NOT NULL,
    closed boolean DEFAULT false NOT NULL,
    nsfw boolean DEFAULT false NOT NULL,
    trusted boolean DEFAULT false NOT NULL,
    poster_id integer,
    last_poster_id integer,
    closer_id integer,
    posts_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_post_at timestamp without time zone,
    type character varying(100),
    tsv tsvector
);


--
-- Name: exchanges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exchanges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exchanges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exchanges_id_seq OWNED BY public.exchanges.id;


--
-- Name: invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invites (
    id integer NOT NULL,
    user_id integer,
    email public.citext,
    token character varying,
    message text,
    expires_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invites_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invites_id_seq OWNED BY public.invites.id;


--
-- Name: post_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_images (
    id integer NOT NULL,
    content_hash character varying,
    content_type character varying,
    content_length integer,
    filename character varying,
    colorspace character varying,
    real_width integer,
    real_height integer,
    crop_width integer,
    crop_height integer,
    crop_start_x integer,
    crop_start_y integer,
    crop_gravity_x integer,
    crop_gravity_y integer,
    original_url character varying(4096),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: post_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.post_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: post_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.post_images_id_seq OWNED BY public.post_images.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id integer NOT NULL,
    body text,
    body_html text,
    user_id integer,
    exchange_id integer,
    trusted boolean DEFAULT false NOT NULL,
    conversation boolean DEFAULT false NOT NULL,
    format character varying DEFAULT 'markdown'::character varying NOT NULL,
    edited_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    tsv tsvector,
    "position" integer
);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    name character varying,
    value jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: user_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_links (
    id bigint NOT NULL,
    user_id bigint,
    label character varying,
    name character varying,
    url text,
    "position" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_links_id_seq OWNED BY public.user_links.id;


--
-- Name: user_mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_mutes (
    id bigint NOT NULL,
    user_id bigint,
    muted_user_id bigint,
    exchange_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_mutes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_mutes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_mutes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_mutes_id_seq OWNED BY public.user_mutes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(100),
    realname character varying,
    email public.citext,
    password_digest character varying,
    location character varying,
    stylesheet_url character varying,
    description text,
    admin boolean DEFAULT false NOT NULL,
    trusted boolean DEFAULT false NOT NULL,
    user_admin boolean DEFAULT false NOT NULL,
    moderator boolean DEFAULT false NOT NULL,
    notify_on_message boolean DEFAULT true NOT NULL,
    last_active timestamp without time zone,
    birthday date,
    posts_count integer DEFAULT 0 NOT NULL,
    inviter_id integer,
    longitude double precision,
    latitude double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    available_invites integer DEFAULT 0 NOT NULL,
    participated_count integer DEFAULT 0 NOT NULL,
    favorites_count integer DEFAULT 0 NOT NULL,
    following_count integer DEFAULT 0 NOT NULL,
    time_zone character varying,
    banned_until timestamp without time zone,
    mobile_stylesheet_url character varying,
    theme character varying,
    mobile_theme character varying,
    persistence_token character varying,
    public_posts_count integer DEFAULT 0 NOT NULL,
    hidden_count integer DEFAULT 0 NOT NULL,
    preferred_format character varying,
    avatar_id integer,
    previous_usernames text,
    status integer DEFAULT 0 NOT NULL,
    pronouns character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: avatars id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avatars ALTER COLUMN id SET DEFAULT nextval('public.avatars_id_seq'::regclass);


--
-- Name: conversation_relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_relationships ALTER COLUMN id SET DEFAULT nextval('public.conversation_relationships_id_seq'::regclass);


--
-- Name: discussion_relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_relationships ALTER COLUMN id SET DEFAULT nextval('public.discussion_relationships_id_seq'::regclass);


--
-- Name: dynamic_image_variants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_image_variants ALTER COLUMN id SET DEFAULT nextval('public.dynamic_image_variants_id_seq'::regclass);


--
-- Name: exchange_moderators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_moderators ALTER COLUMN id SET DEFAULT nextval('public.exchange_moderators_id_seq'::regclass);


--
-- Name: exchange_views id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_views ALTER COLUMN id SET DEFAULT nextval('public.exchange_views_id_seq'::regclass);


--
-- Name: exchanges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchanges ALTER COLUMN id SET DEFAULT nextval('public.exchanges_id_seq'::regclass);


--
-- Name: invites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invites ALTER COLUMN id SET DEFAULT nextval('public.invites_id_seq'::regclass);


--
-- Name: post_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_images ALTER COLUMN id SET DEFAULT nextval('public.post_images_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: user_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_links ALTER COLUMN id SET DEFAULT nextval('public.user_links_id_seq'::regclass);


--
-- Name: user_mutes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mutes ALTER COLUMN id SET DEFAULT nextval('public.user_mutes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: avatars avatars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avatars
    ADD CONSTRAINT avatars_pkey PRIMARY KEY (id);


--
-- Name: conversation_relationships conversation_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_relationships
    ADD CONSTRAINT conversation_relationships_pkey PRIMARY KEY (id);


--
-- Name: discussion_relationships discussion_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.discussion_relationships
    ADD CONSTRAINT discussion_relationships_pkey PRIMARY KEY (id);


--
-- Name: dynamic_image_variants dynamic_image_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dynamic_image_variants
    ADD CONSTRAINT dynamic_image_variants_pkey PRIMARY KEY (id);


--
-- Name: exchange_moderators exchange_moderators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_moderators
    ADD CONSTRAINT exchange_moderators_pkey PRIMARY KEY (id);


--
-- Name: exchange_views exchange_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_views
    ADD CONSTRAINT exchange_views_pkey PRIMARY KEY (id);


--
-- Name: exchanges exchanges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchanges
    ADD CONSTRAINT exchanges_pkey PRIMARY KEY (id);


--
-- Name: invites invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: post_images post_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_images
    ADD CONSTRAINT post_images_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: user_links user_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_links
    ADD CONSTRAINT user_links_pkey PRIMARY KEY (id);


--
-- Name: user_mutes user_mutes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mutes
    ADD CONSTRAINT user_mutes_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: dynamic_image_variants_by_format_and_size; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dynamic_image_variants_by_format_and_size ON public.dynamic_image_variants USING btree (image_id, image_type, format, width, height, crop_width, crop_height, crop_start_x, crop_start_y);


--
-- Name: dynamic_image_variants_by_image; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX dynamic_image_variants_by_image ON public.dynamic_image_variants USING btree (image_id, image_type);


--
-- Name: index_conversation_relationships_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_relationships_on_conversation_id ON public.conversation_relationships USING btree (conversation_id);


--
-- Name: index_conversation_relationships_on_conversation_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_relationships_on_conversation_id_and_user_id ON public.conversation_relationships USING btree (conversation_id, user_id);


--
-- Name: index_conversation_relationships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_relationships_on_user_id ON public.conversation_relationships USING btree (user_id);


--
-- Name: index_discussion_relationships_on_discussion_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_discussion_id ON public.discussion_relationships USING btree (discussion_id);


--
-- Name: index_discussion_relationships_on_favorite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_favorite ON public.discussion_relationships USING btree (favorite);


--
-- Name: index_discussion_relationships_on_following; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_following ON public.discussion_relationships USING btree (following);


--
-- Name: index_discussion_relationships_on_hidden; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_hidden ON public.discussion_relationships USING btree (hidden);


--
-- Name: index_discussion_relationships_on_participated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_participated ON public.discussion_relationships USING btree (participated);


--
-- Name: index_discussion_relationships_on_trusted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_trusted ON public.discussion_relationships USING btree (trusted);


--
-- Name: index_discussion_relationships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_discussion_relationships_on_user_id ON public.discussion_relationships USING btree (user_id);


--
-- Name: index_dynamic_image_variants_on_image_type_and_image_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dynamic_image_variants_on_image_type_and_image_id ON public.dynamic_image_variants USING btree (image_type, image_id);


--
-- Name: index_exchange_moderators_on_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_moderators_on_exchange_id ON public.exchange_moderators USING btree (exchange_id);


--
-- Name: index_exchange_moderators_on_exchange_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_exchange_moderators_on_exchange_id_and_user_id ON public.exchange_moderators USING btree (exchange_id, user_id);


--
-- Name: index_exchange_moderators_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_moderators_on_user_id ON public.exchange_moderators USING btree (user_id);


--
-- Name: index_exchange_views_on_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_views_on_exchange_id ON public.exchange_views USING btree (exchange_id);


--
-- Name: index_exchange_views_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_views_on_post_id ON public.exchange_views USING btree (post_id);


--
-- Name: index_exchange_views_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_views_on_user_id ON public.exchange_views USING btree (user_id);


--
-- Name: index_exchange_views_on_user_id_and_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchange_views_on_user_id_and_exchange_id ON public.exchange_views USING btree (user_id, exchange_id);


--
-- Name: index_exchanges_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_created_at ON public.exchanges USING btree (created_at);


--
-- Name: index_exchanges_on_last_post_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_last_post_at ON public.exchanges USING btree (last_post_at);


--
-- Name: index_exchanges_on_poster_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_poster_id ON public.exchanges USING btree (poster_id);


--
-- Name: index_exchanges_on_sticky; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_sticky ON public.exchanges USING btree (sticky);


--
-- Name: index_exchanges_on_sticky_and_last_post_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_sticky_and_last_post_at ON public.exchanges USING btree (sticky, last_post_at);


--
-- Name: index_exchanges_on_trusted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_trusted ON public.exchanges USING btree (trusted);


--
-- Name: index_exchanges_on_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_tsv ON public.exchanges USING gin (tsv);


--
-- Name: index_exchanges_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exchanges_on_type ON public.exchanges USING btree (type);


--
-- Name: index_invites_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invites_on_email ON public.invites USING btree (email);


--
-- Name: index_post_images_on_id_and_content_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_post_images_on_id_and_content_hash ON public.post_images USING btree (id, content_hash);


--
-- Name: index_post_images_on_original_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_images_on_original_url ON public.post_images USING btree (original_url);


--
-- Name: index_posts_on_conversation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_conversation ON public.posts USING btree (conversation);


--
-- Name: index_posts_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_created_at ON public.posts USING btree (created_at);


--
-- Name: index_posts_on_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_deleted ON public.posts USING btree (deleted);


--
-- Name: index_posts_on_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_exchange_id ON public.posts USING btree (exchange_id);


--
-- Name: index_posts_on_exchange_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_exchange_id_and_created_at ON public.posts USING btree (exchange_id, created_at);


--
-- Name: index_posts_on_trusted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_trusted ON public.posts USING btree (trusted);


--
-- Name: index_posts_on_tsv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_tsv ON public.posts USING gin (tsv);


--
-- Name: index_posts_on_tsv_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_tsv_searchable ON public.posts USING gin (tsv) WHERE ((conversation = false) AND (deleted = false));


--
-- Name: index_posts_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id ON public.posts USING btree (user_id);


--
-- Name: index_posts_on_user_id_and_conversation; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id_and_conversation ON public.posts USING btree (user_id, conversation);


--
-- Name: index_posts_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_user_id_and_created_at ON public.posts USING btree (user_id, created_at);


--
-- Name: index_settings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_name ON public.settings USING btree (name);


--
-- Name: index_user_links_on_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_links_on_label ON public.user_links USING btree (label);


--
-- Name: index_user_links_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_links_on_user_id ON public.user_links USING btree (user_id);


--
-- Name: index_user_mutes_on_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_mutes_on_exchange_id ON public.user_mutes USING btree (exchange_id);


--
-- Name: index_user_mutes_on_muted_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_mutes_on_muted_user_id ON public.user_mutes USING btree (muted_user_id);


--
-- Name: index_user_mutes_on_muted_user_id_and_user_id_and_exchange_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_mutes_on_muted_user_id_and_user_id_and_exchange_id ON public.user_mutes USING btree (muted_user_id, user_id, exchange_id);


--
-- Name: index_user_mutes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_mutes_on_user_id ON public.user_mutes USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_last_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_last_active ON public.users USING btree (last_active);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: exchanges tsvectorupdate_exchanges; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvectorupdate_exchanges BEFORE INSERT OR UPDATE ON public.exchanges FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('tsv', 'public.english_unaccent', 'title');


--
-- Name: posts tsvectorupdate_posts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvectorupdate_posts BEFORE INSERT OR UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('tsv', 'public.english_unaccent', 'body');


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260523200000'),
('20260523170000'),
('20260514120000'),
('20260513213433'),
('20241117214337'),
('20241016075108'),
('20241016075107'),
('20241016075106'),
('20241016075105'),
('20241016075104'),
('20240204213226'),
('20240204213225'),
('20240203220916'),
('20240203204255'),
('20240131190941'),
('20230102115258'),
('20221227145750'),
('20221224122008'),
('20221219034728'),
('20221204150531'),
('20210511201335'),
('20210511201334'),
('20210511190938'),
('20200310231312'),
('20200106134349'),
('20191217150053'),
('20190626225031'),
('20190620160500'),
('20180529221615'),
('20180315195139'),
('20171025220509'),
('20170502045600'),
('20160810181227'),
('20160328211958'),
('20150731222329'),
('20141015220711'),
('20130401001644'),
('20121212191843'),
('20091205170938'),
('20090512185809'),
('20090429063818'),
('20090404154958'),
('20080701172614'),
('20080625202348'),
('20080625202342'),
('20080625185118');

