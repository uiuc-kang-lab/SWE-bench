#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 3c88e520da24ae6f736929a750876e7654accc3d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install .
git checkout 3c88e520da24ae6f736929a750876e7654accc3d 
git apply -v - <<'EOF_114329324912'

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA
: '>>>>> End Test Output'
git checkout 3c88e520da24ae6f736929a750876e7654accc3d 
