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
-- Name: branch_update_triggers_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE branch_update_triggers_tags (
    branch_update_trigger_id uuid,
    tag_id uuid
);


--
-- Name: branches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE branches (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    repository_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    current_commit_id character varying(40) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
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
    author_name character varying(255),
    author_email character varying(255),
    author_date timestamp without time zone,
    committer_name character varying(255),
    committer_email character varying(255),
    committer_date timestamp without time zone,
    subject text,
    body text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: executions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE executions (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    state character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    tree_id character varying(40) NOT NULL,
    name character varying(255) NOT NULL,
    priority integer DEFAULT 5,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    specification_id uuid,
    expanded_specification_id uuid,
    result jsonb,
    CONSTRAINT check_executions_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'pending'::character varying, 'executing'::character varying, 'passed'::character varying])::text[])))
);


--
-- Name: repositories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE repositories (
    id uuid NOT NULL,
    origin_uri character varying(255),
    name character varying(255),
    importance integer DEFAULT 0 NOT NULL,
    git_fetch_and_update_interval integer DEFAULT 60,
    git_update_interval integer,
    transient_properties_id uuid DEFAULT uuid_generate_v4(),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    public_view_permission boolean DEFAULT false NOT NULL
);


--
-- Name: commit_cache_signatures; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW commit_cache_signatures AS
 SELECT commits.id AS commit_id,
    md5(string_agg(DISTINCT (branches.updated_at)::text, ', '::text ORDER BY (branches.updated_at)::text)) AS branches_signature,
    md5(string_agg(DISTINCT (repositories.updated_at)::text, ', '::text ORDER BY (repositories.updated_at)::text)) AS repositories_signature,
    md5(string_agg(DISTINCT (executions.updated_at)::text, ', '::text ORDER BY (executions.updated_at)::text)) AS executions_signature
   FROM ((((commits
     LEFT JOIN branches_commits ON (((branches_commits.commit_id)::text = (commits.id)::text)))
     LEFT JOIN branches ON ((branches_commits.branch_id = branches.id)))
     LEFT JOIN executions ON (((executions.tree_id)::text = (commits.tree_id)::text)))
     LEFT JOIN repositories ON ((branches.repository_id = repositories.id)))
  GROUP BY commits.id;


--
-- Name: definitions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE definitions (
    name character varying(255) NOT NULL,
    description character varying(255),
    specification_id uuid,
    is_default boolean DEFAULT false NOT NULL
);


--
-- Name: depths; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW depths AS
 SELECT cd.id AS commit_id,
    cd.depth
   FROM ( WITH RECURSIVE ancestors(id, depth) AS (
                 SELECT commits.id,
                    0 AS depth
                   FROM commits
                  WHERE ((NOT (EXISTS ( SELECT 1
                           FROM commit_arcs
                          WHERE ((commits.id)::text = (commit_arcs.child_id)::text)))) AND (commits.depth IS NULL))
                UNION
                 SELECT parents.id,
                    parents.depth
                   FROM commits parents
                  WHERE ((parents.depth IS NOT NULL) AND (EXISTS ( SELECT 1
                           FROM commits children,
                            commit_arcs
                          WHERE (((children.depth IS NULL) AND ((commit_arcs.child_id)::text = (children.id)::text)) AND ((commit_arcs.parent_id)::text = (parents.id)::text)))))
                UNION
                 SELECT commits.id,
                    (ancestors_1.depth + 1)
                   FROM commits,
                    ancestors ancestors_1,
                    commit_arcs
                  WHERE ((((commits.id)::text = (commit_arcs.child_id)::text) AND ((ancestors_1.id)::text = (commit_arcs.parent_id)::text)) AND (commits.depth IS NULL))
                )
         SELECT ancestors.id,
            max(ancestors.depth) AS depth
           FROM ancestors
          GROUP BY ancestors.id
          ORDER BY max(ancestors.depth)) cd;


--
-- Name: email_addresses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE email_addresses (
    user_id uuid,
    email_address character varying(255) NOT NULL,
    searchable character varying(255),
    "primary" boolean DEFAULT false NOT NULL
);


--
-- Name: execution_issues; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE execution_issues (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    description text,
    stacktrace text,
    type character varying(255) DEFAULT 'error'::character varying NOT NULL,
    execution_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT valid_type CHECK (((type)::text = ANY ((ARRAY['error'::character varying, 'warning'::character varying])::text[])))
);


--
-- Name: executions_tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE executions_tags (
    execution_id uuid,
    tag_id uuid
);


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tasks (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    execution_id uuid NOT NULL,
    state character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    priority integer DEFAULT 5 NOT NULL,
    traits character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    name character varying(255),
    error text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    task_spec_id uuid,
    result jsonb,
    CONSTRAINT check_tasks_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'pending'::character varying, 'executing'::character varying, 'passed'::character varying])::text[])))
);


--
-- Name: execution_cache_signatures; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW execution_cache_signatures AS
 SELECT executions.id AS execution_id,
    md5(string_agg(DISTINCT (branches.updated_at)::text, ', '::text ORDER BY (branches.updated_at)::text)) AS branches_signature,
    md5(string_agg(DISTINCT (commits.updated_at)::text, ', '::text ORDER BY (commits.updated_at)::text)) AS commits_signature,
    md5(string_agg(DISTINCT (execution_issues.updated_at)::text, ', '::text ORDER BY (execution_issues.updated_at)::text)) AS execution_issues_signature,
    count(DISTINCT execution_issues.*) AS execution_issues_count,
    md5(string_agg(DISTINCT (repositories.updated_at)::text, ', '::text ORDER BY (repositories.updated_at)::text)) AS repositories_signature,
    ( SELECT md5(string_agg((executions_tags.tag_id)::text, ','::text ORDER BY executions_tags.tag_id)) AS md5
           FROM executions_tags
          WHERE (executions_tags.execution_id = executions.id)) AS tags_signature,
    ( SELECT (((count(DISTINCT tasks.id))::text || ' - '::text) || (max(tasks.updated_at))::text)
           FROM tasks
          WHERE (tasks.execution_id = executions.id)) AS tasks_signature
   FROM (((((executions
     LEFT JOIN execution_issues ON ((executions.id = execution_issues.execution_id)))
     LEFT JOIN commits ON (((executions.tree_id)::text = (commits.tree_id)::text)))
     LEFT JOIN branches_commits ON (((branches_commits.commit_id)::text = (commits.id)::text)))
     LEFT JOIN branches ON ((branches_commits.branch_id = branches.id)))
     LEFT JOIN repositories ON ((branches.repository_id = repositories.id)))
  GROUP BY executions.id;


--
-- Name: execution_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW execution_stats AS
 SELECT executions.id AS execution_id,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE (tasks.execution_id = executions.id)) AS total,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.execution_id = executions.id) AND ((tasks.state)::text = 'aborted'::text))) AS aborted,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.execution_id = executions.id) AND ((tasks.state)::text = 'executing'::text))) AS executing,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.execution_id = executions.id) AND ((tasks.state)::text = 'failed'::text))) AS failed,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.execution_id = executions.id) AND ((tasks.state)::text = 'passed'::text))) AS passed,
    ( SELECT count(*) AS count
           FROM tasks
          WHERE ((tasks.execution_id = executions.id) AND ((tasks.state)::text = 'pending'::text))) AS pending
   FROM executions;


--
-- Name: executors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE executors (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(255),
    host character varying(255) NOT NULL,
    port integer DEFAULT 8443 NOT NULL,
    ssl boolean DEFAULT true NOT NULL,
    server_overwrite boolean DEFAULT false,
    server_ssl boolean DEFAULT true,
    server_host character varying(255) DEFAULT '192.168.0.1'::character varying,
    server_port integer DEFAULT 8080,
    max_load integer DEFAULT 4 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    app character varying(255),
    app_version character varying(255),
    traits character varying(255)[] DEFAULT '{}'::character varying[] NOT NULL,
    last_ping_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: executors_with_load; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE executors_with_load (
    id uuid,
    name character varying(255),
    host character varying(255),
    port integer,
    ssl boolean,
    server_overwrite boolean,
    server_ssl boolean,
    server_host character varying(255),
    server_port integer,
    max_load integer,
    enabled boolean,
    app character varying(255),
    app_version character varying(255),
    traits character varying(255)[],
    last_ping_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    current_load bigint,
    relative_load double precision
);

ALTER TABLE ONLY executors_with_load REPLICA IDENTITY NOTHING;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: specifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE specifications (
    id uuid NOT NULL,
    data jsonb
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    tag character varying(255),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: task_specs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE task_specs (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    data jsonb
);


--
-- Name: timeout_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE timeout_settings (
    id integer NOT NULL,
    trial_dispatch_timeout_minutes integer DEFAULT 60 NOT NULL,
    trial_end_state_timeout_minutes integer DEFAULT 180 NOT NULL,
    trial_execution_timeout_minutes integer DEFAULT 5 NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    trial_scripts_retention_time_days integer DEFAULT 10 NOT NULL,
    CONSTRAINT one_and_only_one CHECK ((id = 0)),
    CONSTRAINT trial_dispatch_timeout_minutes_positive CHECK ((trial_dispatch_timeout_minutes > 0)),
    CONSTRAINT trial_end_state_timeout_minutes_positive CHECK ((trial_end_state_timeout_minutes > 0)),
    CONSTRAINT trial_execution_timeout_minutes_positive CHECK ((trial_execution_timeout_minutes > 0))
);


--
-- Name: tree_attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tree_attachments (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    path text NOT NULL,
    content_length text,
    content_type text,
    to_be_retained_before timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: trial_attachments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trial_attachments (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    path text NOT NULL,
    content_length text,
    content_type text,
    to_be_retained_before timestamp without time zone,
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
    state character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    scripts jsonb,
    result jsonb,
    CONSTRAINT check_trials_valid_state CHECK (((state)::text = ANY ((ARRAY['failed'::character varying, 'aborted'::character varying, 'pending'::character varying, 'dispatching'::character varying, 'executing'::character varying, 'passed'::character varying])::text[])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    password_digest character varying(255),
    login character varying(255) NOT NULL,
    login_downcased character varying(255) NOT NULL,
    last_name character varying(255) DEFAULT ''::character varying NOT NULL,
    first_name character varying(255) DEFAULT ''::character varying NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: welcome_page_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE welcome_page_settings (
    id integer NOT NULL,
    welcome_message text,
    radiator_config json,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
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
-- Name: definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY definitions
    ADD CONSTRAINT definitions_pkey PRIMARY KEY (name);


--
-- Name: email_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY email_addresses
    ADD CONSTRAINT email_addresses_pkey PRIMARY KEY (email_address);


--
-- Name: execution_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY execution_issues
    ADD CONSTRAINT execution_issues_pkey PRIMARY KEY (id);


--
-- Name: executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY executions
    ADD CONSTRAINT executions_pkey PRIMARY KEY (id);


--
-- Name: executors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY executors
    ADD CONSTRAINT executors_pkey PRIMARY KEY (id);


--
-- Name: repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY repositories
    ADD CONSTRAINT repositories_pkey PRIMARY KEY (id);


--
-- Name: specifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY specifications
    ADD CONSTRAINT specifications_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: task_specs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY task_specs
    ADD CONSTRAINT task_specs_pkey PRIMARY KEY (id);


--
-- Name: tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: timeout_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY timeout_settings
    ADD CONSTRAINT timeout_settings_pkey PRIMARY KEY (id);


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
-- Name: email_addresses_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX email_addresses_to_tsvector_idx ON email_addresses USING gin (to_tsvector('english'::regconfig, (email_address)::text));


--
-- Name: email_addresses_to_tsvector_idx1; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX email_addresses_to_tsvector_idx1 ON email_addresses USING gin (to_tsvector('english'::regconfig, (searchable)::text));


--
-- Name: exectutions_lower_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX exectutions_lower_name_idx ON executions USING btree (lower((name)::text));


--
-- Name: exectutions_tree_id_lower_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX exectutions_tree_id_lower_name_idx ON executions USING btree (tree_id, lower((name)::text));


--
-- Name: index_branches_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_branches_on_created_at ON branches USING btree (created_at);


--
-- Name: index_branches_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_branches_on_name ON branches USING btree (name);


--
-- Name: index_branches_on_repository_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_branches_on_repository_id_and_name ON branches USING btree (repository_id, name);


--
-- Name: index_branches_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_branches_on_updated_at ON branches USING btree (updated_at);


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
-- Name: index_commits_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_created_at ON commits USING btree (created_at);


--
-- Name: index_commits_on_tree_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_commits_on_tree_id ON commits USING btree (tree_id);


--
-- Name: index_email_addresses_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_email_addresses_on_user_id ON email_addresses USING btree (user_id);


--
-- Name: index_execution_issues_on_execution_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_execution_issues_on_execution_id ON execution_issues USING btree (execution_id);


--
-- Name: index_executions_on_column_and_tree_id_and_specification_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_executions_on_column_and_tree_id_and_specification_id ON executions USING btree (tree_id, specification_id);


--
-- Name: index_executions_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_executions_on_created_at ON executions USING btree (created_at);


--
-- Name: index_executions_on_tree_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_executions_on_tree_id ON executions USING btree (tree_id);


--
-- Name: index_executions_tags_on_execution_id_and_tag_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_executions_tags_on_execution_id_and_tag_id ON executions_tags USING btree (execution_id, tag_id);


--
-- Name: index_executions_tags_on_tag_id_and_execution_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_executions_tags_on_tag_id_and_execution_id ON executions_tags USING btree (tag_id, execution_id);


--
-- Name: index_executors_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_executors_on_name ON executors USING btree (name);


--
-- Name: index_executors_on_traits; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_executors_on_traits ON executors USING btree (traits);


--
-- Name: index_repositories_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_repositories_on_created_at ON repositories USING btree (created_at);


--
-- Name: index_repositories_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_repositories_on_name ON repositories USING btree (name);


--
-- Name: index_tags_on_tag; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tags_on_tag ON tags USING btree (tag);


--
-- Name: index_tasks_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_created_at ON tasks USING btree (created_at);


--
-- Name: index_tasks_on_execution_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_execution_id ON tasks USING btree (execution_id);


--
-- Name: index_tasks_on_execution_id_and_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_execution_id_and_state ON tasks USING btree (execution_id, state);


--
-- Name: index_tasks_on_execution_id_and_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_execution_id_and_updated_at ON tasks USING btree (execution_id, updated_at);


--
-- Name: index_tasks_on_traits; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tasks_on_traits ON tasks USING btree (traits);


--
-- Name: index_tree_attachments_on_path; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tree_attachments_on_path ON tree_attachments USING btree (path);


--
-- Name: index_trial_attachments_on_path; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_trial_attachments_on_path ON trial_attachments USING btree (path);


--
-- Name: index_trials_on_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trials_on_created_at ON trials USING btree (created_at);


--
-- Name: index_trials_on_state; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trials_on_state ON trials USING btree (state);


--
-- Name: index_trials_on_task_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_trials_on_task_id ON trials USING btree (task_id);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login ON users USING btree (login);


--
-- Name: index_users_on_login_downcased; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login_downcased ON users USING btree (login_downcased);


--
-- Name: repositories_lower_name_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX repositories_lower_name_idx ON repositories USING btree (lower((name)::text));


--
-- Name: tag_trigger_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tag_trigger_idx ON branch_update_triggers_tags USING btree (tag_id, branch_update_trigger_id);


--
-- Name: tags_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_to_tsvector_idx ON tags USING gin (to_tsvector('english'::regconfig, (tag)::text));


--
-- Name: trigger_tag_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX trigger_tag_idx ON branch_update_triggers_tags USING btree (branch_update_trigger_id, tag_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: users_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_to_tsvector_idx ON users USING gin (to_tsvector('english'::regconfig, (login)::text));


--
-- Name: users_to_tsvector_idx1; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_to_tsvector_idx1 ON users USING gin (to_tsvector('english'::regconfig, (login_downcased)::text));


--
-- Name: users_to_tsvector_idx2; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_to_tsvector_idx2 ON users USING gin (to_tsvector('english'::regconfig, (first_name)::text));


--
-- Name: users_to_tsvector_idx3; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_to_tsvector_idx3 ON users USING gin (to_tsvector('english'::regconfig, (last_name)::text));


--
-- Name: _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE RULE "_RETURN" AS
    ON SELECT TO executors_with_load DO INSTEAD  SELECT executors.id,
    executors.name,
    executors.host,
    executors.port,
    executors.ssl,
    executors.server_overwrite,
    executors.server_ssl,
    executors.server_host,
    executors.server_port,
    executors.max_load,
    executors.enabled,
    executors.app,
    executors.app_version,
    executors.traits,
    executors.last_ping_at,
    executors.created_at,
    executors.updated_at,
    count(trials.executor_id) AS current_load,
    ((count(trials.executor_id))::double precision / (executors.max_load)::double precision) AS relative_load
   FROM (executors
     LEFT JOIN trials ON (((trials.executor_id = executors.id) AND ((trials.state)::text = ANY ((ARRAY['dispatching'::character varying, 'executing'::character varying])::text[])))))
  GROUP BY executors.id;


--
-- Name: update_updated_at_column_of_branches; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_branches BEFORE UPDATE ON branches FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_commits; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_commits BEFORE UPDATE ON commits FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_execution_issues; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_execution_issues BEFORE UPDATE ON execution_issues FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_executions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_executions BEFORE UPDATE ON executions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_executors; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_executors BEFORE UPDATE ON executors FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_repositories; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_repositories BEFORE UPDATE ON repositories FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_tags; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_tags BEFORE UPDATE ON tags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_tasks; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_tasks BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_timeout_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_timeout_settings BEFORE UPDATE ON timeout_settings FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_tree_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_tree_attachments BEFORE UPDATE ON tree_attachments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: update_updated_at_column_of_trial_attachments; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_trial_attachments BEFORE UPDATE ON trial_attachments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE update_updated_at_column();


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

CREATE TRIGGER update_updated_at_column_of_welcome_page_settings BEFORE UPDATE ON welcome_page_settings FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();


--
-- Name: branch_update_triggers_tags_tag_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branch_update_triggers_tags
    ADD CONSTRAINT branch_update_triggers_tags_tag_id_fk FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE;


--
-- Name: branches_commits_branch_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches_commits
    ADD CONSTRAINT branches_commits_branch_id_fk FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE;


--
-- Name: branches_commits_commit_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches_commits
    ADD CONSTRAINT branches_commits_commit_id_fk FOREIGN KEY (commit_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: branches_current_commit_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches
    ADD CONSTRAINT branches_current_commit_id_fk FOREIGN KEY (current_commit_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: branches_repository_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY branches
    ADD CONSTRAINT branches_repository_id_fk FOREIGN KEY (repository_id) REFERENCES repositories(id);


--
-- Name: commit_arcs_child_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY commit_arcs
    ADD CONSTRAINT commit_arcs_child_id_fk FOREIGN KEY (child_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: commit_arcs_parent_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY commit_arcs
    ADD CONSTRAINT commit_arcs_parent_id_fk FOREIGN KEY (parent_id) REFERENCES commits(id) ON DELETE CASCADE;


--
-- Name: email_addresses_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_addresses
    ADD CONSTRAINT email_addresses_user_id_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: execution_issues_execution_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY execution_issues
    ADD CONSTRAINT execution_issues_execution_id_fk FOREIGN KEY (execution_id) REFERENCES executions(id) ON DELETE CASCADE;


--
-- Name: executions_expanded_specification_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY executions
    ADD CONSTRAINT executions_expanded_specification_id_fk FOREIGN KEY (expanded_specification_id) REFERENCES specifications(id);


--
-- Name: executions_specification_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY executions
    ADD CONSTRAINT executions_specification_id_fk FOREIGN KEY (specification_id) REFERENCES specifications(id);


--
-- Name: executions_tags_execution_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY executions_tags
    ADD CONSTRAINT executions_tags_execution_id_fk FOREIGN KEY (execution_id) REFERENCES executions(id) ON DELETE CASCADE;


--
-- Name: executions_tags_tag_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY executions_tags
    ADD CONSTRAINT executions_tags_tag_id_fk FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE;


--
-- Name: tasks_execution_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_execution_id_fk FOREIGN KEY (execution_id) REFERENCES executions(id) ON DELETE CASCADE;


--
-- Name: tasks_task_spec_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tasks
    ADD CONSTRAINT tasks_task_spec_id_fk FOREIGN KEY (task_spec_id) REFERENCES task_specs(id) ON DELETE SET NULL;


--
-- Name: trials_task_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trials
    ADD CONSTRAINT trials_task_id_fk FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('100');

INSERT INTO schema_migrations (version) VALUES ('102');

INSERT INTO schema_migrations (version) VALUES ('103');

INSERT INTO schema_migrations (version) VALUES ('104');

INSERT INTO schema_migrations (version) VALUES ('105');

INSERT INTO schema_migrations (version) VALUES ('106');

INSERT INTO schema_migrations (version) VALUES ('107');

INSERT INTO schema_migrations (version) VALUES ('108');

INSERT INTO schema_migrations (version) VALUES ('109');

INSERT INTO schema_migrations (version) VALUES ('110');

INSERT INTO schema_migrations (version) VALUES ('111');

INSERT INTO schema_migrations (version) VALUES ('112');

INSERT INTO schema_migrations (version) VALUES ('113');

INSERT INTO schema_migrations (version) VALUES ('114');

INSERT INTO schema_migrations (version) VALUES ('115');

INSERT INTO schema_migrations (version) VALUES ('116');

INSERT INTO schema_migrations (version) VALUES ('117');

INSERT INTO schema_migrations (version) VALUES ('118');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('18');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('30');

INSERT INTO schema_migrations (version) VALUES ('37');

INSERT INTO schema_migrations (version) VALUES ('38');

INSERT INTO schema_migrations (version) VALUES ('40');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('50');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('60');

INSERT INTO schema_migrations (version) VALUES ('65');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('70');

INSERT INTO schema_migrations (version) VALUES ('71');

INSERT INTO schema_migrations (version) VALUES ('74');

INSERT INTO schema_migrations (version) VALUES ('80');

INSERT INTO schema_migrations (version) VALUES ('81');

INSERT INTO schema_migrations (version) VALUES ('82');

INSERT INTO schema_migrations (version) VALUES ('84');

INSERT INTO schema_migrations (version) VALUES ('85');

INSERT INTO schema_migrations (version) VALUES ('86');

INSERT INTO schema_migrations (version) VALUES ('87');

INSERT INTO schema_migrations (version) VALUES ('88');

INSERT INTO schema_migrations (version) VALUES ('89');

INSERT INTO schema_migrations (version) VALUES ('90');

