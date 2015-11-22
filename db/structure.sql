--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: add_fast_forward_ancestors_to_branches_commits(uuid, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION add_fast_forward_ancestors_to_branches_commits(branch_id uuid, commit_id character varying) RETURNS void
    LANGUAGE sql
    AS $$
      INSERT INTO branches_commits (branch_id,commit_id)
        SELECT * FROM fast_forward_ancestors_to_be_added_to_branches_commits(branch_id,commit_id)
      $$;


--
-- Name: fast_forward_ancestors_to_be_added_to_branches_commits(uuid, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION fast_forward_ancestors_to_be_added_to_branches_commits(branch_id uuid, commit_id character varying) RETURNS TABLE(branch_id uuid, commit_id character varying)
    LANGUAGE sql
    AS $_$
        WITH RECURSIVE arcs(parent_id,child_id) AS
          (SELECT $2::varchar, NULL::varchar
            UNION
           SELECT commit_arcs.* FROM commit_arcs, arcs 
            WHERE arcs.parent_id = commit_arcs.child_id
            AND NOT EXISTS (SELECT 1 FROM branches_commits WHERE commit_id = arcs.parent_id AND branch_id = $1)
          )
        SELECT DISTINCT $1, parent_id FROM arcs
        WHERE NOT EXISTS (SELECT * FROM branches_commits WHERE commit_id = parent_id AND branch_id = $1)
      $_$;


--
-- Name: is_ancestor(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_ancestor(node character varying, possible_ancestor character varying) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT ( EXISTS (SELECT * FROM with_ancestors(node) WHERE ancestor_id = possible_ancestor)
                  AND $1 <> $2 )
      $_$;


--
-- Name: is_descendant(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_descendant(node character varying, possible_descendant character varying) RETURNS boolean
    LANGUAGE sql
    AS $_$
        SELECT ( EXISTS (SELECT * FROM with_descendants(node) WHERE descendant_id = possible_descendant)
                  AND $1 <> $2 )
      $_$;


--
-- Name: update_branches_commits(uuid, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_branches_commits(branch_id uuid, new_commit_id character varying, old_commit_id character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
      BEGIN
        CASE 
        WHEN (branch_id IS NULL) THEN 
          RAISE 'branch_id may not be null';
        WHEN NOT EXISTS (SELECT * FROM branches WHERE id = branch_id) THEN 
          RAISE 'branch_id must refer to an existing branch';
        WHEN new_commit_id IS NULL THEN
          RAISE 'new_commit_id may not be null';
        WHEN NOT EXISTS (SELECT * FROM commits WHERE id = new_commit_id) THEN
          RAISE 'new_commit_id must refer to an existing commit';
        WHEN old_commit_id IS NULL THEN 
          -- entirely new branch (nothing should be in branches_commits)
          -- or request a complete reset by setting old_commit_id to NULL 
          DELETE FROM branches_commits WHERE branches_commits.branch_id = $1;
        WHEN NOT is_ancestor(new_commit_id,old_commit_id) THEN
          -- this is the hard non fast forward case
          -- remove all ancestors of old_commit_id which are not ancestors of new_commit_id
          DELETE FROM branches_commits 
            WHERE branches_commits.branch_id = $1 
            AND branches_commits.commit_id IN ( SELECT * FROM with_ancestors(old_commit_id) 
                                EXCEPT SELECT * from with_ancestors(new_commit_id) );
        ELSE 
          -- this is the fast forward case; see last statement
        END CASE;
        -- whats left is adding as if we are in the fast forward case
        PERFORM add_fast_forward_ancestors_to_branches_commits(branch_id,new_commit_id);
        RETURN 'done';
      END;
      $_$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
             NEW.updated_at = now(); 
             RETURN NEW;
          END;
          $$;


--
-- Name: with_ancestors(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION with_ancestors(character varying) RETURNS TABLE(ancestor_id character varying)
    LANGUAGE sql
    AS $_$
      WITH RECURSIVE arcs(parent_id,child_id) AS
        (SELECT $1::varchar, NULL::varchar
          UNION
         SELECT commit_arcs.* FROM commit_arcs, arcs WHERE arcs.parent_id = commit_arcs.child_id
        )
      SELECT parent_id FROM arcs
      $_$;


--
-- Name: with_descendants(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION with_descendants(character varying) RETURNS TABLE(descendant_id character varying)
    LANGUAGE sql
    AS $_$
      WITH RECURSIVE arcs(parent_id,child_id) AS
        (SELECT NULL::varchar, $1::varchar
          UNION
         SELECT commit_arcs.* FROM commit_arcs, arcs WHERE arcs.child_id = commit_arcs.parent_id
        )
      SELECT child_id FROM arcs
      $_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: branches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE branches (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    repository_id uuid NOT NULL,
    name character varying NOT NULL,
    current_commit_id character varying(40) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: branches_commits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE branches_commits (
    branch_id uuid NOT NULL,
    commit_id character varying(40) NOT NULL
);


--
-- Name: commit_arcs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commit_arcs (
    parent_id character varying(40) NOT NULL,
    child_id character varying(40) NOT NULL
);


--
-- Name: commits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE commits (
    id character varying(40) NOT NULL,
    tree_id character varying(40),
    depth integer,
    author_name character varying,
    author_email character varying,
    author_date timestamp without time zone,
    committer_name character varying,
    committer_email character varying,
    committer_date timestamp without time zone,
    subject text,
    body text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE jobs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    description text,
    result jsonb,
    tree_id character varying(40) NOT NULL,
    job_specification_id uuid NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by uuid,
    aborted_by uuid,
    aborted_at timestamp without time zone,
    resumed_by uuid,
    resumed_at timestamp without time zone,
    CONSTRAINT check_jobs_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'aborting'::character varying, 'pending'::character varying, 'executing'::character varying, 'passed'::character varying])::text[])))
);


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE repositories (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    git_url text NOT NULL,
    name character varying,
    git_fetch_and_update_interval integer DEFAULT 60,
    public_view_permission boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    update_notification_token uuid DEFAULT uuid_generate_v4(),
    github_authtoken text,
    use_default_github_authtoken boolean DEFAULT false NOT NULL
);


--
-- Name: commit_cache_signatures; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW commit_cache_signatures AS
 SELECT commits.id AS commit_id,
    md5(string_agg(DISTINCT (branches.updated_at)::text, ', '::text ORDER BY (branches.updated_at)::text)) AS branches_signature,
    md5(string_agg(DISTINCT (repositories.updated_at)::text, ', '::text ORDER BY (repositories.updated_at)::text)) AS repositories_signature,
    md5(string_agg(DISTINCT (jobs.updated_at)::text, ', '::text ORDER BY (jobs.updated_at)::text)) AS jobs_signature
   FROM ((((commits
     LEFT JOIN branches_commits ON (((branches_commits.commit_id)::text = (commits.id)::text)))
     LEFT JOIN branches ON ((branches_commits.branch_id = branches.id)))
     LEFT JOIN jobs ON (((jobs.tree_id)::text = (commits.tree_id)::text)))
     LEFT JOIN repositories ON ((branches.repository_id = repositories.id)))
  GROUP BY commits.id;


--
-- Name: email_addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_addresses (
    user_id uuid,
    email_address character varying NOT NULL,
    "primary" boolean DEFAULT false NOT NULL
);


--
-- Name: executors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE executors (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    max_load integer DEFAULT 1 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    traits character varying[] DEFAULT '{}'::character varying[],
    base_url text,
    last_ping_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    accepted_repositories character varying[] DEFAULT '{}'::character varying[],
    CONSTRAINT executors_name_constraints CHECK (((name)::text ~* '^[A-Za-z0-9\-\_]+$'::text))
);


--
-- Name: executors_with_load; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE executors_with_load (
    id uuid,
    name character varying,
    max_load integer,
    enabled boolean,
    traits character varying[],
    base_url text,
    last_ping_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    accepted_repositories character varying[],
    current_load bigint,
    relative_load double precision
);

ALTER TABLE ONLY executors_with_load REPLICA IDENTITY NOTHING;


--
-- Name: job_cache_signatures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE job_cache_signatures (
    job_id uuid,
    branches_signature text,
    commits_signature text,
    job_issues_signature text,
    job_issues_count bigint,
    repositories_signature text,
    tasks_signature text,
    tree_attachments_count bigint
);

ALTER TABLE ONLY job_cache_signatures REPLICA IDENTITY NOTHING;


--
-- Name: job_issues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE job_issues (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    title text,
    description text,
    type character varying DEFAULT 'error'::character varying NOT NULL,
    job_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: job_specifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE job_specifications (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    data jsonb
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tasks (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    job_id uuid NOT NULL,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    name text NOT NULL,
    result jsonb,
    task_specification_id uuid NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    traits character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    exclusive_global_resources character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    entity_errors jsonb DEFAULT '[]'::jsonb,
    CONSTRAINT check_tasks_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'aborting'::character varying, 'pending'::character varying, 'executing'::character varying, 'passed'::character varying])::text[])))
);


--
-- Name: job_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW job_stats AS
 SELECT jobs.id AS job_id,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE (tasks.job_id = jobs.id)) AS total,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.job_id = jobs.id) AND ((tasks.state)::text = 'failed'::text))) AS failed,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.job_id = jobs.id) AND ((tasks.state)::text = 'aborted'::text))) AS aborted,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.job_id = jobs.id) AND ((tasks.state)::text = 'aborting'::text))) AS aborting,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.job_id = jobs.id) AND ((tasks.state)::text = 'pending'::text))) AS pending,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.job_id = jobs.id) AND ((tasks.state)::text = 'executing'::text))) AS executing,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.job_id = jobs.id) AND ((tasks.state)::text = 'passed'::text))) AS passed
   FROM jobs;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: scripts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE scripts (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    trial_id uuid NOT NULL,
    key character varying NOT NULL,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    name character varying NOT NULL,
    stdout character varying(10485760) DEFAULT ''::character varying NOT NULL,
    stderr character varying(10485760) DEFAULT ''::character varying NOT NULL,
    body character varying(10240) DEFAULT ''::character varying NOT NULL,
    error character varying(1048576),
    timeout character varying,
    exclusive_executor_resource character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    start_when jsonb DEFAULT '[]'::jsonb NOT NULL,
    terminate_when jsonb DEFAULT '[]'::jsonb NOT NULL,
    environment_variables jsonb DEFAULT '{}'::jsonb NOT NULL,
    ignore_abort boolean DEFAULT false NOT NULL,
    ignore_state boolean DEFAULT false NOT NULL,
    template_environment_variables boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    exit_status integer,
    CONSTRAINT check_trials_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'pending'::character varying, 'executing'::character varying, 'skipped'::character varying, 'passed'::character varying, 'waiting'::character varying])::text[])))
);


--
-- Name: submodules; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE submodules (
    submodule_commit_id character varying NOT NULL,
    path text NOT NULL,
    commit_id character varying NOT NULL
);


--
-- Name: task_specifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE task_specifications (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    data jsonb
);


--
-- Name: tree_attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tree_attachments (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    path text NOT NULL,
    content_length text,
    content_type text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tree_id text NOT NULL,
    CONSTRAINT check_tree_id CHECK ((length(tree_id) = 40))
);


--
-- Name: trial_attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trial_attachments (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    path text NOT NULL,
    content_length text,
    content_type text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    trial_id uuid NOT NULL
);


--
-- Name: trial_issues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trial_issues (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    title text,
    description text,
    type character varying DEFAULT 'error'::character varying NOT NULL,
    trial_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: trials; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trials (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    task_id uuid NOT NULL,
    executor_id uuid,
    error text,
    state character varying DEFAULT 'pending'::character varying NOT NULL,
    result jsonb,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_by uuid,
    aborted_by uuid,
    aborted_at timestamp without time zone,
    CONSTRAINT check_trials_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'aborting'::character varying, 'pending'::character varying, 'dispatching'::character varying, 'executing'::character varying, 'passed'::character varying])::text[])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    password_digest character varying,
    login character varying NOT NULL,
    last_name character varying DEFAULT ''::character varying NOT NULL,
    first_name character varying DEFAULT ''::character varying NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    workspace_filters jsonb
);


--
-- Name: welcome_page_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE welcome_page_settings (
    id integer NOT NULL,
    welcome_message text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_and_only_one CHECK ((id = 0))
);


--
-- Name: branches_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY branches_commits
    ADD CONSTRAINT branches_commits_pkey PRIMARY KEY (commit_id, branch_id);


--
-- Name: branches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);


--
-- Name: commits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY commits
    ADD CONSTRAINT commits_pkey PRIMARY KEY (id);


--
-- Name: email_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_addresses
    ADD CONSTRAINT email_addresses_pkey PRIMARY KEY (email_address);


--
-- Name: executors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY executors
    ADD CONSTRAINT executors_pkey PRIMARY KEY (id);


--
-- Name: job_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_issues
    ADD CONSTRAINT job_issues_pkey PRIMARY KEY (id);


--
-- Name: job_specifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_specifications
    ADD CONSTRAINT job_specifications_pkey PRIMARY KEY (id);


--
-- Name: jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY scripts
    ADD CONSTRAINT scripts_pkey PRIMARY KEY (id);


--
-- Name: submodules_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submodules
    ADD CONSTRAINT submodules_pkey PRIMARY KEY (commit_id, path);


--
-- Name: task_specifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY task_specifications
    ADD CONSTRAINT task_specifications_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: tree_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tree_attachments
    ADD CONSTRAINT tree_attachments_pkey PRIMARY KEY (id);


--
-- Name: trial_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trial_attachments
    ADD CONSTRAINT trial_attachments_pkey PRIMARY KEY (id);


--
-- Name: trial_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trial_issues
    ADD CONSTRAINT trial_issues_pkey PRIMARY KEY (id);


--
-- Name: trials_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: welcome_page_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY welcome_page_settings
    ADD CONSTRAINT welcome_page_settings_pkey PRIMARY KEY (id);


--
-- Name: branches_lower_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX branches_lower_name_idx ON branches USING btree (lower((name)::text));


--
-- Name: commits_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx ON commits USING gin (to_tsvector('english'::regconfig, body));


--
-- Name: commits_to_tsvector_idx1; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx1 ON commits USING gin (to_tsvector('english'::regconfig, (author_name)::text));


--
-- Name: commits_to_tsvector_idx2; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx2 ON commits USING gin (to_tsvector('english'::regconfig, (author_email)::text));


--
-- Name: commits_to_tsvector_idx3; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx3 ON commits USING gin (to_tsvector('english'::regconfig, (committer_name)::text));


--
-- Name: commits_to_tsvector_idx4; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx4 ON commits USING gin (to_tsvector('english'::regconfig, (committer_email)::text));


--
-- Name: commits_to_tsvector_idx5; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx5 ON commits USING gin (to_tsvector('english'::regconfig, subject));


--
-- Name: commits_to_tsvector_idx6; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX commits_to_tsvector_idx6 ON commits USING gin (to_tsvector('english'::regconfig, body));


--
-- Name: idx_jobs_tree-id_job-specification-id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "idx_jobs_tree-id_job-specification-id" ON jobs USING btree (tree_id, job_specification_id);


--
-- Name: idx_jobs_tree-id_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "idx_jobs_tree-id_key" ON jobs USING btree (tree_id, key);


--
-- Name: idx_jobs_tree-id_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX "idx_jobs_tree-id_name" ON jobs USING btree (tree_id, name);


--
-- Name: index_branches_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_branches_on_name ON branches USING btree (name);


--
-- Name: index_branches_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_branches_on_repository_id_and_name ON branches USING btree (repository_id, name);


--
-- Name: index_commit_arcs_on_child_id_and_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commit_arcs_on_child_id_and_parent_id ON commit_arcs USING btree (child_id, parent_id);


--
-- Name: index_commit_arcs_on_parent_id_and_child_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_commit_arcs_on_parent_id_and_child_id ON commit_arcs USING btree (parent_id, child_id);


--
-- Name: index_commits_on_author_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_author_date ON commits USING btree (author_date);


--
-- Name: index_commits_on_committer_date; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_committer_date ON commits USING btree (committer_date);


--
-- Name: index_commits_on_depth; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_depth ON commits USING btree (depth);


--
-- Name: index_commits_on_tree_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_tree_id ON commits USING btree (tree_id);


--
-- Name: index_commits_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_updated_at ON commits USING btree (updated_at);


--
-- Name: index_email_addresses_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_email_addresses_on_user_id ON email_addresses USING btree (user_id);


--
-- Name: index_executors_on_accepted_repositories; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_executors_on_accepted_repositories ON executors USING btree (accepted_repositories);


--
-- Name: index_executors_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_executors_on_name ON executors USING btree (name);


--
-- Name: index_executors_on_traits; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_executors_on_traits ON executors USING btree (traits);


--
-- Name: index_job_issues_on_job_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_job_issues_on_job_id ON job_issues USING btree (job_id);


--
-- Name: index_jobs_on_job_specification_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_job_specification_id ON jobs USING btree (job_specification_id);


--
-- Name: index_jobs_on_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_key ON jobs USING btree (key);


--
-- Name: index_jobs_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_name ON jobs USING btree (name);


--
-- Name: index_jobs_on_tree_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_jobs_on_tree_id ON jobs USING btree (tree_id);


--
-- Name: index_repositories_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_created_at ON repositories USING btree (created_at);


--
-- Name: index_repositories_on_git_url; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_repositories_on_git_url ON repositories USING btree (git_url);


--
-- Name: index_repositories_on_update_notification_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_update_notification_token ON repositories USING btree (update_notification_token);


--
-- Name: index_repositories_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_updated_at ON repositories USING btree (updated_at);


--
-- Name: index_scripts_on_trial_id_and_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_scripts_on_trial_id_and_key ON scripts USING btree (trial_id, key);


--
-- Name: index_submodules_on_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_submodules_on_commit_id ON submodules USING btree (commit_id);


--
-- Name: index_submodules_on_submodule_commit_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_submodules_on_submodule_commit_id ON submodules USING btree (submodule_commit_id);


--
-- Name: index_tasks_on_exclusive_global_resources; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_exclusive_global_resources ON tasks USING btree (exclusive_global_resources);


--
-- Name: index_tasks_on_job_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_job_id ON tasks USING btree (job_id);


--
-- Name: index_tasks_on_job_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tasks_on_job_id_and_name ON tasks USING btree (job_id, name);


--
-- Name: index_tasks_on_task_specification_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_task_specification_id ON tasks USING btree (task_specification_id);


--
-- Name: index_tasks_on_traits; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_traits ON tasks USING btree (traits);


--
-- Name: index_tree_attachments_on_tree_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tree_attachments_on_tree_id ON tree_attachments USING btree (tree_id);


--
-- Name: index_tree_attachments_on_tree_id_and_path; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tree_attachments_on_tree_id_and_path ON tree_attachments USING btree (tree_id, path);


--
-- Name: index_trial_attachments_on_trial_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trial_attachments_on_trial_id ON trial_attachments USING btree (trial_id);


--
-- Name: index_trial_attachments_on_trial_id_and_path; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_trial_attachments_on_trial_id_and_path ON trial_attachments USING btree (trial_id, path);


--
-- Name: index_trial_issues_on_trial_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trial_issues_on_trial_id ON trial_issues USING btree (trial_id);


--
-- Name: index_trials_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trials_on_state ON trials USING btree (state);


--
-- Name: index_trials_on_task_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trials_on_task_id ON trials USING btree (task_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_lower_login_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_lower_login_idx ON users USING btree (lower((login)::text));


--
-- Name: _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO executors_with_load DO INSTEAD  SELECT executors.id,
    executors.name,
    executors.max_load,
    executors.enabled,
    executors.traits,
    executors.base_url,
    executors.last_ping_at,
    executors.created_at,
    executors.updated_at,
    executors.accepted_repositories,
    count(trials.executor_id) AS current_load,
    ((count(trials.executor_id))::double precision / (executors.max_load)::double precision) AS relative_load
   FROM (executors
     LEFT JOIN trials ON (((trials.executor_id = executors.id) AND ((trials.state)::text = ANY ((ARRAY['dispatching'::character varying, 'executing'::character varying])::text[])))))
  GROUP BY executors.id;


--
-- Name: _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO job_cache_signatures DO INSTEAD  SELECT jobs.id AS job_id,
    md5(string_agg(DISTINCT (branches.updated_at)::text, ',
               '::text ORDER BY (branches.updated_at)::text)) AS branches_signature,
    md5(string_agg(DISTINCT (commits.updated_at)::text, ',
               '::text ORDER BY (commits.updated_at)::text)) AS commits_signature,
    md5(string_agg(DISTINCT (job_issues.updated_at)::text, ',
               '::text ORDER BY (job_issues.updated_at)::text)) AS job_issues_signature,
    count(DISTINCT job_issues.*) AS job_issues_count,
    md5(string_agg(DISTINCT (repositories.updated_at)::text, ',
               '::text ORDER BY (repositories.updated_at)::text)) AS repositories_signature,
    ( SELECT (((count(DISTINCT tasks.id))::text || ' - '::text) || (max(tasks.updated_at))::text)
           FROM tasks
          WHERE (tasks.job_id = jobs.id)) AS tasks_signature,
    ( SELECT count(DISTINCT tree_attachments.id) AS count
           FROM tree_attachments
          WHERE (tree_attachments.tree_id = (jobs.tree_id)::text)) AS tree_attachments_count
   FROM (((((jobs
     LEFT JOIN job_issues ON ((jobs.id = job_issues.job_id)))
     LEFT JOIN commits ON (((jobs.tree_id)::text = (commits.tree_id)::text)))
     LEFT JOIN branches_commits ON (((branches_commits.commit_id)::text = (commits.id)::text)))
     LEFT JOIN branches ON ((branches_commits.branch_id = branches.id)))
     LEFT JOIN repositories ON ((branches.repository_id = repositories.id)))
  GROUP BY jobs.id;


--
-- Name: update_updated_at_column_of_branches; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_branches BEFORE UPDATE ON branches FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_commits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_commits BEFORE UPDATE ON commits FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_executors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_executors BEFORE UPDATE ON executors FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_job_issues; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_job_issues BEFORE UPDATE ON job_issues FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_jobs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_jobs BEFORE UPDATE ON jobs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_repositories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_repositories BEFORE UPDATE ON repositories FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_scripts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_scripts BEFORE UPDATE ON scripts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_tasks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_tasks BEFORE UPDATE ON tasks FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_tree_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_tree_attachments BEFORE UPDATE ON tree_attachments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_trial_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_trial_attachments BEFORE UPDATE ON trial_attachments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_trial_issues; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_trial_issues BEFORE UPDATE ON trial_issues FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_trials; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_trials BEFORE UPDATE ON trials FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_users BEFORE UPDATE ON users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_welcome_page_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_welcome_page_settings BEFORE UPDATE ON welcome_page_settings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: fk_rails_2595d4f43b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trial_attachments
    ADD CONSTRAINT fk_rails_2595d4f43b FOREIGN KEY (trial_id) REFERENCES trials(id) ON DELETE CASCADE;


--
-- Name: fk_rails_3bfb7b73f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trials
    ADD CONSTRAINT fk_rails_3bfb7b73f7 FOREIGN KEY (aborted_by) REFERENCES users(id);


--
-- Name: fk_rails_3ccf965e25; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT fk_rails_3ccf965e25 FOREIGN KEY (created_by) REFERENCES users(id);


--
-- Name: fk_rails_3e557ab362; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trials
    ADD CONSTRAINT fk_rails_3e557ab362 FOREIGN KEY (created_by) REFERENCES users(id);


--
-- Name: fk_rails_5056f0a1f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT fk_rails_5056f0a1f0 FOREIGN KEY (aborted_by) REFERENCES users(id);


--
-- Name: fk_rails_637f302c5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY commit_arcs
    ADD CONSTRAINT fk_rails_637f302c5b FOREIGN KEY (parent_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: fk_rails_73565c5700; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY submodules
    ADD CONSTRAINT fk_rails_73565c5700 FOREIGN KEY (commit_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: fk_rails_741467517e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches
    ADD CONSTRAINT fk_rails_741467517e FOREIGN KEY (current_commit_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: fk_rails_ce2b80387a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches_commits
    ADD CONSTRAINT fk_rails_ce2b80387a FOREIGN KEY (commit_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: fk_rails_ce3c7008c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches
    ADD CONSTRAINT fk_rails_ce3c7008c0 FOREIGN KEY (repository_id) REFERENCES repositories(id);


--
-- Name: fk_rails_cf50105b6a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT fk_rails_cf50105b6a FOREIGN KEY (resumed_by) REFERENCES users(id);


--
-- Name: fk_rails_de643267e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_addresses
    ADD CONSTRAINT fk_rails_de643267e7 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_rails_eb81826b6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY scripts
    ADD CONSTRAINT fk_rails_eb81826b6c FOREIGN KEY (trial_id) REFERENCES trials(id) ON DELETE CASCADE;


--
-- Name: fk_rails_f1b0bc6b0c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches_commits
    ADD CONSTRAINT fk_rails_f1b0bc6b0c FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE;


--
-- Name: fk_rails_fe00cc3459; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY commit_arcs
    ADD CONSTRAINT fk_rails_fe00cc3459 FOREIGN KEY (child_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: job_issues_jobs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY job_issues
    ADD CONSTRAINT job_issues_jobs_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;


--
-- Name: jobs_job-specifications_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY jobs
    ADD CONSTRAINT "jobs_job-specifications_fkey" FOREIGN KEY (job_specification_id) REFERENCES job_specifications(id);


--
-- Name: tasks_jobs_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_jobs_fkey FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;


--
-- Name: trial_issues_trials_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trial_issues
    ADD CONSTRAINT trial_issues_trials_fkey FOREIGN KEY (trial_id) REFERENCES trials(id) ON DELETE CASCADE;


--
-- Name: trials_tasks_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_tasks_fkey FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('0');

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('22');

INSERT INTO schema_migrations (version) VALUES ('25');

INSERT INTO schema_migrations (version) VALUES ('26');

INSERT INTO schema_migrations (version) VALUES ('27');

INSERT INTO schema_migrations (version) VALUES ('28');

INSERT INTO schema_migrations (version) VALUES ('29');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('32');

INSERT INTO schema_migrations (version) VALUES ('33');

INSERT INTO schema_migrations (version) VALUES ('34');

INSERT INTO schema_migrations (version) VALUES ('35');

INSERT INTO schema_migrations (version) VALUES ('36');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('38');

INSERT INTO schema_migrations (version) VALUES ('39');

INSERT INTO schema_migrations (version) VALUES ('40');

INSERT INTO schema_migrations (version) VALUES ('41');

INSERT INTO schema_migrations (version) VALUES ('42');

INSERT INTO schema_migrations (version) VALUES ('43');

INSERT INTO schema_migrations (version) VALUES ('45');

INSERT INTO schema_migrations (version) VALUES ('46');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('51');

INSERT INTO schema_migrations (version) VALUES ('52');

INSERT INTO schema_migrations (version) VALUES ('53');

INSERT INTO schema_migrations (version) VALUES ('54');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

