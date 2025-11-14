#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 3eacf948e0f95ef957862568d87ce082f378e186
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -v --no-use-pep517 --no-build-isolation -e .
git checkout 3eacf948e0f95ef957862568d87ce082f378e186 sklearn/cluster/tests/test_k_means.py
git apply -v - <<'EOF_114329324912'
diff --git a/sklearn/cluster/tests/test_k_means.py b/sklearn/cluster/tests/test_k_means.py
index abeeff0..839f346 100644
--- a/sklearn/cluster/tests/test_k_means.py
+++ b/sklearn/cluster/tests/test_k_means.py
@@ -727,6 +727,159 @@ def test_k_means_function():
                          sample_weight=None, algorithm="elkan")
 
 
+def test_k_means_n_jobs_consistency():
+    # Test that KMeans gives the same result for n_jobs=1 vs n_jobs>1
+    # This is a regression test for issue where n_jobs=1 gave different
+    # results than n_jobs>1
+    from sklearn.cluster import KMeans
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    from numpy.testing import assert_allclose
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=10000, centers=10, n_features=2, 
+                                 random_state=2)
+    
+    # Run KMeans with n_jobs=1
+    kmeans_1 = KMeans(n_clusters=10, random_state=2, n_jobs=1)
+    kmeans_1.fit(X_test)
+    inertia_1 = kmeans_1.inertia_
+    centers_1 = kmeans_1.cluster_centers_
+    labels_1 = kmeans_1.labels_
+    
+    # Run KMeans with n_jobs=2
+    kmeans_2 = KMeans(n_clusters=10, random_state=2, n_jobs=2)
+    kmeans_2.fit(X_test)
+    inertia_2 = kmeans_2.inertia_
+    centers_2 = kmeans_2.cluster_centers_
+    labels_2 = kmeans_2.labels_
+    
+    # The inertia should be the same (or very close due to floating point)
+    assert_allclose(inertia_1, inertia_2, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=2 gave different inertia")
+    
+    # Run KMeans with n_jobs=3
+    kmeans_3 = KMeans(n_clusters=10, random_state=2, n_jobs=3)
+    kmeans_3.fit(X_test)
+    inertia_3 = kmeans_3.inertia_
+    
+    # Run KMeans with n_jobs=4
+    kmeans_4 = KMeans(n_clusters=10, random_state=2, n_jobs=4)
+    kmeans_4.fit(X_test)
+    inertia_4 = kmeans_4.inertia_
+    
+    # All inertias should be the same
+    assert_allclose(inertia_1, inertia_3, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=3 gave different inertia")
+    assert_allclose(inertia_1, inertia_4, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=4 gave different inertia")
+
+
+@if_safe_multiprocessing_with_blas
+def test_k_means_n_jobs_consistency_parallel():
+    # Test that KMeans gives consistent results across different n_jobs values
+    # when using parallel processing
+    from sklearn.cluster import KMeans
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    from numpy.testing import assert_allclose
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=5000, centers=5, n_features=3,
+                                 random_state=123)
+    
+    results = []
+    for n_jobs in [1, 2, 3, 4]:
+        kmeans = KMeans(n_clusters=5, random_state=123, n_jobs=n_jobs, 
+                       n_init=10)
+        kmeans.fit(X_test)
+        results.append(kmeans.inertia_)
+    
+    # All results should be the same
+    for i in range(1, len(results)):
+        assert_allclose(results[0], results[i], rtol=1e-7,
+                       err_msg=f"n_jobs=1 and n_jobs={i+1} gave different results")
+
+
+def test_k_means_n_jobs_consistency_with_init():
+    # Test that KMeans gives consistent results with different init methods
+    from sklearn.cluster import KMeans
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    from numpy.testing import assert_allclose
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=1000, centers=4, n_features=2,
+                                 random_state=456)
+    
+    for init_method in ['k-means++', 'random']:
+        # Run with n_jobs=1
+        kmeans_1 = KMeans(n_clusters=4, random_state=456, n_jobs=1,
+                         init=init_method, n_init=5)
+        kmeans_1.fit(X_test)
+        
+        # Run with n_jobs=2
+        kmeans_2 = KMeans(n_clusters=4, random_state=456, n_jobs=2,
+                         init=init_method, n_init=5)
+        kmeans_2.fit(X_test)
+        
+        # The inertia should be the same
+        assert_allclose(kmeans_1.inertia_, kmeans_2.inertia_, rtol=1e-7,
+                       err_msg=f"n_jobs=1 and n_jobs=2 gave different inertia with init={init_method}")
+
+
+def test_k_means_n_jobs_consistency_elkan():
+    # Test that KMeans gives consistent results with elkan algorithm
+    from sklearn.cluster import KMeans
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    from numpy.testing import assert_allclose
+    
+    # Generate some data (elkan doesn't support sparse, so use dense)
+    X_test, y_test = make_blobs(n_samples=2000, centers=6, n_features=4,
+                                 random_state=789)
+    
+    # Run with n_jobs=1 and elkan algorithm
+    kmeans_1 = KMeans(n_clusters=6, random_state=789, n_jobs=1,
+                     algorithm='elkan', n_init=5)
+    kmeans_1.fit(X_test)
+    
+    # Run with n_jobs=2 and elkan algorithm
+    kmeans_2 = KMeans(n_clusters=6, random_state=789, n_jobs=2,
+                     algorithm='elkan', n_init=5)
+    kmeans_2.fit(X_test)
+    
+    # The inertia should be the same
+    assert_allclose(kmeans_1.inertia_, kmeans_2.inertia_, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=2 gave different inertia with elkan algorithm")
+
+
+def test_k_means_n_jobs_consistency_full():
+    # Test that KMeans gives consistent results with full algorithm
+    from sklearn.cluster import KMeans
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    from numpy.testing import assert_allclose
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=1500, centers=7, n_features=3,
+                                 random_state=321)
+    
+    # Run with n_jobs=1 and full algorithm
+    kmeans_1 = KMeans(n_clusters=7, random_state=321, n_jobs=1,
+                     algorithm='full', n_init=5)
+    kmeans_1.fit(X_test)
+    
+    # Run with n_jobs=2 and full algorithm
+    kmeans_2 = KMeans(n_clusters=7, random_state=321, n_jobs=2,
+                     algorithm='full', n_init=5)
+    kmeans_2.fit(X_test)
+    
+    # The inertia should be the same
+    assert_allclose(kmeans_1.inertia_, kmeans_2.inertia_, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=2 gave different inertia with full algorithm")
+
+
 def test_x_squared_norms_init_centroids():
     # Test that x_squared_norms can be None in _init_centroids
     from sklearn.cluster.k_means_ import _init_centroids

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA sklearn/cluster/tests/test_k_means.py
: '>>>>> End Test Output'
git checkout 3eacf948e0f95ef957862568d87ce082f378e186 sklearn/cluster/tests/test_k_means.py
