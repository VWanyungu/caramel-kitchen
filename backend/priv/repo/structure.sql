--
-- PostgreSQL database dump
--

\restrict CrAQ9DbvmWmqBBj5rJYGhqFw7wug2ZGmRnOSRDWnp6na6lwsv0KY52Ys0A8fAWu

-- Dumped from database version 14.23 (Ubuntu 14.23-1.pgdg22.04+1)
-- Dumped by pg_dump version 18.4 (Ubuntu 18.4-1.pgdg22.04+1)

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
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: ai_query_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ai_query_type AS ENUM (
    'chat',
    'voice',
    'meal_plan',
    'suggestion'
);


--
-- Name: cooking_method; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.cooking_method AS ENUM (
    'boiling',
    'frying',
    'roasting',
    'grilling',
    'baking',
    'steaming',
    'braising',
    'slow_cooking',
    'pressure_cooking',
    'air_frying',
    'raw',
    'fermented',
    'sauteing',
    'smoking',
    'chilling',
    'blanching',
    'stir_frying',
    'poaching'
);


--
-- Name: course_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.course_type AS ENUM (
    'pre_starter',
    'starter',
    'soup',
    'salad',
    'main',
    'dessert',
    'after_meal'
);


--
-- Name: difficulty_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.difficulty_level AS ENUM (
    'beginner',
    'intermediate',
    'advanced'
);


--
-- Name: dish_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.dish_category AS ENUM (
    'egg_dishes',
    'rice_dishes',
    'soups_stews',
    'meat_dishes',
    'fish_seafood',
    'salads',
    'pasta_noodles',
    'breakfast',
    'baked_goods',
    'drinks_juices',
    'snacks',
    'vegetarian'
);


--
-- Name: goal_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.goal_type AS ENUM (
    'gym_muscle',
    'weight_loss',
    'weight_gain',
    'balanced',
    'keto'
);


--
-- Name: interaction_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.interaction_action AS ENUM (
    'saved',
    'cooked',
    'skipped',
    'rated',
    'viewed'
);


--
-- Name: oban_job_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.oban_job_state AS ENUM (
    'available',
    'suspended',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded',
    'cancelled'
);


--
-- Name: recipe_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.recipe_status AS ENUM (
    'draft',
    'scheduled',
    'live',
    'archived'
);


--
-- Name: subscription_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_status AS ENUM (
    'active',
    'past_due',
    'canceled',
    'trialing',
    'incomplete'
);


--
-- Name: subscription_tier; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.subscription_tier AS ENUM (
    'free',
    'premium',
    'creator_pro'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'user',
    'creator',
    'admin'
);


--
-- Name: recipes_search_vector_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.recipes_search_vector_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', array_to_string(NEW.taste_tags, ' ')), 'C') ||
    setweight(to_tsvector('english', array_to_string(NEW.dietary_flags, ' ')), 'C');
  RETURN NEW;
END
$$;


--
-- Name: update_recipe_computed_fields(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_recipe_computed_fields() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.total_time_mins := NEW.prep_time_mins + NEW.cook_time_mins;
  NEW.engagement_score :=
    (NEW.view_count * 0.1 + NEW.save_count * 0.4 + NEW.cook_count * 0.5 + NEW.avg_rating * 5.0) /
    GREATEST(1, (EXTRACT(EPOCH FROM (NOW() - NEW.published_at)) / 86400.0));
  RETURN NEW;
END
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_queries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_queries (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    session_id character varying(255),
    query_type public.ai_query_type,
    prompt text,
    response text,
    model character varying(255) DEFAULT 'gpt-4o'::character varying,
    tokens_used integer,
    latency_ms integer,
    recipe_ids uuid[] DEFAULT ARRAY[]::uuid[],
    error character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: event_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_menus (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    name character varying(150) NOT NULL,
    courses jsonb DEFAULT '{}'::jsonb,
    notes text,
    event_date date,
    guest_count integer DEFAULT 4,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: guardian_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.guardian_tokens (
    jti character varying(255) NOT NULL,
    aud character varying(255) NOT NULL,
    typ character varying(255),
    iss character varying(255),
    sub character varying(255),
    exp bigint,
    jwt text,
    claims jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: meal_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meal_plans (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    goal_type public.goal_type NOT NULL,
    name character varying(100),
    week_start date NOT NULL,
    week_end date NOT NULL,
    calorie_target integer,
    macro_split jsonb DEFAULT '{}'::jsonb,
    days jsonb[] DEFAULT ARRAY[]::jsonb[],
    is_ai_generated boolean DEFAULT true,
    ai_model character varying(255),
    is_active boolean DEFAULT true,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: oban_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oban_jobs (
    id bigint NOT NULL,
    state public.oban_job_state DEFAULT 'available'::public.oban_job_state NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    worker text NOT NULL,
    args jsonb DEFAULT '{}'::jsonb NOT NULL,
    errors jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    attempt integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 20 NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    scheduled_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    attempted_by text[],
    discarded_at timestamp without time zone,
    priority integer DEFAULT 0 NOT NULL,
    tags text[] DEFAULT ARRAY[]::text[],
    meta jsonb DEFAULT '{}'::jsonb,
    cancelled_at timestamp without time zone,
    CONSTRAINT attempt_range CHECK (((attempt >= 0) AND (attempt <= max_attempts))),
    CONSTRAINT positive_max_attempts CHECK ((max_attempts > 0)),
    CONSTRAINT queue_length CHECK (((char_length(queue) > 0) AND (char_length(queue) < 128))),
    CONSTRAINT worker_length CHECK (((char_length(worker) > 0) AND (char_length(worker) < 128)))
);


--
-- Name: TABLE oban_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.oban_jobs IS '14';


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oban_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oban_jobs_id_seq OWNED BY public.oban_jobs.id;


--
-- Name: oban_peers; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.oban_peers (
    name text NOT NULL,
    node text NOT NULL,
    started_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    creator_id uuid NOT NULL,
    slug character varying(200) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    ingredients jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    steps jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    serving_size integer DEFAULT 2 NOT NULL,
    thumbnail_url character varying(255),
    video_url character varying(255),
    video_key character varying(255),
    video_duration_secs integer,
    dish_category public.dish_category,
    course public.course_type,
    primary_method public.cooking_method,
    secondary_method public.cooking_method,
    difficulty public.difficulty_level DEFAULT 'beginner'::public.difficulty_level,
    cuisine_origin character varying(255)[] DEFAULT ARRAY[]::character varying[],
    prep_time_mins integer DEFAULT 0,
    cook_time_mins integer DEFAULT 0,
    total_time_mins integer DEFAULT 0,
    taste_tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    taste_profile public.vector(8),
    dietary_flags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    allergens character varying(255)[] DEFAULT ARRAY[]::character varying[],
    calories integer,
    macros jsonb DEFAULT '{}'::jsonb,
    view_count integer DEFAULT 0,
    save_count integer DEFAULT 0,
    cook_count integer DEFAULT 0,
    avg_rating numeric(3,2) DEFAULT 0,
    rating_count integer DEFAULT 0,
    engagement_score double precision DEFAULT 0.0,
    status public.recipe_status DEFAULT 'draft'::public.recipe_status NOT NULL,
    published_at timestamp(0) without time zone,
    scheduled_at timestamp(0) without time zone,
    featured_until timestamp(0) without time zone,
    search_vector tsvector,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: shopping_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shopping_lists (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    meal_plan_id uuid,
    event_menu_id uuid,
    name character varying(100),
    items jsonb[] DEFAULT ARRAY[]::jsonb[],
    checked_ids uuid[] DEFAULT ARRAY[]::uuid[],
    share_token character varying(255),
    servings_multiplier double precision DEFAULT 1.0,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    stripe_customer_id character varying(255),
    stripe_sub_id character varying(255),
    plan public.subscription_tier DEFAULT 'free'::public.subscription_tier NOT NULL,
    status public.subscription_status DEFAULT 'active'::public.subscription_status,
    trial_ends_at timestamp(0) without time zone,
    current_period_start timestamp(0) without time zone,
    current_period_end timestamp(0) without time zone,
    canceled_at timestamp(0) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: user_push_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_push_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token character varying(512) NOT NULL,
    platform character varying(255) NOT NULL,
    device_name character varying(255),
    active boolean DEFAULT true,
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: user_recipe_interactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_recipe_interactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    recipe_id uuid NOT NULL,
    action public.interaction_action NOT NULL,
    rating integer,
    taste_feedback jsonb DEFAULT '{}'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(100) NOT NULL,
    avatar_url character varying(255),
    role public.user_role DEFAULT 'user'::public.user_role NOT NULL,
    subscription_tier public.subscription_tier DEFAULT 'free'::public.subscription_tier NOT NULL,
    taste_vector public.vector(8),
    taste_survey_done boolean DEFAULT false NOT NULL,
    taste_updated_at timestamp(0) without time zone,
    dietary_flags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    allergy_flags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    cuisine_preferences character varying(255)[] DEFAULT ARRAY[]::character varying[],
    goal_type character varying(255),
    google_uid character varying(255),
    email_verified boolean DEFAULT false NOT NULL,
    email_verify_token character varying(255),
    password_reset_token character varying(255),
    password_reset_at timestamp(0) without time zone,
    last_sign_in_at timestamp(0) without time zone,
    sign_in_count integer DEFAULT 0,
    deactivated_at timestamp(0) without time zone,
    deactivation_reason character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: oban_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs ALTER COLUMN id SET DEFAULT nextval('public.oban_jobs_id_seq'::regclass);


--
-- Name: ai_queries ai_queries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_queries
    ADD CONSTRAINT ai_queries_pkey PRIMARY KEY (id);


--
-- Name: event_menus event_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_menus
    ADD CONSTRAINT event_menus_pkey PRIMARY KEY (id);


--
-- Name: guardian_tokens guardian_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.guardian_tokens
    ADD CONSTRAINT guardian_tokens_pkey PRIMARY KEY (jti);


--
-- Name: meal_plans meal_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meal_plans
    ADD CONSTRAINT meal_plans_pkey PRIMARY KEY (id);


--
-- Name: oban_jobs non_negative_priority; Type: CHECK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.oban_jobs
    ADD CONSTRAINT non_negative_priority CHECK ((priority >= 0)) NOT VALID;


--
-- Name: oban_jobs oban_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs
    ADD CONSTRAINT oban_jobs_pkey PRIMARY KEY (id);


--
-- Name: oban_peers oban_peers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_peers
    ADD CONSTRAINT oban_peers_pkey PRIMARY KEY (name);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shopping_lists shopping_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_lists
    ADD CONSTRAINT shopping_lists_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: user_push_tokens user_push_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_push_tokens
    ADD CONSTRAINT user_push_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_recipe_interactions user_recipe_interactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_recipe_interactions
    ADD CONSTRAINT user_recipe_interactions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ai_queries_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ai_queries_inserted_at_index ON public.ai_queries USING btree (inserted_at);


--
-- Name: ai_queries_query_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ai_queries_query_type_index ON public.ai_queries USING btree (query_type);


--
-- Name: ai_queries_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ai_queries_user_id_index ON public.ai_queries USING btree (user_id);


--
-- Name: ai_queries_user_id_inserted_at_query_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ai_queries_user_id_inserted_at_query_type_index ON public.ai_queries USING btree (user_id, inserted_at, query_type);


--
-- Name: event_menus_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_menus_user_id_index ON public.event_menus USING btree (user_id);


--
-- Name: guardian_tokens_aud_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX guardian_tokens_aud_index ON public.guardian_tokens USING btree (aud);


--
-- Name: guardian_tokens_jti_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX guardian_tokens_jti_index ON public.guardian_tokens USING btree (jti);


--
-- Name: meal_plans_active_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meal_plans_active_user_idx ON public.meal_plans USING btree (user_id, inserted_at DESC) WHERE (is_active = true);


--
-- Name: meal_plans_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meal_plans_user_id_index ON public.meal_plans USING btree (user_id);


--
-- Name: meal_plans_user_id_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meal_plans_user_id_is_active_index ON public.meal_plans USING btree (user_id, is_active);


--
-- Name: meal_plans_week_start_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meal_plans_week_start_index ON public.meal_plans USING btree (week_start);


--
-- Name: oban_jobs_args_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_args_index ON public.oban_jobs USING gin (args);


--
-- Name: oban_jobs_meta_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_meta_index ON public.oban_jobs USING gin (meta);


--
-- Name: oban_jobs_state_cancelled_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_state_cancelled_at_index ON public.oban_jobs USING btree (state, cancelled_at);


--
-- Name: oban_jobs_state_discarded_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_state_discarded_at_index ON public.oban_jobs USING btree (state, discarded_at);


--
-- Name: oban_jobs_state_queue_priority_scheduled_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_state_queue_priority_scheduled_at_id_index ON public.oban_jobs USING btree (state, queue, priority, scheduled_at, id);


--
-- Name: recipes_allergens_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_allergens_index ON public.recipes USING gin (allergens);


--
-- Name: recipes_course_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_course_index ON public.recipes USING btree (course);


--
-- Name: recipes_creator_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_creator_id_index ON public.recipes USING btree (creator_id);


--
-- Name: recipes_creator_id_status_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_creator_id_status_inserted_at_index ON public.recipes USING btree (creator_id, status, inserted_at);


--
-- Name: recipes_cuisine_origin_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_cuisine_origin_index ON public.recipes USING gin (cuisine_origin);


--
-- Name: recipes_dietary_flags_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_dietary_flags_index ON public.recipes USING gin (dietary_flags);


--
-- Name: recipes_dish_category_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_dish_category_index ON public.recipes USING btree (dish_category);


--
-- Name: recipes_engagement_score_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_engagement_score_index ON public.recipes USING btree (engagement_score);


--
-- Name: recipes_live_engagement_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_live_engagement_idx ON public.recipes USING btree (engagement_score DESC, published_at DESC) WHERE (status = 'live'::public.recipe_status);


--
-- Name: recipes_primary_method_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_primary_method_index ON public.recipes USING btree (primary_method);


--
-- Name: recipes_published_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_published_at_index ON public.recipes USING btree (published_at);


--
-- Name: recipes_scheduled_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_scheduled_idx ON public.recipes USING btree (scheduled_at) WHERE ((status = 'scheduled'::public.recipe_status) AND (scheduled_at IS NOT NULL));


--
-- Name: recipes_search_vector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_search_vector_idx ON public.recipes USING gin (search_vector);


--
-- Name: recipes_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX recipes_slug_index ON public.recipes USING btree (slug);


--
-- Name: recipes_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_status_index ON public.recipes USING btree (status);


--
-- Name: recipes_taste_profile_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_taste_profile_hnsw_idx ON public.recipes USING hnsw (taste_profile public.vector_cosine_ops) WITH (m='16', ef_construction='64');


--
-- Name: recipes_taste_tags_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipes_taste_tags_index ON public.recipes USING gin (taste_tags);


--
-- Name: shopping_lists_share_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX shopping_lists_share_token_index ON public.shopping_lists USING btree (share_token) WHERE (share_token IS NOT NULL);


--
-- Name: shopping_lists_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX shopping_lists_user_id_index ON public.shopping_lists USING btree (user_id);


--
-- Name: subscriptions_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_status_index ON public.subscriptions USING btree (status);


--
-- Name: subscriptions_stripe_customer_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX subscriptions_stripe_customer_id_index ON public.subscriptions USING btree (stripe_customer_id);


--
-- Name: subscriptions_stripe_sub_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscriptions_stripe_sub_id_index ON public.subscriptions USING btree (stripe_sub_id) WHERE (stripe_sub_id IS NOT NULL);


--
-- Name: subscriptions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX subscriptions_user_id_index ON public.subscriptions USING btree (user_id);


--
-- Name: user_push_tokens_platform_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_push_tokens_platform_index ON public.user_push_tokens USING btree (platform);


--
-- Name: user_push_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_push_tokens_user_id_index ON public.user_push_tokens USING btree (user_id);


--
-- Name: user_push_tokens_user_id_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_push_tokens_user_id_token_index ON public.user_push_tokens USING btree (user_id, token);


--
-- Name: user_recipe_interactions_inserted_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_recipe_interactions_inserted_at_index ON public.user_recipe_interactions USING btree (inserted_at);


--
-- Name: user_recipe_interactions_recipe_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_recipe_interactions_recipe_id_index ON public.user_recipe_interactions USING btree (recipe_id);


--
-- Name: user_recipe_interactions_user_id_action_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_recipe_interactions_user_id_action_index ON public.user_recipe_interactions USING btree (user_id, action);


--
-- Name: user_recipe_interactions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_recipe_interactions_user_id_index ON public.user_recipe_interactions USING btree (user_id);


--
-- Name: user_recipe_interactions_user_id_recipe_id_action_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_recipe_interactions_user_id_recipe_id_action_index ON public.user_recipe_interactions USING btree (user_id, recipe_id, action);


--
-- Name: users_dietary_flags_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_dietary_flags_index ON public.users USING gin (dietary_flags);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_google_uid_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_google_uid_index ON public.users USING btree (google_uid) WHERE (google_uid IS NOT NULL);


--
-- Name: users_role_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_role_index ON public.users USING btree (role);


--
-- Name: users_subscription_tier_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_subscription_tier_index ON public.users USING btree (subscription_tier);


--
-- Name: users_taste_vector_hnsw_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_taste_vector_hnsw_idx ON public.users USING hnsw (taste_vector public.vector_cosine_ops) WITH (m='16', ef_construction='64');


--
-- Name: recipes recipe_computed_fields_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recipe_computed_fields_trigger BEFORE INSERT OR UPDATE ON public.recipes FOR EACH ROW EXECUTE FUNCTION public.update_recipe_computed_fields();


--
-- Name: recipes recipes_search_vector_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recipes_search_vector_trigger BEFORE INSERT OR UPDATE ON public.recipes FOR EACH ROW EXECUTE FUNCTION public.recipes_search_vector_update();


--
-- Name: ai_queries ai_queries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_queries
    ADD CONSTRAINT ai_queries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: event_menus event_menus_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_menus
    ADD CONSTRAINT event_menus_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: meal_plans meal_plans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meal_plans
    ADD CONSTRAINT meal_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: recipes recipes_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: shopping_lists shopping_lists_meal_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_lists
    ADD CONSTRAINT shopping_lists_meal_plan_id_fkey FOREIGN KEY (meal_plan_id) REFERENCES public.meal_plans(id) ON DELETE SET NULL;


--
-- Name: shopping_lists shopping_lists_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_lists
    ADD CONSTRAINT shopping_lists_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_push_tokens user_push_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_push_tokens
    ADD CONSTRAINT user_push_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_recipe_interactions user_recipe_interactions_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_recipe_interactions
    ADD CONSTRAINT user_recipe_interactions_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: user_recipe_interactions user_recipe_interactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_recipe_interactions
    ADD CONSTRAINT user_recipe_interactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict CrAQ9DbvmWmqBBj5rJYGhqFw7wug2ZGmRnOSRDWnp6na6lwsv0KY52Ys0A8fAWu

INSERT INTO public."schema_migrations" (version) VALUES (20240101000001);
INSERT INTO public."schema_migrations" (version) VALUES (20240101000002);
INSERT INTO public."schema_migrations" (version) VALUES (20240101000003);
INSERT INTO public."schema_migrations" (version) VALUES (20240101000004);
INSERT INTO public."schema_migrations" (version) VALUES (20240101000005);
INSERT INTO public."schema_migrations" (version) VALUES (20240101000006);
INSERT INTO public."schema_migrations" (version) VALUES (20260716051603);
INSERT INTO public."schema_migrations" (version) VALUES (20260717000000);
