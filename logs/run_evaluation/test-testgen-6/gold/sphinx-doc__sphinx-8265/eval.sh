#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff b428cd2404675475a5c3dc2a2b0790ba57676202
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test]
git checkout b428cd2404675475a5c3dc2a2b0790ba57676202 tests/test_util_inspect.py
git apply -v - <<'EOF_114329324912'
diff --git a/tests/test_util_inspect.py b/tests/test_util_inspect.py
index be92c21..21ed221 100644
--- a/tests/test_util_inspect.py
+++ b/tests/test_util_inspect.py
@@ -309,6 +309,34 @@ def test_signature_from_str_default_values():
     assert sig.parameters['m'].default == 'foo.bar.CONSTANT'
 
 
+def test_signature_from_str_tuple_default():
+    # Test for issue: docstring default arg is broken
+    # Tuple default values should be preserved correctly
+    signature = '(color=(1, 1, 1), width=5)'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['color'].default == '(1, 1, 1)'
+    assert sig.parameters['width'].default == '5'
+
+
+def test_signature_from_str_complex_tuple_defaults():
+    # Test various tuple default values
+    signature = '(a=(1, 2), b=(1.0, 2.0, 3.0), c=("x", "y"), d=(True, False), e=())'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['a'].default == '(1, 2)'
+    assert sig.parameters['b'].default == '(1.0, 2.0, 3.0)'
+    assert sig.parameters['c'].default == '("x", "y")'
+    assert sig.parameters['d'].default == '(True, False)'
+    assert sig.parameters['e'].default == '()'
+
+
+def test_signature_from_str_nested_tuple_defaults():
+    # Test nested tuples
+    signature = '(a=((1, 2), (3, 4)), b=(1, (2, 3)))'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['a'].default == '((1, 2), (3, 4))'
+    assert sig.parameters['b'].default == '(1, (2, 3))'
+
+
 def test_signature_from_str_annotations():
     signature = '(a: int, *args: bytes, b: str = "blah", **kwargs: float) -> None'
     sig = inspect.signature_from_str(signature)

EOF_114329324912
: '>>>>> Start Test Output'
tox --current-env -epy39 -v -- tests/test_util_inspect.py
: '>>>>> End Test Output'
git checkout b428cd2404675475a5c3dc2a2b0790ba57676202 tests/test_util_inspect.py
