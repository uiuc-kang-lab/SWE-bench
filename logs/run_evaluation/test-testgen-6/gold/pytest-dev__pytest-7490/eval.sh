#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 7f7a36478abe7dd1fa993b115d22606aa0e35e88
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git checkout 7f7a36478abe7dd1fa993b115d22606aa0e35e88 testing/test_skipping.py
git apply -v - <<'EOF_114329324912'
diff --git a/testing/test_skipping.py b/testing/test_skipping.py
index 50a5826..92fedca 100644
--- a/testing/test_skipping.py
+++ b/testing/test_skipping.py
@@ -425,6 +425,114 @@ class TestXFail:
         result = testdir.runpytest(p)
         result.stdout.fnmatch_lines(["*1 xfailed*"])
 
+    def test_dynamic_xfail_with_add_marker(self, testdir):
+        """Test that dynamically adding xfail marker with add_marker works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_test(request):
+                mark = pytest.mark.xfail(reason="xfail")
+                request.node.add_marker(mark)
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_test*", "*xfail*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_with_add_marker_passing(self, testdir):
+        """Test that dynamically adding xfail marker works with passing test."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_passing(request):
+                mark = pytest.mark.xfail(reason="expected to fail")
+                request.node.add_marker(mark)
+                assert 1
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XPASS*test_xfail_passing*"])
+
+    def test_dynamic_xfail_with_add_marker_strict(self, testdir):
+        """Test that dynamically adding strict xfail marker works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_strict(request):
+                mark = pytest.mark.xfail(reason="strict xfail", strict=True)
+                request.node.add_marker(mark)
+                assert 1
+        """
+        )
+        result = testdir.runpytest(p)
+        result.stdout.fnmatch_lines(["*1 failed*"])
+
+    def test_dynamic_xfail_with_add_marker_run_false(self, testdir):
+        """Test that dynamically adding xfail marker with run=False works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_no_run(request):
+                mark = pytest.mark.xfail(reason="should not run", run=False)
+                request.node.add_marker(mark)
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rxX")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_no_run*", "*NOTRUN*"])
+
+    def test_dynamic_xfail_with_add_marker_in_test_body(self, testdir):
+        """Test that adding xfail marker in test body (not fixture) works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_dynamic_in_body(request):
+                # Add marker dynamically in test body
+                request.node.add_marker(pytest.mark.xfail(reason="dynamic xfail"))
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_dynamic_in_body*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_with_add_marker_raises(self, testdir):
+        """Test that dynamically adding xfail marker with raises works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_with_raises(request):
+                mark = pytest.mark.xfail(reason="expected TypeError", raises=TypeError)
+                request.node.add_marker(mark)
+                raise TypeError("expected error")
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_with_raises*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_with_add_marker_wrong_exception(self, testdir):
+        """Test that dynamically adding xfail marker with wrong exception fails."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_wrong_exception(request):
+                mark = pytest.mark.xfail(reason="expected TypeError", raises=TypeError)
+                request.node.add_marker(mark)
+                raise ValueError("wrong error")
+        """
+        )
+        result = testdir.runpytest(p)
+        result.stdout.fnmatch_lines(["*1 failed*"])
+
     @pytest.mark.parametrize(
         "expected, actual, matchline",
         [

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA testing/test_skipping.py
: '>>>>> End Test Output'
git checkout 7f7a36478abe7dd1fa993b115d22606aa0e35e88 testing/test_skipping.py
