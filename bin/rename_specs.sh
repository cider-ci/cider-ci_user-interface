#!/usr/bin/env bash

egrep -R -l "pecification" . | xargs -o -I {} vim \
  "+%s/Specification/JobSpecification/gIc" \
  "+%s/specification/job_specification/gIc" \
  "+wq" {}

egrep -R -l "task_spec" .  | xargs -o -I {} vim "+%s/task_spec/task_specification/gIc" "+wq" {}

egrep -R -l "TaskSpec" . | xargs -o -I {} vim "+%s/TaskSpec/TaskSpecification/gIc" "+wq" {}
