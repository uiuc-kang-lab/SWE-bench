#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 3c88e520da24ae6f736929a750876e7654accc3d
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install .
git checkout 3c88e520da24ae6f736929a750876e7654accc3d requests/test_requests.py
git apply -v - <<'EOF_114329324912'
diff --git a/requests/test_requests.py b/requests/test_requests.py
index 1a98458..c268f4d 100644
--- a/requests/test_requests.py
+++ b/requests/test_requests.py
@@ -804,12 +804,120 @@ class RequestsTestCase(unittest.TestCase):
         r = s.get(httpbin('get'), headers={'FOO': None})
         assert 'foo' not in r.request.headers
 
+    def test_session_header_set_to_none_removes_header(self):
+        # Test that setting a session header to None removes it
+        import requests
+        s = requests.Session()
+        # Set a custom header
+        s.headers['X-Custom-Header'] = 'value'
+        # Set it to None to remove it
+        s.headers['X-Custom-Header'] = None
+        r = s.get(httpbin('get'))
+        assert 'X-Custom-Header' not in r.request.headers
+        assert 'x-custom-header' not in r.request.headers
+
+    def test_session_default_header_set_to_none_removes_header(self):
+        # Test that setting a default session header to None removes it
+        import requests
+        s = requests.Session()
+        # Set Accept-Encoding to None to remove it
+        s.headers['Accept-Encoding'] = None
+        r = s.get(httpbin('get'))
+        assert 'Accept-Encoding' not in r.request.headers
+        assert 'accept-encoding' not in r.request.headers
+
+    def test_session_header_none_case_insensitive(self):
+        # Test that setting session header to None is case-insensitive
+        import requests
+        s = requests.Session()
+        s.headers['X-Test-Header'] = 'value'
+        # Set to None using different case
+        s.headers['x-test-header'] = None
+        r = s.get(httpbin('get'))
+        assert 'X-Test-Header' not in r.request.headers
+        assert 'x-test-header' not in r.request.headers
+
+    def test_session_and_request_header_none_interaction(self):
+        # Test interaction between session and request level None headers
+        import requests
+        s = requests.Session()
+        s.headers['X-Session-Header'] = 'session-value'
+        s.headers['X-Both-Header'] = 'session-value'
+        # Request overrides with None
+        r = s.get(httpbin('get'), headers={'X-Both-Header': None, 'X-Request-Header': 'request-value'})
+        assert 'X-Session-Header' in r.request.headers
+        assert 'X-Both-Header' not in r.request.headers
+        assert 'X-Request-Header' in r.request.headers
+
+    def test_session_header_none_does_not_send_none_string(self):
+        # Verify that None doesn't get sent as the string "None"
+        import requests
+        s = requests.Session()
+        s.headers['X-Test'] = None
+        r = s.get(httpbin('get'))
+        # Check that the header is not present at all
+        assert 'X-Test' not in r.request.headers
+        # Also verify in the actual headers sent (if present in response)
+        if 'X-Test' in r.request.headers:
+            # This should not happen, but if it does, verify it's not "None"
+            assert r.request.headers['X-Test'] != 'None'
+            assert r.request.headers['X-Test'] != b'None'
+
+    def test_multiple_session_headers_set_to_none(self):
+        # Test setting multiple session headers to None
+        import requests
+        s = requests.Session()
+        s.headers['X-Header-1'] = 'value1'
+        s.headers['X-Header-2'] = 'value2'
+        s.headers['X-Header-3'] = 'value3'
+        # Set multiple to None
+        s.headers['X-Header-1'] = None
+        s.headers['X-Header-3'] = None
+        r = s.get(httpbin('get'))
+        assert 'X-Header-1' not in r.request.headers
+        assert 'X-Header-2' in r.request.headers
+        assert 'X-Header-3' not in r.request.headers
+
     def test_params_are_merged_case_sensitive(self):
         s = requests.Session()
         s.params['foo'] = 'bar'
         r = s.get(httpbin('get'), params={'FOO': 'bar'})
         assert r.json()['args'] == {'foo': 'bar', 'FOO': 'bar'}
 
+    def test_merge_setting_removes_none_values(self):
+        # Test the merge_setting function directly
+        from requests.sessions import merge_setting
+        from requests.structures import CaseInsensitiveDict
+        
+        # Test with session setting having None values
+        session_setting = CaseInsensitiveDict({'header1': 'value1', 'header2': None, 'header3': 'value3'})
+        request_setting = CaseInsensitiveDict({'header4': 'value4'})
+        
+        result = merge_setting(request_setting, session_setting, dict_class=CaseInsensitiveDict)
+        
+        # header2 should be removed because it's None in session_setting
+        assert 'header1' in result
+        assert 'header2' not in result
+        assert 'header3' in result
+        assert 'header4' in result
+
+    def test_merge_setting_request_none_overrides_session(self):
+        # Test that request-level None removes session header
+        from requests.sessions import merge_setting
+        from requests.structures import CaseInsensitiveDict
+        
+        session_setting = CaseInsensitiveDict({'header1': 'session-value', 'header2': 'session-value'})
+        request_setting = CaseInsensitiveDict({'header1': None, 'header3': 'request-value'})
+        
+        result = merge_setting(request_setting, session_setting, dict_class=CaseInsensitiveDict)
+        
+        # header1 should be removed because it's None in request_setting
+        assert 'header1' not in result
+        assert 'header2' in result
+        assert result['header2'] == 'session-value'
+        assert 'header3' in result
+        assert result['header3'] == 'request-value'
+
 
     def test_long_authinfo_in_url(self):
         url = 'http://{0}:{1}@{2}:9000/path?query#frag'.format(

EOF_114329324912
: '>>>>> Start Test Output'
pytest -rA requests/test_requests.py
: '>>>>> End Test Output'
git checkout 3c88e520da24ae6f736929a750876e7654accc3d requests/test_requests.py
