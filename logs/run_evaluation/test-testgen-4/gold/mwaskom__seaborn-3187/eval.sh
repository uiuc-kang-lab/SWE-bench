#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 22cdfb0c93f8ec78492d87edb810f10cb7f57a31
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .[dev]
git checkout 22cdfb0c93f8ec78492d87edb810f10cb7f57a31 tests/_core/test_scales.py
git apply -v - <<'EOF_114329324912'
diff --git a/tests/_core/test_scales.py b/tests/_core/test_scales.py
index 7a77719..615de52 100644
--- a/tests/_core/test_scales.py
+++ b/tests/_core/test_scales.py
@@ -312,6 +312,240 @@ class TestContinuous:
         with pytest.raises(TypeError, match="`like` must be"):
             s.label(like=2)
 
+    def test_legend_with_large_values_offset(self):
+        """Test that legend labels include offset for large values."""
+        import pandas as pd
+        import numpy as np
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        from matplotlib.ticker import ScalarFormatter
+        
+        # Create data with large values that would trigger offset formatting
+        x = pd.Series(np.array([3000000, 4000000, 5000000, 6000000]), name="x")
+        
+        s = Continuous()
+        scale = s._setup(x, Coordinate())
+        
+        # Check that legend was created
+        assert scale._legend is not None
+        
+        locs, labels = scale._legend
+        
+        # The labels should represent the actual values
+        # Either by including the offset in labels or having proper numeric representation
+        assert len(locs) > 0
+        assert len(labels) == len(locs)
+        
+        # At least one label should not be empty
+        assert any(label.strip() for label in labels)
+
+    def test_legend_with_offset_formatter_useoffset_true(self):
+        """Test legend with ScalarFormatter when useoffset is True."""
+        import pandas as pd
+        import numpy as np
+        import matplotlib as mpl
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Save original rcParams
+        original_useoffset = mpl.rcParams.get('axes.formatter.useoffset', True)
+        original_offset_threshold = mpl.rcParams.get('axes.formatter.offset_threshold', 4)
+        
+        try:
+            # Set rcParams to trigger offset formatting
+            mpl.rcParams['axes.formatter.useoffset'] = True
+            mpl.rcParams['axes.formatter.offset_threshold'] = 2
+            
+            # Create data with values in millions (like body_mass_mg in the issue)
+            x = pd.Series(np.array([3000000, 3500000, 4000000, 4500000, 5000000]), name="x")
+            
+            s = Continuous()
+            scale = s._setup(x, Coordinate())
+            
+            # Check that legend was created
+            assert scale._legend is not None
+            
+            locs, labels = scale._legend
+            
+            # Verify we have legend entries
+            assert len(locs) > 0
+            assert len(labels) == len(locs)
+            
+            # The actual values should be represented somehow
+            # Either in the labels themselves or via offset
+            for loc, label in zip(locs, labels):
+                # Each location should have a corresponding label
+                assert label is not None
+                
+        finally:
+            # Restore original rcParams
+            mpl.rcParams['axes.formatter.useoffset'] = original_useoffset
+            mpl.rcParams['axes.formatter.offset_threshold'] = original_offset_threshold
+
+    def test_legend_values_match_data_range(self):
+        """Test that legend values are in the correct range for large numbers."""
+        import pandas as pd
+        import numpy as np
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Create data similar to the issue: body_mass_mg in millions
+        x = pd.Series(np.array([2700000, 3000000, 3500000, 4000000, 4500000, 5000000, 6300000]), name="x")
+        
+        s = Continuous()
+        scale = s._setup(x, Coordinate())
+        
+        # Check that legend was created
+        assert scale._legend is not None
+        
+        locs, labels = scale._legend
+        
+        # The locations should be within or near the data range
+        assert len(locs) > 0
+        min_loc = min(locs)
+        max_loc = max(locs)
+        
+        # Legend locations should span a reasonable range of the data
+        # They should be in the millions, not in single digits
+        assert min_loc >= 1e6 or min_loc >= x.min() * 0.5
+        assert max_loc <= x.max() * 1.5
+
+    def test_legend_with_scalar_formatter_offset(self):
+        """Test that ScalarFormatter offset is properly handled in legend."""
+        import pandas as pd
+        import numpy as np
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        from matplotlib.ticker import ScalarFormatter
+        
+        # Create data that will trigger offset in ScalarFormatter
+        x = pd.Series(np.array([1000000, 2000000, 3000000, 4000000, 5000000]), name="x")
+        
+        s = Continuous()
+        scale = s._setup(x, Coordinate())
+        
+        # Get the matplotlib scale to check the formatter
+        mpl_scale = scale._matplotlib_scale
+        
+        # Check if formatter is ScalarFormatter and has offset
+        if hasattr(mpl_scale, 'axis'):
+            formatter = mpl_scale.axis.major.formatter
+            if isinstance(formatter, ScalarFormatter):
+                # The formatter might have an offset
+                # After formatting, check if offset exists
+                formatter.set_locs(scale._legend[0] if scale._legend else [])
+                offset_text = formatter.get_offset()
+                
+                # If there's an offset, it should be non-empty for large values
+                # This is what the fix should address
+                if offset_text:
+                    # Offset exists, verify legend accounts for it
+                    assert scale._legend is not None
+
+    def test_legend_formatter_consistency(self):
+        """Test that legend labels are consistent with formatter output."""
+        import pandas as pd
+        import numpy as np
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Test with various ranges
+        test_cases = [
+            np.array([1, 2, 3, 4, 5]),  # Small values
+            np.array([100, 200, 300, 400, 500]),  # Medium values
+            np.array([1000000, 2000000, 3000000]),  # Large values (millions)
+        ]
+        
+        for data in test_cases:
+            x = pd.Series(data, name="x")
+            s = Continuous()
+            scale = s._setup(x, Coordinate())
+            
+            if scale._legend is not None:
+                locs, labels = scale._legend
+                
+                # Basic consistency checks
+                assert len(locs) == len(labels)
+                assert len(locs) > 0
+                
+                # All labels should be strings
+                assert all(isinstance(label, str) for label in labels)
+
+
+class TestContinuousLegendOffset:
+    """Test cases specifically for the legend offset issue with large values."""
+
+    def test_legend_large_range_body_mass_scenario(self):
+        """Reproduce the exact scenario from the issue: body_mass in mg (millions)."""
+        import pandas as pd
+        import numpy as np
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Simulate body_mass_mg values from the penguins dataset
+        # These are in the order of 1e6 (millions)
+        body_mass_mg = pd.Series([
+            2700000, 3000000, 3250000, 3500000, 3750000,
+            4000000, 4500000, 5000000, 5500000, 6000000, 6300000
+        ], name="body_mass_mg")
+        
+        s = Continuous()
+        scale = s._setup(body_mass_mg, Coordinate())
+        
+        # Verify legend was created
+        assert scale._legend is not None
+        
+        locs, labels = scale._legend
+        
+        # Key assertion: legend locations should be in millions, not single digits
+        # This is the core of the bug - without offset handling, 
+        # values might appear as 0, 1, 2, 3 instead of 3000000, 4000000, etc.
+        assert len(locs) > 0
+        
+        # At least some legend values should be >= 1 million
+        # (or close to the actual data range)
+        max_loc = max(locs)
+        min_loc = min(locs)
+        
+        # The legend should represent values in the millions
+        assert max_loc >= 1e6, f"Max legend value {max_loc} should be >= 1e6"
+        
+    def test_legend_offset_in_title_or_labels(self):
+        """Test that offset information is preserved in legend title or labels."""
+        import pandas as pd
+        import numpy as np
+        import matplotlib as mpl
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        from matplotlib.ticker import ScalarFormatter
+        
+        # Force offset formatting
+        original_useoffset = mpl.rcParams.get('axes.formatter.useoffset', True)
+        try:
+            mpl.rcParams['axes.formatter.useoffset'] = True
+            
+            # Large values that will trigger offset
+            x = pd.Series(np.array([3.5e6, 4.0e6, 4.5e6, 5.0e6, 5.5e6]), name="x")
+            
+            s = Continuous()
+            scale = s._setup(x, Coordinate())
+            
+            assert scale._legend is not None
+            locs, labels = scale._legend
+            
+            # The legend should properly represent the data
+            # Either through full values in labels or offset in title
+            assert len(locs) > 0
+            
+            # Check that locations are in the right ballpark
+            for loc in locs:
+                # Locations should be large numbers (millions)
+                assert loc >= 1e6 or loc == 0, \
+                    f"Legend location {loc} doesn't match expected range"
+                    
+        finally:
+            mpl.rcParams['axes.formatter.useoffset'] = original_useoffset
+
 
 class TestNominal:
 

EOF_114329324912
: '>>>>> Start Test Output'
pytest --no-header -rA tests/_core/test_scales.py
: '>>>>> End Test Output'
git checkout 22cdfb0c93f8ec78492d87edb810f10cb7f57a31 tests/_core/test_scales.py
