#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff c4e40d991c28be51de9ac560ce895ac7f9b14924
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git checkout c4e40d991c28be51de9ac560ce895ac7f9b14924 xarray/tests/test_dataset.py
git apply -v - <<'EOF_114329324912'
diff --git a/xarray/tests/test_dataset.py b/xarray/tests/test_dataset.py
index 83dc799..983aeab 100644
--- a/xarray/tests/test_dataset.py
+++ b/xarray/tests/test_dataset.py
@@ -2995,6 +2995,77 @@ class TestDataset:
         assert isinstance(actual.variables["x"], Variable)
         assert actual.xindexes["y"].equals(expected.xindexes["y"])
 
+    def test_swap_dims_does_not_modify_original(self) -> None:
+        """Test that swap_dims does not modify the original dataset.
+        
+        This is a regression test for:
+        https://github.com/pydata/xarray/issues/...
+        """
+        import numpy as np
+        import xarray as xr
+        
+        nz = 11
+        ds = xr.Dataset(
+            data_vars={
+                "y": ("z", np.random.rand(nz)),
+                "lev": ("z", np.arange(nz) * 10),
+            },
+        )
+        
+        # Create ds2 by swapping, renaming, and resetting
+        ds2 = (
+            ds.swap_dims(z="lev")
+            .rename_dims(lev="z")
+            .reset_index("lev")
+            .reset_coords()
+        )
+        
+        # Store the original dims of ds2['lev'] before swap_dims
+        original_lev_dims = ds2["lev"].dims
+        
+        # Apply swap_dims to ds2
+        ds2_swapped = ds2.swap_dims(z="lev")
+        
+        # Check that ds2['lev'].dims has not been modified
+        assert ds2["lev"].dims == original_lev_dims, (
+            f"swap_dims modified original object: "
+            f"expected dims {original_lev_dims}, got {ds2['lev'].dims}"
+        )
+        
+        # Also verify the swapped version has the correct dims
+        assert ds2_swapped["lev"].dims == ("lev",), (
+            f"swapped version has incorrect dims: "
+            f"expected ('lev',), got {ds2_swapped['lev'].dims}"
+        )
+
+    def test_swap_dims_does_not_modify_original_simple(self) -> None:
+        """Test that swap_dims does not modify original dataset - simple case."""
+        import numpy as np
+        import xarray as xr
+        
+        # Create a simple dataset
+        ds = xr.Dataset(
+            data_vars={
+                "data": ("x", [1, 2, 3]),
+                "coord_var": ("x", [10, 20, 30]),
+            },
+        )
+        
+        # Store original dims
+        original_coord_var_dims = ds["coord_var"].dims
+        original_data_dims = ds["data"].dims
+        
+        # Swap dims
+        ds_swapped = ds.swap_dims(x="coord_var")
+        
+        # Verify original is not modified
+        assert ds["coord_var"].dims == original_coord_var_dims
+        assert ds["data"].dims == original_data_dims
+        
+        # Verify swapped version is correct
+        assert ds_swapped["coord_var"].dims == ("coord_var",)
+        assert ds_swapped["data"].dims == ("coord_var",)
+
     def test_expand_dims_error(self) -> None:
         original = Dataset(
             {

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA xarray/tests/test_dataset.py
: '>>>>> End Test Output'
git checkout c4e40d991c28be51de9ac560ce895ac7f9b14924 xarray/tests/test_dataset.py
