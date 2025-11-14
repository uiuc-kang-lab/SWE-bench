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
index 4242664..99dbe4e 100644
--- a/lib/matplotlib/tests/test_pyplot.py
+++ b/lib/matplotlib/tests/test_pyplot.py
@@ -166,6 +166,269 @@ def test_close():
                          "a string, or None, not <class 'float'>"
 
 
+def test_get_backend_preserves_figures_created_in_rc_context():
+    """
+    Test that get_backend() doesn't clear figures from Gcf.figs
+    when they were created under rc_context.
+    
+    This is a regression test for:
+    https://github.com/matplotlib/matplotlib/issues/...
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Create a figure within rc_context
+    with rc_context():
+        fig = plt.figure()
+    
+    # Store the state before calling get_backend()
+    figs_before = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_before = len(figs_before)
+    
+    # Call get_backend() - this should not clear figures
+    backend = get_backend()
+    
+    # Check that figures are still present
+    figs_after = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_after = len(figs_after)
+    
+    assert num_figs_before == num_figs_after, (
+        f"get_backend() cleared figures: had {num_figs_before} before, "
+        f"{num_figs_after} after"
+    )
+    assert figs_before.keys() == figs_after.keys(), (
+        "Figure numbers changed after get_backend()"
+    )
+    
+    # Verify that plt.close() works on the figure
+    plt.close(fig)
+    assert len(plt._pylab_helpers.Gcf.figs) == 0, (
+        "Figure was not properly closed"
+    )
+
+
+def test_get_backend_preserves_multiple_figures_with_rc_context():
+    """
+    Test that get_backend() preserves multiple figures when some
+    are created in rc_context.
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Create first figure in rc_context
+    with rc_context():
+        fig1 = plt.figure()
+    
+    # Create second figure outside rc_context
+    fig2 = plt.figure()
+    
+    # Create third figure in another rc_context
+    with rc_context():
+        fig3 = plt.figure()
+    
+    # Store the state before calling get_backend()
+    figs_before = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_before = len(figs_before)
+    
+    # Call get_backend()
+    backend = get_backend()
+    
+    # Check that all figures are still present
+    figs_after = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_after = len(figs_after)
+    
+    assert num_figs_before == num_figs_after == 3, (
+        f"Expected 3 figures, had {num_figs_before} before get_backend(), "
+        f"{num_figs_after} after"
+    )
+    
+    # Verify all figures can be closed
+    plt.close(fig1)
+    assert len(plt._pylab_helpers.Gcf.figs) == 2
+    plt.close(fig2)
+    assert len(plt._pylab_helpers.Gcf.figs) == 1
+    plt.close(fig3)
+    assert len(plt._pylab_helpers.Gcf.figs) == 0
+
+
+def test_get_backend_with_figure_before_rc_context():
+    """
+    Test that get_backend() works correctly when a figure is created
+    before rc_context (the workaround mentioned in the issue).
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Create a figure before rc_context (workaround)
+    fig1 = plt.figure()
+    
+    # Create another figure within rc_context
+    with rc_context():
+        fig2 = plt.figure()
+    
+    # Store the state before calling get_backend()
+    figs_before = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_before = len(figs_before)
+    
+    # Call get_backend()
+    backend = get_backend()
+    
+    # Check that figures are still present
+    figs_after = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_after = len(figs_after)
+    
+    assert num_figs_before == num_figs_after == 2, (
+        f"Expected 2 figures, had {num_figs_before} before get_backend(), "
+        f"{num_figs_after} after"
+    )
+    
+    # Clean up
+    plt.close('all')
+
+
+def test_get_backend_with_ion():
+    """
+    Test that get_backend() works correctly with plt.ion() enabled
+    (another workaround mentioned in the issue).
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Enable interactive mode (workaround)
+    was_interactive = plt.isinteractive()
+    plt.ion()
+    
+    try:
+        # Create a figure within rc_context
+        with rc_context():
+            fig = plt.figure()
+        
+        # Store the state before calling get_backend()
+        figs_before = dict(plt._pylab_helpers.Gcf.figs)
+        num_figs_before = len(figs_before)
+        
+        # Call get_backend()
+        backend = get_backend()
+        
+        # Check that figures are still present
+        figs_after = dict(plt._pylab_helpers.Gcf.figs)
+        num_figs_after = len(figs_after)
+        
+        assert num_figs_before == num_figs_after == 1, (
+            f"Expected 1 figure, had {num_figs_before} before get_backend(), "
+            f"{num_figs_after} after"
+        )
+        
+        # Clean up
+        plt.close('all')
+    finally:
+        # Restore interactive state
+        if not was_interactive:
+            plt.ioff()
+
+
+def test_get_backend_idempotent():
+    """
+    Test that calling get_backend() multiple times doesn't cause issues.
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Create a figure within rc_context
+    with rc_context():
+        fig = plt.figure()
+    
+    # Call get_backend() multiple times
+    backend1 = get_backend()
+    figs_after_first = len(plt._pylab_helpers.Gcf.figs)
+    
+    backend2 = get_backend()
+    figs_after_second = len(plt._pylab_helpers.Gcf.figs)
+    
+    backend3 = get_backend()
+    figs_after_third = len(plt._pylab_helpers.Gcf.figs)
+    
+    # All should return the same backend
+    assert backend1 == backend2 == backend3
+    
+    # Figure count should remain constant
+    assert figs_after_first == figs_after_second == figs_after_third == 1, (
+        f"Figure count changed: {figs_after_first}, {figs_after_second}, "
+        f"{figs_after_third}"
+    )
+    
+    # Clean up
+    plt.close('all')
+
+
+def test_get_backend_nested_rc_context():
+    """
+    Test that get_backend() works with nested rc_context calls.
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Create figures in nested rc_context
+    with rc_context():
+        fig1 = plt.figure()
+        with rc_context():
+            fig2 = plt.figure()
+    
+    # Store the state before calling get_backend()
+    figs_before = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_before = len(figs_before)
+    
+    # Call get_backend()
+    backend = get_backend()
+    
+    # Check that figures are still present
+    figs_after = dict(plt._pylab_helpers.Gcf.figs)
+    num_figs_after = len(figs_after)
+    
+    assert num_figs_before == num_figs_after == 2, (
+        f"Expected 2 figures, had {num_figs_before} before get_backend(), "
+        f"{num_figs_after} after"
+    )
+    
+    # Clean up
+    plt.close('all')
+
+
+def test_figure_close_after_get_backend_with_rc_context():
+    """
+    Test that plt.close() works correctly after get_backend() is called
+    on figures created in rc_context.
+    """
+    import matplotlib.pyplot as plt
+    from matplotlib import get_backend, rc_context
+    
+    # Create a figure within rc_context
+    with rc_context():
+        fig = plt.figure()
+    
+    fig_num = fig.number
+    
+    # Call get_backend()
+    backend = get_backend()
+    
+    # Verify figure is still in Gcf
+    assert fig_num in plt._pylab_helpers.Gcf.figs, (
+        "Figure not found in Gcf.figs after get_backend()"
+    )
+    
+    # Try to close the figure - this should work
+    plt.close(fig)
+    
+    # Verify figure was removed from Gcf
+    assert fig_num not in plt._pylab_helpers.Gcf.figs, (
+        "Figure was not removed from Gcf.figs after plt.close()"
+    )
+    
+    assert len(plt._pylab_helpers.Gcf.figs) == 0, (
+        "Gcf.figs should be empty after closing all figures"
+    )
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
