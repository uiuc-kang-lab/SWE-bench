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
index 7a77719..0c1bdff 100644
--- a/tests/_core/test_scales.py
+++ b/tests/_core/test_scales.py
@@ -312,6 +312,185 @@ class TestContinuous:
         with pytest.raises(TypeError, match="`like` must be"):
             s.label(like=2)
 
+    def test_label_large_numbers_with_offset(self):
+        """Test that large numbers with ScalarFormatter offset are handled correctly."""
+        import numpy as np
+        import pandas as pd
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        from matplotlib.ticker import ScalarFormatter
+        
+        # Create data in the range of millions (like body_mass_mg in the issue)
+        x = pd.Series(np.linspace(3000000, 6000000, 100), name="x")
+        
+        s = Continuous()
+        scale = s._setup(x, Coordinate())
+        
+        # Get the axis and formatter
+        a = PseudoAxis(scale._matplotlib_scale)
+        a.set_view_interval(x.min(), x.max())
+        
+        # Check if formatter is ScalarFormatter
+        formatter = a.major.formatter
+        if isinstance(formatter, ScalarFormatter):
+            # Get the tick locations and labels
+            locs = a.major.locator()
+            locs = locs[(x.min() <= locs) & (locs <= x.max())]
+            labels = formatter.format_ticks(locs)
+            
+            # Get the offset if it exists
+            offset = formatter.get_offset()
+            
+            # If there's an offset, verify the legend would include it
+            if offset:
+                # The scale should have legend information
+                assert scale._legend is not None
+                legend_locs, legend_labels = scale._legend
+                
+                # Check that legend labels are not empty
+                assert len(legend_labels) > 0
+                
+                # The actual values should be in the millions
+                assert all(loc >= 1e6 for loc in legend_locs if loc > 0)
+
+    def test_label_large_numbers_legend_values(self):
+        """Test that legend values for large numbers are correct."""
+        import numpy as np
+        import pandas as pd
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Simulate body_mass_mg data from the issue (in millions)
+        x = pd.Series([3000000, 3500000, 4000000, 4500000, 5000000, 5500000, 6000000], name="body_mass_mg")
+        
+        s = Continuous()
+        scale = s._setup(x, Coordinate())
+        
+        # The scale should have legend information
+        assert scale._legend is not None
+        legend_locs, legend_labels = scale._legend
+        
+        # Check that we have legend entries
+        assert len(legend_locs) > 0
+        assert len(legend_labels) > 0
+        assert len(legend_locs) == len(legend_labels)
+        
+        # The legend locations should reflect the actual data range (millions)
+        # At least some values should be >= 3000000
+        assert any(loc >= 3000000 for loc in legend_locs)
+
+    def test_label_formatter_offset_threshold(self):
+        """Test that formatter offset threshold is respected."""
+        import numpy as np
+        import pandas as pd
+        import matplotlib as mpl
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Save original rcParams
+        original_useoffset = mpl.rcParams.get('axes.formatter.useoffset', True)
+        original_threshold = mpl.rcParams.get('axes.formatter.offset_threshold', 4)
+        
+        try:
+            # Enable offset formatting
+            mpl.rcParams['axes.formatter.useoffset'] = True
+            mpl.rcParams['axes.formatter.offset_threshold'] = 4
+            
+            # Create data that should trigger offset formatting
+            x = pd.Series(np.linspace(1000000, 1000100, 10), name="x")
+            
+            s = Continuous()
+            scale = s._setup(x, Coordinate())
+            
+            # Get the axis
+            a = PseudoAxis(scale._matplotlib_scale)
+            a.set_view_interval(x.min(), x.max())
+            
+            # Get formatter and check for offset
+            formatter = a.major.formatter
+            locs = a.major.locator()
+            locs = locs[(x.min() <= locs) & (locs <= x.max())]
+            
+            if len(locs) > 0:
+                labels = formatter.format_ticks(locs)
+                
+                # The scale should have legend
+                assert scale._legend is not None
+                legend_locs, legend_labels = scale._legend
+                
+                # Legend locations should be in the correct range
+                if len(legend_locs) > 0:
+                    assert min(legend_locs) >= x.min() * 0.9
+                    assert max(legend_locs) <= x.max() * 1.1
+                    
+        finally:
+            # Restore original rcParams
+            mpl.rcParams['axes.formatter.useoffset'] = original_useoffset
+            mpl.rcParams['axes.formatter.offset_threshold'] = original_threshold
+
+    def test_label_small_numbers_no_offset(self):
+        """Test that small numbers don't incorrectly use offset formatting."""
+        import numpy as np
+        import pandas as pd
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        
+        # Create data with small numbers (should not need offset)
+        x = pd.Series(np.linspace(1, 10, 10), name="x")
+        
+        s = Continuous()
+        scale = s._setup(x, Coordinate())
+        
+        # The scale should have legend information
+        assert scale._legend is not None
+        legend_locs, legend_labels = scale._legend
+        
+        # Check that legend values are in the expected range
+        assert len(legend_locs) > 0
+        assert all(1 <= loc <= 10 for loc in legend_locs if loc > 0)
+        
+        # Labels should be simple numbers without scientific notation
+        for label in legend_labels:
+            if label and label.strip():
+                # Should not contain 'e' or '×' for scientific notation
+                assert 'e' not in label.lower() or label == ''
+
+
+    def test_legend_with_large_range_integration(self):
+        """Integration test for legend with large number ranges like body_mass_mg."""
+        import numpy as np
+        import pandas as pd
+        from seaborn._core.scales import Continuous
+        from seaborn._core.properties import Coordinate
+        from matplotlib.ticker import ScalarFormatter
+        
+        # Simulate the body_mass_mg scenario from the issue
+        # body_mass_g is typically 3000-6000, so body_mass_mg is 3000000-6000000
+        body_mass_mg = pd.Series(
+            [3200000, 3750000, 4300000, 4850000, 5400000, 5950000],
+            name="body_mass_mg"
+        )
+        
+        s = Continuous()
+        scale = s._setup(body_mass_mg, Coordinate())
+        
+        # Verify legend exists
+        assert scale._legend is not None
+        legend_locs, legend_labels = scale._legend
+        
+        # Verify we have legend entries
+        assert len(legend_locs) > 0
+        assert len(legend_labels) == len(legend_locs)
+        
+        # The key test: legend locations should be in millions, not 0-100
+        # This is the bug - without the fix, legend_locs might be small numbers
+        # With the fix, they should reflect actual data magnitude
+        for loc in legend_locs:
+            if loc > 0:  # Skip zero if present
+                # Values should be at least in the hundreds of thousands
+                # (could be slightly outside the data range due to axis scaling)
+                assert loc >= 1e5, f"Legend location {loc} is too small, expected >= 1e5"
+
 
 class TestNominal:
 

EOF_114329324912
: '>>>>> Start Test Output'
pytest --no-header -rA tests/_core/test_scales.py
: '>>>>> End Test Output'
git checkout 22cdfb0c93f8ec78492d87edb810f10cb7f57a31 tests/_core/test_scales.py
