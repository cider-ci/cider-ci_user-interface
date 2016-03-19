
--#############################################################################

SELECT id FROM commits WHERE tree_id = 'df7ca91946dd93944cbd5a2371c20b4f1360c27a';

SELECT submodule_commit_id FROM submodules WHERE commit_id = '5f685b7b58557226ffa19589083448e66f487c08';

WITH RECURSIVE recursive_commits(id) AS
  ( SELECT id
   FROM commits
   WHERE tree_id = 'df7ca91946dd93944cbd5a2371c20b4f1360c27a'
   UNION ALL SELECT submodule_commit_id
   FROM submodules,
        recursive_commits
   WHERE submodules.commit_id = recursive_commits.id )
SELECT id
FROM recursive_commits;





WITH RECURSIVE recursive_commits(id) AS (
    SELECT id FROM commits WHERE tree_id = 'df7ca91946dd93944cbd5a2371c20b4f1360c27a'
  -- UNION ALL
  --  SELECT p.sub_part, p.part, p.quantity
  --  FROM included_parts pr, parts p
  --  WHERE p.part = pr.sub_part
  )
SELECT id FROM recursive_commits;




SELECT "commits".*
FROM "commits"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
WHERE "repositories"."name" = 'Cider-CI'
;

SELECT "commits".id
FROM "commits"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
INNER JOIN "branches" "head_of_branches_commits" ON "head_of_branches_commits"."current_commit_id" = "commits"."id"
WHERE "repositories"."name" = 'Cider-CI'
;


(SELECT cs0.id
   FROM commits AS cs0
   JOIN branches_commits AS bcs0 ON bcs0.commit_id = cs0.id
   JOIN branches AS bs0 ON bcs0.branch_id = bs0.id
   WHERE bs0.id = '385efc0d-6199-4f0b-8acf-84b3354f7e60'::UUID
     AND cs0.depth > 50)

UNION
  (SELECT cs1.id, bs1.name
   FROM commits AS cs1
   JOIN branches_commits AS bcs1 ON bcs1.commit_id = cs1.id
   JOIN branches AS bs1 ON bcs1.branch_id = bs1.id
   WHERE bs1.id = '64d6be89-264e-4d2c-aa6e-f4ae0d836e0f'::UUID
     AND cs1.depth > 50)
UNION
  (SELECT cs2.id
   FROM commits AS cs2
   JOIN branches_commits AS bcs2 ON bcs2.commit_id = cs2.id
   JOIN branches AS bs2 ON bcs2.branch_id = bs2.id
   WHERE bs2.id = '64d6be89-264e-4d2c-aa6e-f4ae0d836e0f'::UUID
     AND cs2.depth > 59)
 ;



SELECT DISTINCT commits.id AS id,
                commits.depth AS depth,
                head_of_branches_commits.id AS branch_id,
                branches.name
FROM "commits"
INNER JOIN "branches_commits" ON "branches_commits"."commit_id" = "commits"."id"
INNER JOIN "branches" ON "branches"."id" = "branches_commits"."branch_id"
INNER JOIN "repositories" ON "repositories"."id" = "branches"."repository_id"
INNER JOIN "branches" "head_of_branches_commits" ON "head_of_branches_commits"."current_commit_id" = "commits"."id"
WHERE "repositories"."name" = 'Cider-CI'
;
