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
index abeeff0..45e830f 100644
--- a/sklearn/cluster/tests/test_k_means.py
+++ b/sklearn/cluster/tests/test_k_means.py
@@ -674,6 +674,118 @@ def test_full_vs_elkan():
     assert homogeneity_score(km1.predict(X), km2.predict(X)) == 1.0
 
 
+def test_k_means_n_jobs_consistency():
+    # Test that KMeans gives the same result for n_jobs=1 vs n_jobs>1
+    # This is a regression test for issue where n_jobs=1 gave slightly
+    # different results than n_jobs>1
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=10000, centers=10, n_features=2, 
+                                 random_state=2)
+    
+    # Run KMeans with n_jobs=1
+    kmeans_1 = KMeans(n_clusters=10, random_state=2, n_jobs=1)
+    kmeans_1.fit(X_test)
+    
+    # Run KMeans with n_jobs=2
+    kmeans_2 = KMeans(n_clusters=10, random_state=2, n_jobs=2)
+    kmeans_2.fit(X_test)
+    
+    # Run KMeans with n_jobs=3
+    kmeans_3 = KMeans(n_clusters=10, random_state=2, n_jobs=3)
+    kmeans_3.fit(X_test)
+    
+    # Run KMeans with n_jobs=4
+    kmeans_4 = KMeans(n_clusters=10, random_state=2, n_jobs=4)
+    kmeans_4.fit(X_test)
+    
+    # The inertia should be the same (or very close due to floating point)
+    assert_allclose(kmeans_1.inertia_, kmeans_2.inertia_, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=2 gave different inertia")
+    assert_allclose(kmeans_1.inertia_, kmeans_3.inertia_, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=3 gave different inertia")
+    assert_allclose(kmeans_1.inertia_, kmeans_4.inertia_, rtol=1e-7,
+                   err_msg="n_jobs=1 and n_jobs=4 gave different inertia")
+    
+    # The cluster centers should also be consistent
+    # Sort centers by their first coordinate for comparison
+    centers_1_sorted = kmeans_1.cluster_centers_[np.argsort(kmeans_1.cluster_centers_[:, 0])]
+    centers_2_sorted = kmeans_2.cluster_centers_[np.argsort(kmeans_2.cluster_centers_[:, 0])]
+    centers_3_sorted = kmeans_3.cluster_centers_[np.argsort(kmeans_3.cluster_centers_[:, 0])]
+    centers_4_sorted = kmeans_4.cluster_centers_[np.argsort(kmeans_4.cluster_centers_[:, 0])]
+    
+    assert_allclose(centers_1_sorted, centers_2_sorted, rtol=1e-5,
+                   err_msg="n_jobs=1 and n_jobs=2 gave different centers")
+    assert_allclose(centers_1_sorted, centers_3_sorted, rtol=1e-5,
+                   err_msg="n_jobs=1 and n_jobs=3 gave different centers")
+    assert_allclose(centers_1_sorted, centers_4_sorted, rtol=1e-5,
+                   err_msg="n_jobs=1 and n_jobs=4 gave different centers")
+
+
+@if_safe_multiprocessing_with_blas
+def test_k_means_n_jobs_consistency_with_parallel():
+    # Test that KMeans gives consistent results across different n_jobs values
+    # when using parallel processing
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=5000, centers=5, n_features=3,
+                                 random_state=123)
+    
+    results_inertia = []
+    results_centers = []
+    
+    for n_jobs in [1, 2, 3, 4]:
+        kmeans = KMeans(n_clusters=5, random_state=123, n_jobs=n_jobs, 
+                       n_init=10)
+        kmeans.fit(X_test)
+        results_inertia.append(kmeans.inertia_)
+        # Sort centers for comparison
+        centers_sorted = kmeans.cluster_centers_[np.argsort(kmeans.cluster_centers_[:, 0])]
+        results_centers.append(centers_sorted)
+    
+    # All results should be the same
+    for i in range(1, len(results_inertia)):
+        assert_allclose(results_inertia[0], results_inertia[i], rtol=1e-7,
+                       err_msg=f"n_jobs=1 and n_jobs={i+1} gave different inertia")
+        assert_allclose(results_centers[0], results_centers[i], rtol=1e-5,
+                       err_msg=f"n_jobs=1 and n_jobs={i+1} gave different centers")
+
+
+def test_k_means_function_n_jobs_consistency():
+    # Test that k_means function gives the same result for n_jobs=1 vs n_jobs>1
+    from sklearn.cluster import k_means
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    
+    # Generate some data
+    X_test, y_test = make_blobs(n_samples=1000, centers=5, n_features=2,
+                                 random_state=456)
+    
+    # Call k_means function with n_jobs=1
+    centers_1, labels_1, inertia_1 = k_means(X_test, n_clusters=5, 
+                                              random_state=456, n_jobs=1,
+                                              n_init=10)
+    
+    # Call k_means function with n_jobs=2
+    centers_2, labels_2, inertia_2 = k_means(X_test, n_clusters=5,
+                                              random_state=456, n_jobs=2,
+                                              n_init=10)
+    
+    # The inertia should be the same
+    assert_allclose(inertia_1, inertia_2, rtol=1e-7,
+                   err_msg="k_means with n_jobs=1 and n_jobs=2 gave different inertia")
+    
+    # The cluster centers should be consistent (after sorting)
+    centers_1_sorted = centers_1[np.argsort(centers_1[:, 0])]
+    centers_2_sorted = centers_2[np.argsort(centers_2[:, 0])]
+    assert_allclose(centers_1_sorted, centers_2_sorted, rtol=1e-5,
+                   err_msg="k_means with n_jobs=1 and n_jobs=2 gave different centers")
+
+
 def test_n_init():
     # Check that increasing the number of init increases the quality
     n_runs = 5
@@ -692,6 +804,40 @@ def test_n_init():
         assert inertia[i] >= inertia[i + 1], failure_msg
 
 
+def test_k_means_n_jobs_deterministic():
+    # Regression test for issue where n_jobs=1 gave different results than n_jobs>1
+    # This test uses the exact scenario from the reported issue
+    from sklearn.datasets import make_blobs
+    import numpy as np
+    
+    # Generate data exactly as in the issue
+    X_test, y_test = make_blobs(n_samples=10000, centers=10, n_features=2, 
+                                 random_state=2)
+    
+    inertias = []
+    centers_list = []
+    
+    # Run KMeans with various n_jobs values (1 through 4)
+    for n_jobs in range(1, 5):
+        kmeans = KMeans(n_clusters=10, random_state=2, n_jobs=n_jobs)
+        kmeans.fit(X_test)
+        inertias.append(kmeans.inertia_)
+        # Sort centers for comparison
+        centers_sorted = kmeans.cluster_centers_[np.argsort(kmeans.cluster_centers_[:, 0])]
+        centers_list.append(centers_sorted)
+    
+    # All inertias should be identical (or very close)
+    for i in range(1, len(inertias)):
+        assert_allclose(inertias[0], inertias[i], rtol=1e-7,
+                       err_msg=f"n_jobs=1 gave inertia {inertias[0]}, "
+                               f"but n_jobs={i+1} gave {inertias[i]}")
+    
+    # All centers should be identical (or very close)
+    for i in range(1, len(centers_list)):
+        assert_allclose(centers_list[0], centers_list[i], rtol=1e-5,
+                       err_msg=f"n_jobs=1 and n_jobs={i+1} gave different centers")
+
+
 def test_k_means_function():
     # test calling the k_means function directly
     # catch output

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA sklearn/cluster/tests/test_k_means.py
: '>>>>> End Test Output'
git checkout 3eacf948e0f95ef957862568d87ce082f378e186 sklearn/cluster/tests/test_k_means.py
