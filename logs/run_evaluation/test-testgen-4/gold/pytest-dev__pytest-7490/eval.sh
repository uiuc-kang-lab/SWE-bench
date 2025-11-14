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
index 50a5826..b7d462e 100644
--- a/testing/test_skipping.py
+++ b/testing/test_skipping.py
@@ -425,6 +425,201 @@ class TestXFail:
         result = testdir.runpytest(p)
         result.stdout.fnmatch_lines(["*1 xfailed*"])
 
+    def test_dynamic_xfail_in_test_body(self, testdir):
+        """Test that dynamically adding xfail marker in test body works."""
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
+    def test_dynamic_xfail_in_test_body_with_reason(self, testdir):
+        """Test that dynamically adding xfail marker with reason works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_with_reason(request):
+                mark = pytest.mark.xfail(reason="expected to fail")
+                request.node.add_marker(mark)
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_with_reason*"])
+        result.stdout.fnmatch_lines(["*expected to fail*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_in_test_body_strict(self, testdir):
+        """Test that dynamically adding strict xfail marker works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_strict_fail(request):
+                mark = pytest.mark.xfail(reason="strict xfail", strict=True)
+                request.node.add_marker(mark)
+                assert 0
+            
+            def test_xfail_strict_pass(request):
+                mark = pytest.mark.xfail(reason="strict xfail", strict=True)
+                request.node.add_marker(mark)
+                assert 1
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_strict_fail*"])
+        result.stdout.fnmatch_lines(["*FAILED*test_xfail_strict_pass*"])
+        assert result.ret == 1
+
+    def test_dynamic_xfail_in_test_body_run_false(self, testdir):
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
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_no_run*"])
+        result.stdout.fnmatch_lines(["*NOTRUN*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_in_test_body_with_raises(self, testdir):
+        """Test that dynamically adding xfail marker with raises works."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_with_correct_exception(request):
+                mark = pytest.mark.xfail(reason="expected TypeError", raises=TypeError)
+                request.node.add_marker(mark)
+                raise TypeError("expected")
+            
+            def test_xfail_with_wrong_exception(request):
+                mark = pytest.mark.xfail(reason="expected TypeError", raises=TypeError)
+                request.node.add_marker(mark)
+                raise ValueError("unexpected")
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_with_correct_exception*"])
+        result.stdout.fnmatch_lines(["*FAILED*test_xfail_with_wrong_exception*"])
+        assert result.ret == 1
+
+    def test_dynamic_xfail_in_test_body_passing(self, testdir):
+        """Test that dynamically adding xfail marker to passing test creates XPASS."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_but_passes(request):
+                mark = pytest.mark.xfail(reason="expected to fail but passes")
+                request.node.add_marker(mark)
+                assert 1
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XPASS*test_xfail_but_passes*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_using_add_marker(self, testdir):
+        """Test using add_marker method directly (alternative API)."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_add_marker_xfail(request):
+                request.node.add_marker(pytest.mark.xfail(reason="added via add_marker"))
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_add_marker_xfail*"])
+        result.stdout.fnmatch_lines(["*added via add_marker*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_multiple_markers(self, testdir):
+        """Test that adding multiple xfail markers works (last one wins)."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_multiple_xfail_markers(request):
+                request.node.add_marker(pytest.mark.xfail(reason="first"))
+                request.node.add_marker(pytest.mark.xfail(reason="second"))
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_multiple_xfail_markers*"])
+        # Should show one of the reasons
+        assert result.ret == 0
+
+    def test_dynamic_xfail_in_setup_and_test(self, testdir):
+        """Test that xfail can be added in both fixture and test body."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            @pytest.fixture
+            def setup_xfail(request):
+                # This should be overridden by the one in test body
+                request.node.add_marker(pytest.mark.xfail(reason="from fixture"))
+            
+            def test_override_xfail(request, setup_xfail):
+                request.node.add_marker(pytest.mark.xfail(reason="from test"))
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_override_xfail*"])
+        assert result.ret == 0
+
+    def test_dynamic_xfail_with_runxfail_option(self, testdir):
+        """Test that --runxfail option disables dynamic xfail."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_ignored(request):
+                request.node.add_marker(pytest.mark.xfail(reason="should be ignored"))
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "--runxfail")
+        result.stdout.fnmatch_lines(["*FAILED*test_xfail_ignored*"])
+        assert result.ret == 1
+
+    def test_dynamic_xfail_condition_true(self, testdir):
+        """Test dynamic xfail with condition parameter."""
+        p = testdir.makepyfile(
+            """
+            import pytest
+            
+            def test_xfail_condition_true(request):
+                request.node.add_marker(
+                    pytest.mark.xfail(condition=True, reason="condition is true")
+                )
+                assert 0
+        """
+        )
+        result = testdir.runpytest(p, "-rsx")
+        result.stdout.fnmatch_lines(["*XFAIL*test_xfail_condition_true*"])
+        assert result.ret == 0
+
     @pytest.mark.parametrize(
         "expected, actual, matchline",
         [

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA testing/test_skipping.py
: '>>>>> End Test Output'
git checkout 7f7a36478abe7dd1fa993b115d22606aa0e35e88 testing/test_skipping.py
