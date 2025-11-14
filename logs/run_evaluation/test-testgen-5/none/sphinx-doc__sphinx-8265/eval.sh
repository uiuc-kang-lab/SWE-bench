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
index be92c21..4cab98d 100644
--- a/tests/test_util_inspect.py
+++ b/tests/test_util_inspect.py
@@ -309,6 +309,59 @@ def test_signature_from_str_default_values():
     assert sig.parameters['m'].default == 'foo.bar.CONSTANT'
 
 
+def test_signature_from_str_tuple_default():
+    """Test that tuple default values are correctly parsed.
+    
+    This is a regression test for:
+    https://github.com/sphinx-doc/sphinx/issues/...
+    where color=(1, 1, 1) was being rendered as color=1, 1, 1
+    """
+    from sphinx.util import inspect
+    from inspect import Parameter
+    
+    # Test simple tuple default
+    signature = '(color=(1, 1, 1))'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['color'].default == '(1, 1, 1)'
+    
+    # Test tuple with multiple parameters
+    signature = '(lines, color=(1, 1, 1), width=5)'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['color'].default == '(1, 1, 1)'
+    assert sig.parameters['width'].default == '5'
+    
+    # Test empty tuple
+    signature = '(value=())'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['value'].default == '()'
+    
+    # Test nested tuple
+    signature = '(nested=((1, 2), (3, 4)))'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['nested'].default == '((1, 2), (3, 4))'
+    
+    # Test tuple with different types
+    signature = '(mixed=(1, "a", 2.0))'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['mixed'].default == '(1, \'a\', 2.0)'
+
+
+def test_signature_from_str_complex_defaults_with_tuples():
+    """Test complex signatures with tuple defaults and other parameters."""
+    from sphinx.util import inspect
+    from inspect import Parameter
+    
+    # Test the exact case from the issue
+    signature = '(lines, color=(1, 1, 1), width=5, label=None, name=None)'
+    sig = inspect.signature_from_str(signature)
+    assert list(sig.parameters.keys()) == ['lines', 'color', 'width', 'label', 'name']
+    assert sig.parameters['lines'].default == Parameter.empty
+    assert sig.parameters['color'].default == '(1, 1, 1)'
+    assert sig.parameters['width'].default == '5'
+    assert sig.parameters['label'].default == 'None'
+    assert sig.parameters['name'].default == 'None'
+
+
 def test_signature_from_str_annotations():
     signature = '(a: int, *args: bytes, b: str = "blah", **kwargs: float) -> None'
     sig = inspect.signature_from_str(signature)
@@ -317,6 +370,28 @@ def test_signature_from_str_annotations():
     assert sig.parameters['args'].annotation == "bytes"
     assert sig.parameters['b'].annotation == "str"
     assert sig.parameters['kwargs'].annotation == "float"
+
+
+def test_signature_from_str_tuple_defaults_with_annotations():
+    """Test tuple defaults work correctly with type annotations."""
+    from sphinx.util import inspect
+    from inspect import Parameter
+    
+    # Test tuple default with annotation
+    signature = '(color: tuple = (1, 1, 1))'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['color'].annotation == "tuple"
+    assert sig.parameters['color'].default == '(1, 1, 1)'
+    
+    # Test complex case with annotations and tuple defaults
+    signature = '(lines: list, color: tuple = (1, 1, 1), width: int = 5)'
+    sig = inspect.signature_from_str(signature)
+    assert sig.parameters['lines'].annotation == "list"
+    assert sig.parameters['lines'].default == Parameter.empty
+    assert sig.parameters['color'].annotation == "tuple"
+    assert sig.parameters['color'].default == '(1, 1, 1)'
+    assert sig.parameters['width'].annotation == "int"
+    assert sig.parameters['width'].default == '5'
     assert sig.return_annotation == 'None'
 
 

EOF_114329324912
: '>>>>> Start Test Output'
tox --current-env -epy39 -v -- tests/test_util_inspect.py
: '>>>>> End Test Output'
git checkout b428cd2404675475a5c3dc2a2b0790ba57676202 tests/test_util_inspect.py
