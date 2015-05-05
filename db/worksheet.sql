

SELECT trials.*
FROM trials
INNER JOIN tasks ON tasks.id = trials.task_id
INNER JOIN jobs ON jobs.id = tasks.job_id
WHERE ((trials.state = 'pending'
        AND exists(
                     (SELECT 1
                      FROM executors_with_load
                      WHERE (((relative_load < 1
                               AND enabled = TRUE)
                              AND (tasks.traits <@ executors_with_load.traits))
                             AND (last_ping_at > (now() - interval '1 Minutes'))))))
       AND NOT EXISTS(
                        (SELECT 1
                         FROM trials active_trials
                         INNER JOIN tasks active_tasks ON active_tasks.id = active_trials.task_id
                         WHERE ((active_trials.state IN ('executing', 'dispatching'))
                                AND active_tasks.exclusive_global_resources && tasks.exclusive_global_resources))))
ORDER BY jobs.priority DESC,
         jobs.created_at ASC,
         tasks.priority DESC,
         tasks.created_at ASC,
         trials.created_at ASC LIMIT 1
        ;



SELECT 1
FROM trials active_trials
INNER JOIN tasks active_tasks ON active_tasks.id = active_trials.task_id
WHERE true 
AND (active_trials.state IN ('executing', 'dispatching'))
AND active_tasks.exclusive_global_resources && active_tasks.exclusive_global_resources 
;




explain ANALYZE
SELECT id
FROM trials
WHERE STATE NOT IN ('aborted',
                    'success',
                    'failed')
  AND trials.created_at <
    (SELECT now() -
       (SELECT max(trial_end_state_timeout_minutes)
        FROM timeout_settings) * interval '1 Minute');

explain ANALYZE
SELECT id
FROM trials
WHERE STATE IN ('executing', 'pending', 'dispatching')
  AND trials.created_at <
    (SELECT now() -
       (SELECT max(trial_end_state_timeout_minutes)
        FROM timeout_settings) * interval '1 Minute');


select distinct state from trials;

ALTER TABLE trials ADD CONSTRAINT valid_state CHECK ( state in ('failed', 'success'));

ALTER TABLE trials DROP CONSTRAINT valid_state;


explain analyze SELECT commits.id AS commit_id,
       count(branches.id)::text || ' - ' ||  max(branches.updated_at)::text as branches_signature,
       md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
       md5(string_agg(DISTINCT jobs.updated_at::text,', 'ORDER BY jobs.updated_at::text)) AS jobs_signature
FROM commits
LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
LEFT OUTER JOIN jobs ON jobs.tree_id = commits.tree_id
LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
WHERE commits.id = '9525afe09976766eb5d8c881d173f7269675f24b'
GROUP BY commits.id;

-- #################################################################

explain analyze SELECT DISTINCT "commits".*
FROM "commits"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
WHERE "repositories"."name" IN ('Madek')
  AND  "commits"."committer_date"  > ( now() - interval '1000 Days')
ORDER BY "commits"."committer_date" DESC,
         "commits"."depth" DESC LIMIT 12
;


explain analyze SELECT DISTINCT "commits".*
FROM "commits"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
WHERE "branches"."name" IN ('next')
  AND "repositories"."name" IN ('Madek')
  AND  "commits"."committer_date"  > ( now() - interval '100 Days')
ORDER BY "commits"."committer_date" DESC,
         "commits"."depth" DESC LIMIT 12
OFFSET 0
;





OFFSET 0
-- TODO test/add (tasks.job_id, tasks.updated_at) index 
-- TODO test/add (tasks.job_id, tasks.state ) index 
-- TODO add tasks.updated_at index 
-- TODO add tasks.state index


explain analyze SELECT * FROM job_stats 
where job_id = 'ded35229-12dc-4471-9b9d-288fc33fc67d'; 

explain analyze SELECT "job_cache_signatures".*
FROM "job_cache_signatures"
WHERE (job_id IN ('78d5fca7-2b45-47b6-be4e-e1d43cdb4b12',
                        '9083e49f-20df-4f7d-ada7-403e6477b879',
                        '73909e12-02b3-47ae-a4bc-cab93e3ba071',
                        'ded35229-12dc-4471-9b9d-288fc33fc67d',
                        '4f28e3ec-2700-43d3-ae6b-3bcb785b7d0a',
                        '4daf28dd-1c38-45e6-a765-3a813b4898c7',
                        'ea6c4117-425f-491a-9db6-f3a04f82abb1',
                        '5c812397-8b51-4ed3-a956-32cf6d04522e',
                        'a95df42a-cfbb-4853-93a4-169ba5e5d7fa',
                        'c05d19e4-55b6-4078-831d-76cf77f5f9dd',
                        '6aba2625-1918-4ebb-8d02-9604da06044f',
                        'a95f4bd6-afb4-4abc-879b-a5c3eaa7d8f2'))
                    ;

explain analyze SELECT jobs.id as job_id,
md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
md5(string_agg(DISTINCT commits.updated_at::text,', 'ORDER BY commits.updated_at::text)) AS commits_signature,
md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
md5(string_agg(DISTINCT tags.updated_at::text,', 'ORDER BY tags.updated_at::text)) AS tags_signature,
count(DISTINCT tasks.id)::text || ' - ' ||  max(tasks.updated_at)::text as tasks_signature
FROM jobs
LEFT OUTER JOIN commits ON jobs.tree_id = commits.tree_id
LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
LEFT OUTER JOIN tasks ON tasks.job_id = jobs.id
LEFT OUTER JOIN jobs_tags ON jobs_tags.job_id = jobs.id
LEFT OUTER JOIN tags ON jobs_tags.tag_id = tags.id
WHERE jobs.id = 'ded35229-12dc-4471-9b9d-288fc33fc67d'
GROUP BY jobs.id;

explain analyze SELECT jobs.id as job_id,
md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
md5(string_agg(DISTINCT commits.updated_at::text,', 'ORDER BY commits.updated_at::text)) AS commits_signature,
md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
(SELECT (md5(string_agg(jobs_tags.tag_id::text,',' ORDER BY tag_id))) FROM jobs_tags WHERE jobs_tags.job_id = jobs.id) AS tags_signature,
(SELECT (count(DISTINCT tasks.id)::text || ' - ' || max(tasks.updated_at)::text ) FROM tasks WHERE tasks.job_id = jobs.id) as tasks_signature,
(SELECT ( count(trials.id)::text || ' - ' ||  max(trials.updated_at)::text ) FROM tasks JOIN trials ON trials.task_id = tasks.id WHERE tasks.job_id = jobs.id) AS trials_signature,
(SELECT concat_ws(':', total,failed,executing,pending,success) FROM job_stats WHERE job_id = jobs.id) as stats_signature
FROM jobs
LEFT OUTER JOIN commits ON jobs.tree_id = commits.tree_id
LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
WHERE jobs.id = 'ded35229-12dc-4471-9b9d-288fc33fc67d'
GROUP BY jobs.id;


explain analyze SELECT concat_ws(':', total,failed,executing,pending,success)  FROM job_stats
WHERE job_id = 'ded35229-12dc-4471-9b9d-288fc33fc67d' ;


explain analyze SELECT (
  SELECT ( count(trials.id)::text || ' - ' ||  max(trials.updated_at)::text ) FROM tasks 
  JOIN trials ON trials.task_id = tasks.id 
  WHERE tasks.job_id = jobs.id)   FROM jobs
WHERE jobs.id = 'ded35229-12dc-4471-9b9d-288fc33fc67d' ;



explain analyze SELECT jobs.id, 
(select count(*) from tasks where tasks.job_id = jobs.id) as total
FROM jobs
WHERE jobs.id = 'ded35229-12dc-4471-9b9d-288fc33fc67d'
;


explain analyze SELECT jobs.id, 
(select count(*) from tasks where tasks.job_id = jobs.id and state = 'success') as success
FROM jobs
WHERE jobs.id = 'ded35229-12dc-4471-9b9d-288fc33fc67d'
;

explain analyze SELECT tags_signature
FROM "job_cache_signatures"
WHERE (job_id IN ('2727b796-9054-4e39-a450-527e856efede',
                        '0336a2b5-2ba7-41bb-92d3-c01b21904102',
                        '3c0766a1-94a4-407e-a64d-7ca5458f65aa',
                        'c11a98be-326f-4531-9f97-3b6b39a67608',
                        '73a0aa43-3f31-431d-92c6-37f9e614a795',
                        'e7c31583-9fb0-46e3-8ea1-9f5057d6332e',
                        '9d7a1d04-2e43-47c4-ab40-2568c98d988e',
                        'bc791f88-6909-4a61-a74d-9bc6c58a74ac',
                        'bf908f9d-cf0e-45f1-87b7-1cb21b6eb55e',
                        '9456ccb7-0514-40d0-9d41-e029ef46a74e',
                        '11d68ad2-5c51-4ce5-ad3f-e7d0e34b8b8c',
                        'd2fb9339-5557-47b3-8018-4b89494cbe7a'))
;

-- SCRIPTS to be cleaned

SELECT * FROM trials

UPDATE trials SET scripts = '[]'
WHERE json_array_length(scripts) > 0
AND trials.created_at < 
  (SELECT now() - 
    (SELECT max(trial_scripts_retention_time_days)  FROM timeout_settings) 
      * interval '1 day') ;

SELECT * FROM trials
WHERE trials.state = 'pending'
AND trials.created_at < 
  (SELECT now() - 
    (SELECT max(trial_dispatch_timeout_minutes)  FROM timeout_settings) 
      * interval '1 Minute') ;


trial_job_timeout_minutes

-- ######################################


CREATE OR REPLACE FUNCTION array_sort (ANYARRAY)
RETURNS ANYARRAY LANGUAGE SQL
AS $$
SELECT ARRAY(SELECT unnest($1) ORDER BY 1)
$$;

DROP FUNCTION  commit_branches(varchar);

CREATE OR REPLACE FUNCTION commit_branches(varchar(40)) RETURNS  UUID[]
AS $$
WITH RECURSIVE arcs(parent_id,child_id) AS
  (SELECT NULL::varchar, $1::varchar
   UNION SELECT commit_arcs.*
   FROM arcs,
        commit_arcs
   WHERE arcs.child_id = commit_arcs.parent_id)
SELECT array_sort(array_agg(branches.id))
FROM arcs , branches
WHERE current_commit_id = arcs.child_id 
$$ LANGUAGE SQL
;

SELECT * from commit_branches('698c0ca11c2d991d357810a48db5be9980fb8c0a'::varchar);

SELECT * from array_to_string(commit_branches('799c9d036cc0691e7c4503ef531c4fb340fd5d14'::varchar),', ');




SELECT DISTINCT "jobs".*
FROM "jobs"
INNER JOIN "trees" ON "trees"."id" = "jobs"."tree_id"
INNER JOIN "commits" ON "commits"."tree_id" = "trees"."id"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
WHERE "repositories"."name" IN ('Domina CI Executor')
ORDER BY "jobs"."created_at" DESC LIMIT 10
OFFSET 0;


SELECT DISTINCT "jobs".*
FROM "jobs"
INNER JOIN "trees" ON "trees"."id" = "jobs"."tree_id"
INNER JOIN "commits" ON "commits"."tree_id" = "trees"."id"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
WHERE (repositories.name = 'Domina CI Server')
ORDER BY "jobs"."created_at" DESC LIMIT 10
OFFSET 0
;

SELECT * from repositories
WHERE (repositories.name = 'Domina CI Server')
;


SELECT job_id,
       stats_signature,
       commits_signature,
       branches_signature
FROM "job_cache_signatures"
WHERE (job_id IN (NULL));

SELECT "jobs".*
FROM "jobs"
INNER JOIN "jobs_tags" ON "jobs_tags"."job_id" = "jobs"."id"
INNER JOIN "tags" ON "tags"."id" = "jobs_tags"."tag_id"
WHERE TRUE 
-- AND (tags.tag = 'rails4')
AND (tags.tag = 'ts')
ORDER BY "jobs"."created_at" DESC LIMIT 10
OFFSET 0 ;


SELECT commits.id AS commit_id,
       md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
       md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
       md5(string_agg(DISTINCT jobs.updated_at::text,', 'ORDER BY jobs.updated_at::text)) AS jobs_signature
FROM commits
LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
LEFT OUTER JOIN jobs ON jobs.tree_id = commits.tree_id
LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
GROUP BY commits.id
;




SELECT jobs.id, 
(select count(*) from tasks where tasks.job_id = jobs.id) as total,
(select count(*) from tasks where tasks.job_id = jobs.id and state = 'pending') as pending,
(select count(*) from tasks where tasks.job_id = jobs.id and state = 'executing') as executing,
(select count(*) from tasks where tasks.job_id = jobs.id and state = 'failed') as failed,
(select count(*) from tasks where tasks.job_id = jobs.id and state = 'success') as success
FROM jobs
--WHERE jobs.id = '4948b8ed-3021-49d2-a685-9d2815961980'
;

SELECT DISTINCT jobs.id, trials.state
, count(trials.state) OVER (PARTITION BY trials.state)
FROM jobs
LEFT OUTER JOIN tasks ON tasks.job_id = jobs.id
LEFT OUTER JOIN trials ON trials.task_id = tasks.id
WHERE jobs.id = '4948b8ed-3021-49d2-a685-9d2815961980'
;



SELECT _stats.id, _pending.count AS pending, _finished.count AS finished
FROM _stats
RIGHT OUTER JOIN _stats AS _pending ON _stats.id = _pending.id
RIGHT OUTER JOIN _stats AS _finished ON _stats.id = _finished.id
WHERE _stats.id = '4948b8ed-3021-49d2-a685-9d2815961980'
AND _pending.state = 'pending';
AND _finished.state = 'finished' limit 10;


SELECT * from _stats
WHERE _stats.id = '4948b8ed-3021-49d2-a685-9d2815961980'
;


SELECT *
FROM _stats
WHERE true
AND _stats.id = '84140ed4-d9d8-4c21-9504-e5accfe52091' ;


SELECT *
FROM _stats
LEFT OUTER JOIN _stats as _pending ON _stats.id = _pending.id
WHERE true
AND _pending.state = 'pending'
AND _stats.id = '84140ed4-d9d8-4c21-9504-e5accfe52091' ;


CREATE OR REPLACE VIEW  _stats AS 
SELECT jobs.id, trials.state, count(trials.*)
FROM jobs
LEFT OUTER JOIN tasks ON tasks.job_id = jobs.id
LEFT OUTER JOIN trials ON trials.task_id = tasks.id
GROUP BY jobs.id, trials.state;

SELECT jobs.id as job_id,
       md5(string_agg(DISTINCT branches.updated_at::text,', 'ORDER BY branches.updated_at::text)) AS branches_signature,
       md5(string_agg(DISTINCT commits.updated_at::text,', 'ORDER BY commits.updated_at::text)) AS commits_signature,
       md5(string_agg(DISTINCT repositories.updated_at::text,', 'ORDER BY repositories.updated_at::text)) AS repositories_signature,
       md5(string_agg(DISTINCT tasks.updated_at::text,', 'ORDER BY tasks.updated_at::text)) AS tasks_signature,
       md5(string_agg(DISTINCT trials.updated_at::text,', 'ORDER BY trials.updated_at::text)) AS trials_signature
FROM jobs
LEFT OUTER JOIN commits ON jobs.tree_id = commits.tree_id
LEFT OUTER JOIN branches_commits ON branches_commits.commit_id = commits.id
LEFT OUTER JOIN branches ON branches_commits.branch_id= branches.id
LEFT OUTER JOIN repositories ON branches.repository_id= repositories.id
LEFT OUTER JOIN tasks ON tasks.job_id = jobs.id
LEFT OUTER JOIN trials ON trials.task_id = tasks.id
GROUP BY jobs.id;

SELECT jobs.id,
FROM jobs
GROUP BY jobs.id;
 ;




SELECT "trials".*
FROM "trials"
INNER JOIN "tasks" ON "tasks"."id" = "trials"."task_id"
WHERE "trials"."state" = 'pending'
  AND (trials.updated_at < (now() - interval '60 Minutes'))
ORDER BY "trials"."priority" DESC,
         tasks.created_at ASC,
         "trials"."created_at" DESC,
         "trials"."id" ASC
        ;


SELECT "trials".*
FROM "trials"
INNER JOIN "tasks" ON "tasks"."id" = "trials"."task_id"
WHERE "trials"."state" = 'pending'
  AND (trials.created_at < (now() - interval '60 Minutes'))
;

-- uuid pkey for job 
ALTER TABLE jobs ADD id uuid;
UPDATE jobs SET id = uuid_generate_v4();
ALTER TABLE tasks ADD job_id uuid;
UPDATE tasks 
  SET job_id = jobs.id
  FROM jobs
  WHERE tasks.tree_id = jobs.tree_id
  AND tasks.specification_id = jobs.specification_id;
ALTER TABLE tasks DROP tree_id;
ALTER TABLE tasks DROP specification_id;


SELECT DISTINCT "users".*,
                COALESCE(ts_rank(to_tsvector('english', "users"."login"::text), plainto_tsquery('english', 'algocon'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "users"."last_name"::text), plainto_tsquery('english', 'algocon'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "users"."first_name"::text), plainto_tsquery('english', 'algocon'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "email_addresses"."email_address"::text), plainto_tsquery('english', 'algocon'::text)), 0) AS "rank55070702552416812"
FROM "users"
INNER JOIN "email_addresses" ON "email_addresses"."user_id" = "users"."id"
WHERE (to_tsvector('english', "users"."login"::text) @@ plainto_tsquery('english', 'algocon'::text)
       OR to_tsvector('english', "users"."last_name"::text) @@ plainto_tsquery('english', 'algocon'::text)
       OR to_tsvector('english', "users"."first_name"::text) @@ plainto_tsquery('english', 'algocon'::text)
       OR to_tsvector('english', "email_addresses"."email_address"::text) @@ plainto_tsquery('english', 'algocon'::text))
ORDER BY "users"."last_name" ASC,
         "users"."first_name" ASC LIMIT 25

OFFSET 0
SELECT "commits".*,
       COALESCE(ts_rank(to_tsvector('english', "commits"."id"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."tree_id"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."author_name"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."author_email"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."committer_name"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."committer_email"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."subject"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) + COALESCE(ts_rank(to_tsvector('english', "commits"."body"::text), plainto_tsquery('english', 'Permissions\ Franco'::text)), 0) AS "rank47121221514201163"
FROM "commits"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
WHERE (branches.name = 'next')
  AND (repositories.name = 'Madek')
  AND (to_tsvector('english', "commits"."id"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."tree_id"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."author_name"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."author_email"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."committer_name"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."committer_email"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."subject"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text)
       OR to_tsvector('english', "commits"."body"::text) @@ plainto_tsquery('english', 'Permissions\ Franco'::text))
ORDER BY "commits"."committer_date" DESC,
         "rank47121221514201163" DESC,
         "commits"."committer_date" DESC,
         "commits"."created_at" DESC,
         "commits"."id" ASC LIMIT 25
OFFSET 00;

EXPLAIN ANALYZE SELECT DISTINCT commits.*
FROM commits,
     branches AS h_branches
INNER JOIN repositories AS h_repositories ON h_repositories.id = h_branches.repository_id
WHERE ( (h_branches.current_commit_id IN
           (SELECT d_commits.id
            FROM commits AS d_commits
            INNER JOIN "branches" AS d_branches ON "d_branches"."current_commit_id" = "d_commits"."id"
            WHERE (id IN (WITH RECURSIVE descendants AS
                            (SELECT *
                             FROM commits AS s_commits
                             WHERE ID = commits.id
                             UNION SELECT r_commits.*
                             FROM descendants,
                                  commit_arcs,
                                  commits AS r_commits
                             WHERE TRUE
                               AND descendants.id = commit_arcs.parent_id
                               AND commit_arcs.child_id = r_commits.id)
                          SELECT id
                          FROM descendants)) )))
ORDER BY "commits"."committer_date" DESC,
         "commits"."created_at" DESC,
         "commits"."id" ASC LIMIT 25
OFFSET 0;

-- EXAMPLE QUERY: branch joined with heads
SELECT  commits.id, h_branches.name
FROM commits, branches as h_branches 
WHERE (h_branches.current_commit_id IN
         (SELECT d_commits.id
          FROM commits AS d_commits
          INNER JOIN "branches" AS d_branches ON "d_branches"."current_commit_id" = "d_commits"."id"
          WHERE (id IN (WITH RECURSIVE descendants AS
                          (SELECT *
                           FROM commits as s_commits
                           WHERE ID = commits.id 
                           UNION SELECT r_commits.*
                           FROM descendants,
                                commit_arcs,
                                commits AS r_commits
                           WHERE TRUE
                             AND descendants.id = commit_arcs.parent_id
                             AND commit_arcs.child_id = r_commits.id)
                        SELECT id
                        FROM descendants))
          ))
ORDER BY commits.id 
;



SELECT commits.* FROM commits;


SELECT "commits".*
FROM "commits"
INNER JOIN "branches" ON "branches"."current_commit_id" = "commits"."id"
WHERE (id IN ( WITH RECURSIVE descendants AS
                ( SELECT *
                 FROM commits
                 WHERE ID IN
                     (SELECT id
                      FROM "commits"
                      WHERE (id LIKE '3c1bdc8%')
                      ORDER BY "commits"."created_at" DESC, "commits"."id" ASC)
                 UNION SELECT commits.*
                 FROM descendants,
                      commit_arcs,
                      commits
                 WHERE TRUE
                   AND descendants.id = commit_arcs.parent_id
                   AND commit_arcs.child_id = commits.id )
              SELECT id
              FROM descendants))
ORDER BY "commits"."created_at" DESC,
         "commits"."id" ASC
        ;



SELECT date_part('epoch', SUM(finished_at - started_at)) AS total_duration
FROM "trials"
INNER JOIN "tasks" ON "tasks"."id" = "trials"."task_id"
INNER JOIN "jobs" ON "jobs"."specification_id" = "tasks"."specification_id"
AND "jobs"."tree_id" = "tasks"."tree_id"
WHERE (jobs.tree_id = 'a0c367830344212ef0878d2dfb2b419fd4248a6c')
  AND (jobs.specification_id = 'a019b15a-2609-5a56-af25-e80bdbf9c2c0')
  AND ("trials"."started_at" IS NOT NULL)
  AND ("trials"."finished_at" IS NOT NULL)
GROUP BY jobs.tree_id
;

SELECT "executors_with_load".*
FROM executors_with_load,
     tasks
WHERE "executors_with_load"."enabled" = 't'
  AND (tasks.id = '2c3a46fd-ba30-4916-ba6f-5f1526256729')
  AND (tasks.environments <@ executors_with_load.environments)
  AND (last_ping_at > (now() - interval '3 Minutes'))
  AND (executors_with_load.relative_load < 1)
ORDER BY "executors_with_load"."relative_load" ASC,
         "executors_with_load".name ASC ;

SELECT * FROM COMMITS WHERE ID = '643cebb11bc062419bd0d9ab8eeb0a03d0392d26'

WITH RECURSIVE ancestors AS
(
  SELECT * FROM commits WHERE ID = '643cebb11bc062419bd0d9ab8eeb0a03d0392d26'
  UNION 
  SELECT commits.* 
    FROM ancestors, commit_arcs, commits
    WHERE TRUE
    AND ancestors.id = commit_arcs.child_id
    AND commit_arcs.parent_id = commits.id
)
SELECT * FROM ancestors

