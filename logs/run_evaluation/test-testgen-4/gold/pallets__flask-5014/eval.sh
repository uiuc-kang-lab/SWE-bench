#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 7ee9ceb71e868944a46e1ff00b506772a53a4f1d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git checkout 7ee9ceb71e868944a46e1ff00b506772a53a4f1d tests/test_blueprints.py
git apply -v - <<'EOF_114329324912'
diff --git a/tests/test_blueprints.py b/tests/test_blueprints.py
index 94a27b3..db9a6b5 100644
--- a/tests/test_blueprints.py
+++ b/tests/test_blueprints.py
@@ -993,6 +993,18 @@ def test_child_and_parent_subdomain(app, client) -> None:
     assert response.status_code == 404
 
 
+def test_blueprint_name_with_dot_raises_error() -> None:
+    """Test that creating a Blueprint with a dot in the name raises ValueError."""
+    import flask
+    import pytest
+    
+    with pytest.raises(ValueError, match="may not contain a dot"):
+        flask.Blueprint("bp.name", __name__)
+    
+    with pytest.raises(ValueError, match="may not contain a dot"):
+        flask.Blueprint("my.blueprint.name", __name__)
+
+
 def test_unique_blueprint_names(app, client) -> None:
     bp = flask.Blueprint("bp", __name__)
     bp2 = flask.Blueprint("bp", __name__)
@@ -1016,6 +1028,72 @@ def test_self_registration(app, client) -> None:
         bp.register_blueprint(bp)
 
 
+def test_empty_name_raises_error() -> None:
+    """Test that creating a Blueprint with an empty name raises ValueError."""
+    import flask
+    import pytest
+    
+    with pytest.raises(ValueError):
+        flask.Blueprint("", __name__)
+
+
+def test_empty_name_with_whitespace_raises_error() -> None:
+    """Test that creating a Blueprint with whitespace-only name raises ValueError."""
+    import flask
+    import pytest
+    
+    # Test with spaces
+    with pytest.raises(ValueError):
+        flask.Blueprint("   ", __name__)
+    
+    # Test with tabs
+    with pytest.raises(ValueError):
+        flask.Blueprint("\t", __name__)
+    
+    # Test with newlines
+    with pytest.raises(ValueError):
+        flask.Blueprint("\n", __name__)
+
+
+def test_none_name_raises_error() -> None:
+    """Test that creating a Blueprint with None as name raises appropriate error."""
+    import flask
+    import pytest
+    
+    # This should raise either ValueError or TypeError
+    with pytest.raises((ValueError, TypeError)):
+        flask.Blueprint(None, __name__)
+
+
+def test_valid_blueprint_names() -> None:
+    """Test that valid blueprint names work correctly."""
+    import flask
+    
+    # These should all work without raising errors
+    bp1 = flask.Blueprint("valid_name", __name__)
+    assert bp1.name == "valid_name"
+    
+    bp2 = flask.Blueprint("valid-name", __name__)
+    assert bp2.name == "valid-name"
+    
+    bp3 = flask.Blueprint("valid_name_123", __name__)
+    assert bp3.name == "valid_name_123"
+    
+    bp4 = flask.Blueprint("a", __name__)
+    assert bp4.name == "a"
+
+
+def test_empty_name_registration_prevented(app) -> None:
+    """Test that blueprints with empty names cannot be registered."""
+    import flask
+    import pytest
+    
+    # First, verify that creating a blueprint with empty name raises ValueError
+    with pytest.raises(ValueError):
+        bp = flask.Blueprint("", __name__)
+        app.register_blueprint(bp)
+
+
 def test_blueprint_renaming(app, client) -> None:
     bp = flask.Blueprint("bp", __name__)
     bp2 = flask.Blueprint("bp2", __name__)

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA tests/test_blueprints.py
: '>>>>> End Test Output'
git checkout 7ee9ceb71e868944a46e1ff00b506772a53a4f1d tests/test_blueprints.py
