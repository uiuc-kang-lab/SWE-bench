#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 732d89c2940156bdc0e200bb36dc38b5e424bcba
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[test] --verbose
git checkout 732d89c2940156bdc0e200bb36dc38b5e424bcba astropy/units/tests/py3_test_quantity_annotations.py
git apply -v - <<'EOF_114329324912'
diff --git a/astropy/units/tests/py3_test_quantity_annotations.py b/astropy/units/tests/py3_test_quantity_annotations.py
index 9c351c2..e801731 100644
--- a/astropy/units/tests/py3_test_quantity_annotations.py
+++ b/astropy/units/tests/py3_test_quantity_annotations.py
@@ -284,4 +284,89 @@ def test_return_annotation():
     solarx = myfunc_args(1*u.arcsec)
     assert solarx.unit is u.deg
     """
-    return src
+    return src
+
+
+@py3only
+def test_constructor_with_none_return_annotation():
+    """Test that quantity_input works with constructors that have -> None annotation."""
+    src = """
+    class TestClass(object):
+        @u.quantity_input
+        def __init__(self, voltage: u.V) -> None:
+            self.voltage = voltage
+    
+    obj = TestClass(1.0 * u.V)
+    assert obj.voltage.unit is u.V
+    assert obj.voltage.value == 1.0
+    """
+    return src
+
+
+@py3only
+def test_method_with_none_return_annotation():
+    """Test that quantity_input works with methods that have -> None annotation."""
+    src = """
+    class TestClass(object):
+        def __init__(self):
+            self.voltage = None
+        
+        @u.quantity_input
+        def set_voltage(self, voltage: u.V) -> None:
+            self.voltage = voltage
+    
+    obj = TestClass()
+    result = obj.set_voltage(5.0 * u.V)
+    assert result is None
+    assert obj.voltage.unit is u.V
+    assert obj.voltage.value == 5.0
+    """
+    return src
+
+
+@py3only
+def test_function_with_none_return_annotation():
+    """Test that quantity_input works with functions that have -> None annotation."""
+    src = """
+    @u.quantity_input
+    def process_voltage(voltage: u.V) -> None:
+        # Function that doesn't return anything
+        pass
+    
+    result = process_voltage(10.0 * u.V)
+    assert result is None
+    """
+    return src
+
+
+@py3only
+def test_constructor_without_return_annotation():
+    """Test that constructors without return annotation still work (regression test)."""
+    src = """
+    class TestClass(object):
+        @u.quantity_input
+        def __init__(self, voltage: u.V):
+            self.voltage = voltage
+    
+    obj = TestClass(2.0 * u.V)
+    assert obj.voltage.unit is u.V
+    assert obj.voltage.value == 2.0
+    """
+    return src
+
+
+@py3only
+def test_method_with_quantity_return_annotation():
+    """Test that methods with quantity return annotations still work (regression test)."""
+    src = """
+    class TestClass(object):
+        @u.quantity_input
+        def get_voltage(self, voltage: u.V) -> u.kV:
+            return voltage
+    
+    obj = TestClass()
+    result = obj.get_voltage(1000.0 * u.V)
+    assert result.unit is u.kV
+    assert result.value == 1.0
+    """
+    return src

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA -vv -o console_output_style=classic --tb=no astropy/units/tests/py3_test_quantity_annotations.py
: '>>>>> End Test Output'
git checkout 732d89c2940156bdc0e200bb36dc38b5e424bcba astropy/units/tests/py3_test_quantity_annotations.py
