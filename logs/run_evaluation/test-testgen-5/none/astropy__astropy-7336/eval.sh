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
index 9c351c2..07f7300 100644
--- a/astropy/units/tests/py3_test_quantity_annotations.py
+++ b/astropy/units/tests/py3_test_quantity_annotations.py
@@ -284,4 +284,117 @@ def test_return_annotation():
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
+    import astropy.units as u
+    
+    class TestClass(object):
+        @u.quantity_input
+        def __init__(self, voltage: u.V) -> None:
+            self.voltage = voltage
+    
+    # This should not raise an AttributeError
+    obj = TestClass(1.0 * u.V)
+    assert obj.voltage.unit is u.V
+    """
+    return src
+
+
+@py3only
+def test_constructor_without_return_annotation():
+    """Test that quantity_input works with constructors without return annotation."""
+    src = """
+    import astropy.units as u
+    
+    class TestClass(object):
+        @u.quantity_input
+        def __init__(self, voltage: u.V):
+            self.voltage = voltage
+    
+    obj = TestClass(1.0 * u.V)
+    assert obj.voltage.unit is u.V
+    """
+    return src
+
+
+@py3only
+def test_method_with_none_return_annotation():
+    """Test that quantity_input works with methods that have -> None annotation."""
+    src = """
+    import astropy.units as u
+    
+    class TestClass(object):
+        def __init__(self):
+            self.voltage = None
+        
+        @u.quantity_input
+        def set_voltage(self, voltage: u.V) -> None:
+            self.voltage = voltage
+    
+    obj = TestClass()
+    result = obj.set_voltage(1.0 * u.V)
+    assert result is None
+    assert obj.voltage.unit is u.V
+    """
+    return src
+
+
+@py3only
+def test_function_with_none_return_annotation():
+    """Test that quantity_input works with functions that have -> None annotation and return None."""
+    src = """
+    import astropy.units as u
+    
+    @u.quantity_input
+    def process_voltage(voltage: u.V) -> None:
+        # Function that processes but doesn't return anything
+        pass
+    
+    result = process_voltage(1.0 * u.V)
+    assert result is None
+    """
+    return src
+
+
+@py3only
+def test_constructor_with_multiple_params_and_none_return():
+    """Test constructor with multiple parameters and -> None annotation."""
+    src = """
+    import astropy.units as u
+    
+    class TestClass(object):
+        @u.quantity_input
+        def __init__(self, voltage: u.V, current: u.A, resistance: u.ohm = 1.0 * u.ohm) -> None:
+            self.voltage = voltage
+            self.current = current
+            self.resistance = resistance
+    
+    obj = TestClass(5.0 * u.V, 2.0 * u.A)
+    assert obj.voltage.unit is u.V
+    assert obj.current.unit is u.A
+    assert obj.resistance.unit is u.ohm
+    """
+    return src
+
+
+@py3only
+def test_function_returning_none_explicitly():
+    """Test function that explicitly returns None with -> None annotation."""
+    src = """
+    import astropy.units as u
+    
+    @u.quantity_input
+    def process_and_return_none(voltage: u.V) -> None:
+        # Do some processing
+        _ = voltage.to(u.mV)
+        return None
+    
+    result = process_and_return_none(1.0 * u.V)
+    assert result is None
+    """
+    return src

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA -vv -o console_output_style=classic --tb=no astropy/units/tests/py3_test_quantity_annotations.py
: '>>>>> End Test Output'
git checkout 732d89c2940156bdc0e200bb36dc38b5e424bcba astropy/units/tests/py3_test_quantity_annotations.py
