#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 3eadeacc06c9f2ddcdac6ae39819faa9fbee9e39
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git checkout 3eadeacc06c9f2ddcdac6ae39819faa9fbee9e39 lib/matplotlib/tests/test_pyplot.py
git apply -v - <<'EOF_114329324912'
diff --git a/lib/matplotlib/tests/test_pyplot.py b/lib/matplotlib/tests/test_pyplot.py
index 4242664..5bb2f2f 100644
--- a/lib/matplotlib/tests/test_pyplot.py
+++ b/lib/matplotlib/tests/test_pyplot.py
@@ -166,6 +166,203 @@ def test_close():
                          "a string, or None, not <class 'float'>"
 
 
+def test_get_backend_preserves_figures_in_rc_context():
+    """Test that get_backend() doesn't clear figures created in rc_context."""
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Close all existing figures first
+    plt.close('all')
+    
+    # Create a figure inside rc_context
+    with rc_context():
+        fig = plt.figure()
+        fig_num = fig.number
+    
+    # Check that figure is in Gcf.figs
+    assert fig_num in plt._pylab_helpers.Gcf.figs, \
+        "Figure should be in Gcf.figs after creation"
+    
+    # Call get_backend() - this should NOT clear the figure
+    get_backend()
+    
+    # Verify figure is still in Gcf.figs
+    assert fig_num in plt._pylab_helpers.Gcf.figs, \
+        "Figure should still be in Gcf.figs after get_backend()"
+    
+    # Verify we can close the figure properly
+    plt.close(fig)
+    assert fig_num not in plt._pylab_helpers.Gcf.figs, \
+        "Figure should be removed from Gcf.figs after close()"
+
+
+def test_get_backend_preserves_multiple_figures_in_rc_context():
+    """Test that get_backend() preserves multiple figures created in rc_context."""
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Close all existing figures first
+    plt.close('all')
+    
+    # Create multiple figures inside rc_context
+    with rc_context():
+        fig1 = plt.figure()
+        fig2 = plt.figure()
+        fig_nums = [fig1.number, fig2.number]
+    
+    # Check that both figures are in Gcf.figs
+    for fig_num in fig_nums:
+        assert fig_num in plt._pylab_helpers.Gcf.figs, \
+            f"Figure {fig_num} should be in Gcf.figs after creation"
+    
+    # Call get_backend() - this should NOT clear the figures
+    get_backend()
+    
+    # Verify both figures are still in Gcf.figs
+    for fig_num in fig_nums:
+        assert fig_num in plt._pylab_helpers.Gcf.figs, \
+            f"Figure {fig_num} should still be in Gcf.figs after get_backend()"
+    
+    # Clean up
+    plt.close('all')
+
+
+def test_get_backend_with_figure_before_rc_context():
+    """Test that get_backend() works when figure exists before rc_context."""
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Close all existing figures first
+    plt.close('all')
+    
+    # Create a figure BEFORE rc_context
+    fig1 = plt.figure()
+    fig1_num = fig1.number
+    
+    # Create another figure inside rc_context
+    with rc_context():
+        fig2 = plt.figure()
+        fig2_num = fig2.number
+    
+    # Check that both figures are in Gcf.figs
+    assert fig1_num in plt._pylab_helpers.Gcf.figs
+    assert fig2_num in plt._pylab_helpers.Gcf.figs
+    
+    # Call get_backend() - this should NOT clear any figures
+    get_backend()
+    
+    # Verify both figures are still in Gcf.figs
+    assert fig1_num in plt._pylab_helpers.Gcf.figs, \
+        "Figure created before rc_context should still be in Gcf.figs"
+    assert fig2_num in plt._pylab_helpers.Gcf.figs, \
+        "Figure created in rc_context should still be in Gcf.figs"
+    
+    # Clean up
+    plt.close('all')
+
+
+def test_get_backend_with_ion_and_rc_context():
+    """Test that get_backend() works with ion() and rc_context."""
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    import matplotlib as mpl
+    
+    # Close all existing figures first
+    plt.close('all')
+    
+    # Save original interactive state
+    was_interactive = mpl.is_interactive()
+    
+    try:
+        # Turn on interactive mode
+        plt.ion()
+        
+        # Create a figure inside rc_context
+        with rc_context():
+            fig = plt.figure()
+            fig_num = fig.number
+        
+        # Check that figure is in Gcf.figs
+        assert fig_num in plt._pylab_helpers.Gcf.figs
+        
+        # Call get_backend() - this should NOT clear the figure
+        get_backend()
+        
+        # Verify figure is still in Gcf.figs
+        assert fig_num in plt._pylab_helpers.Gcf.figs, \
+            "Figure should still be in Gcf.figs after get_backend() with ion()"
+        
+        # Clean up
+        plt.close('all')
+    finally:
+        # Restore original interactive state
+        if was_interactive:
+            plt.ion()
+        else:
+            plt.ioff()
+
+
+def test_get_backend_nested_rc_context():
+    """Test that get_backend() works with nested rc_context."""
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Close all existing figures first
+    plt.close('all')
+    
+    # Create figures in nested rc_context
+    with rc_context():
+        fig1 = plt.figure()
+        fig1_num = fig1.number
+        
+        with rc_context():
+            fig2 = plt.figure()
+            fig2_num = fig2.number
+    
+    # Check that both figures are in Gcf.figs
+    assert fig1_num in plt._pylab_helpers.Gcf.figs
+    assert fig2_num in plt._pylab_helpers.Gcf.figs
+    
+    # Call get_backend() - this should NOT clear any figures
+    get_backend()
+    
+    # Verify both figures are still in Gcf.figs
+    assert fig1_num in plt._pylab_helpers.Gcf.figs, \
+        "Figure from outer rc_context should still be in Gcf.figs"
+    assert fig2_num in plt._pylab_helpers.Gcf.figs, \
+        "Figure from inner rc_context should still be in Gcf.figs"
+    
+    # Clean up
+    plt.close('all')
+
+
+def test_close_figure_created_in_rc_context():
+    """Test that plt.close() works for figures created in rc_context."""
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Close all existing figures first
+    plt.close('all')
+    
+    # Create a figure inside rc_context
+    with rc_context():
+        fig = plt.figure()
+        fig_num = fig.number
+    
+    # Call get_backend() to ensure it doesn't interfere
+    get_backend()
+    
+    # Verify figure is still in Gcf.figs
+    assert fig_num in plt._pylab_helpers.Gcf.figs
+    
+    # Now close the figure - this should work
+    plt.close(fig)
+    
+    # Verify figure is removed from Gcf.figs
+    assert fig_num not in plt._pylab_helpers.Gcf.figs, \
+        "Figure should be removed from Gcf.figs after close()"
+
+
 def test_subplot_reuse():
     ax1 = plt.subplot(121)
     assert ax1 is plt.gca()

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA lib/matplotlib/tests/test_pyplot.py
: '>>>>> End Test Output'
git checkout 3eadeacc06c9f2ddcdac6ae39819faa9fbee9e39 lib/matplotlib/tests/test_pyplot.py
