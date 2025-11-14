#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 273a8b25620467c1e5686aa8d2a1dbb8c02c78d0
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git checkout 273a8b25620467c1e5686aa8d2a1dbb8c02c78d0 tests/lint/unittest_expand_modules.py
git apply -v - <<'EOF_114329324912'
diff --git a/tests/lint/unittest_expand_modules.py b/tests/lint/unittest_expand_modules.py
index d43a0d1..916d7fb 100644
--- a/tests/lint/unittest_expand_modules.py
+++ b/tests/lint/unittest_expand_modules.py
@@ -99,6 +99,31 @@ class TestExpandModules(CheckerTestCase):
 
     CHECKER_CLASS: type = Checker
 
+    def test_recursive_discovers_files(self):
+        """Test that _discover_files finds Python files recursively."""
+        import tempfile
+        import os
+        from pylint.lint.pylinter import PyLinter
+        
+        with tempfile.TemporaryDirectory() as tmpdir:
+            # Create nested structure
+            subdir = os.path.join(tmpdir, "subdir")
+            os.makedirs(subdir)
+            
+            file1 = os.path.join(tmpdir, "file1.py")
+            file2 = os.path.join(subdir, "file2.py")
+            
+            with open(file1, "w") as f:
+                f.write("# test\n")
+            with open(file2, "w") as f:
+                f.write("# test\n")
+            
+            # Test discovery
+            discovered = list(PyLinter._discover_files([tmpdir]))
+            
+            assert file1 in discovered
+            assert file2 in discovered
+
     @pytest.mark.parametrize(
         "files_or_modules,expected",
         [
@@ -154,4 +179,206 @@ class TestExpandModules(CheckerTestCase):
         )
         modules.sort(key=lambda d: d["name"])
         assert modules == expected
-        assert not errors
+        assert not errors
+
+    def test_expand_modules_with_ignore_list(self):
+        """Test that expand_modules respects ignore_list (--ignore option)."""
+        import tempfile
+        import os
+        from pylint.lint.expand_modules import expand_modules
+        
+        # Create a temporary directory structure
+        with tempfile.TemporaryDirectory() as tmpdir:
+            # Create .a directory with foo.py
+            ignore_dir = os.path.join(tmpdir, ".a")
+            os.makedirs(ignore_dir)
+            foo_path = os.path.join(ignore_dir, "foo.py")
+            with open(foo_path, "w") as f:
+                f.write("# import re\n")
+            
+            # Create bar.py in root
+            bar_path = os.path.join(tmpdir, "bar.py")
+            with open(bar_path, "w") as f:
+                f.write("# import re\n")
+            
+            # Test with ignore_list containing ".a"
+            ignore_list = [".a"]
+            ignore_list_re = []
+            ignore_list_paths_re = []
+            
+            modules, errors = expand_modules(
+                [tmpdir],
+                ignore_list,
+                ignore_list_re,
+                ignore_list_paths_re,
+            )
+            
+            # Should only find bar.py, not foo.py in .a directory
+            module_paths = [m["path"] for m in modules]
+            assert bar_path in module_paths
+            assert foo_path not in module_paths
+            assert not errors
+
+    def test_expand_modules_with_ignore_patterns(self):
+        """Test that expand_modules respects ignore_list_re (--ignore-patterns option)."""
+        import tempfile
+        import os
+        import re
+        from pylint.lint.expand_modules import expand_modules
+        
+        # Create a temporary directory structure
+        with tempfile.TemporaryDirectory() as tmpdir:
+            # Create .a directory with foo.py
+            ignore_dir = os.path.join(tmpdir, ".a")
+            os.makedirs(ignore_dir)
+            foo_path = os.path.join(ignore_dir, "foo.py")
+            with open(foo_path, "w") as f:
+                f.write("# import re\n")
+            
+            # Create bar.py in root
+            bar_path = os.path.join(tmpdir, "bar.py")
+            with open(bar_path, "w") as f:
+                f.write("# import re\n")
+            
+            # Test with ignore_list_re containing pattern for directories starting with "."
+            ignore_list = []
+            ignore_list_re = [re.compile(r"^\..*")]
+            ignore_list_paths_re = []
+            
+            modules, errors = expand_modules(
+                [tmpdir],
+                ignore_list,
+                ignore_list_re,
+                ignore_list_paths_re,
+            )
+            
+            # Should only find bar.py, not foo.py in .a directory
+            module_paths = [m["path"] for m in modules]
+            assert bar_path in module_paths
+            assert foo_path not in module_paths
+            assert not errors
+
+    def test_expand_modules_with_ignore_paths(self):
+        """Test that expand_modules respects ignore_list_paths_re (--ignore-paths option)."""
+        import tempfile
+        import os
+        import re
+        from pylint.lint.expand_modules import expand_modules
+        
+        # Create a temporary directory structure
+        with tempfile.TemporaryDirectory() as tmpdir:
+            # Create .a directory with foo.py
+            ignore_dir = os.path.join(tmpdir, ".a")
+            os.makedirs(ignore_dir)
+            foo_path = os.path.join(ignore_dir, "foo.py")
+            with open(foo_path, "w") as f:
+                f.write("# import re\n")
+            
+            # Create bar.py in root
+            bar_path = os.path.join(tmpdir, "bar.py")
+            with open(bar_path, "w") as f:
+                f.write("# import re\n")
+            
+            # Test with ignore_list_paths_re containing pattern for .a directory
+            ignore_list = []
+            ignore_list_re = []
+            ignore_list_paths_re = [re.compile(r".*\.a.*")]
+            
+            modules, errors = expand_modules(
+                [tmpdir],
+                ignore_list,
+                ignore_list_re,
+                ignore_list_paths_re,
+            )
+            
+            # Should only find bar.py, not foo.py in .a directory
+            module_paths = [m["path"] for m in modules]
+            assert bar_path in module_paths
+            assert foo_path not in module_paths
+            assert not errors
+
+    def test_expand_modules_recursive_with_ignore(self):
+        """Test that recursive discovery respects ignore settings."""
+        import tempfile
+        import os
+        import re
+        from pylint.lint.expand_modules import expand_modules
+        
+        # Create a temporary directory structure with nested directories
+        with tempfile.TemporaryDirectory() as tmpdir:
+            # Create .hidden directory with nested structure
+            hidden_dir = os.path.join(tmpdir, ".hidden")
+            os.makedirs(hidden_dir)
+            hidden_nested = os.path.join(hidden_dir, "nested")
+            os.makedirs(hidden_nested)
+            
+            hidden_file1 = os.path.join(hidden_dir, "file1.py")
+            with open(hidden_file1, "w") as f:
+                f.write("# test\n")
+            
+            hidden_file2 = os.path.join(hidden_nested, "file2.py")
+            with open(hidden_file2, "w") as f:
+                f.write("# test\n")
+            
+            # Create visible directory
+            visible_dir = os.path.join(tmpdir, "visible")
+            os.makedirs(visible_dir)
+            visible_file = os.path.join(visible_dir, "file3.py")
+            with open(visible_file, "w") as f:
+                f.write("# test\n")
+            
+            # Test with pattern to ignore directories starting with "."
+            ignore_list = []
+            ignore_list_re = [re.compile(r"^\..*")]
+            ignore_list_paths_re = []
+            
+            modules, errors = expand_modules(
+                [tmpdir],
+                ignore_list,
+                ignore_list_re,
+                ignore_list_paths_re,
+            )
+            
+            # Should only find visible_file, not any files in .hidden
+            module_paths = [m["path"] for m in modules]
+            assert visible_file in module_paths
+            assert hidden_file1 not in module_paths
+            assert hidden_file2 not in module_paths
+            assert not errors
+
+    def test_expand_modules_default_ignore_patterns(self):
+        """Test that default ignore patterns (^\.#) work correctly."""
+        import tempfile
+        import os
+        import re
+        from pylint.lint.expand_modules import expand_modules
+        
+        # Create a temporary directory structure
+        with tempfile.TemporaryDirectory() as tmpdir:
+            # Create a file matching emacs lock pattern
+            lock_file = os.path.join(tmpdir, ".#lockfile.py")
+            with open(lock_file, "w") as f:
+                f.write("# test\n")
+            
+            # Create a normal file
+            normal_file = os.path.join(tmpdir, "normal.py")
+            with open(normal_file, "w") as f:
+                f.write("# test\n")
+            
+            # Test with default ignore pattern
+            ignore_list = []
+            ignore_list_re = [re.compile(r"^\.#")]
+            ignore_list_paths_re = []
+            
+            modules, errors = expand_modules(
+                [tmpdir],
+                ignore_list,
+                ignore_list_re,
+                ignore_list_paths_re,
+            )
+            
+            # Should only find normal_file, not lock_file
+            module_paths = [m["path"] for m in modules]
+            assert normal_file in module_paths
+            assert lock_file not in module_paths
+            assert not errors

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA tests/lint/unittest_expand_modules.py
: '>>>>> End Test Output'
git checkout 273a8b25620467c1e5686aa8d2a1dbb8c02c78d0 tests/lint/unittest_expand_modules.py
