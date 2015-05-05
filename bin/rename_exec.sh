#!/usr/bin/env bash

# egrep -R -l "xecution" .
egrep -R -l "xecution" . | xargs -o -I {} vim "+%s/Execution/Job/gI" "+%s/execution/job/gI" "+wq" {}
