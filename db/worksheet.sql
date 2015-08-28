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
