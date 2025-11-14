#!/bin/bash
set -uxo pipefail
source /opt/miniconda3/bin/activate
conda activate testbed
cd /testbed
git config --global --add safe.directory /testbed
cd /testbed
git status
git show
git -c core.fileMode=false diff 93d4c9ea1de24eb391cb2b3561b6703fd46374df
source /opt/miniconda3/bin/activate
conda activate testbed
python -m pip install -e .
git checkout 93d4c9ea1de24eb391cb2b3561b6703fd46374df tests/admin_scripts/tests.py
git apply -v - <<'EOF_114329324912'
diff --git a/tests/admin_scripts/tests.py b/tests/admin_scripts/tests.py
index 04d2f0e..1da9b38 100644
--- a/tests/admin_scripts/tests.py
+++ b/tests/admin_scripts/tests.py
@@ -1618,6 +1618,55 @@ class ManageRunserver(SimpleTestCase):
         call_command(self.cmd)
         self.assertServerSettings("0.0.0.0", "5000")
 
+    def test_runserver_addr_zero_shortcut(self):
+        """Test that '0' as address is expanded to '0.0.0.0' in output."""
+        call_command(self.cmd, addrport="0:8000")
+        self.assertServerSettings("0.0.0.0", "8000")
+        output = self.output.getvalue()
+        # The output should contain '0.0.0.0' not just '0'
+        self.assertIn("0.0.0.0:8000", output)
+        self.assertNotIn("http://0:8000", output)
+
+    def test_runserver_addr_zero_with_port(self):
+        """Test that '0' with custom port expands to '0.0.0.0' in output."""
+        call_command(self.cmd, addrport="0:7000")
+        self.assertServerSettings("0.0.0.0", "7000")
+        output = self.output.getvalue()
+        self.assertIn("0.0.0.0:7000", output)
+        self.assertNotIn("http://0:7000", output)
+
+    def test_runserver_addr_zero_default_port(self):
+        """Test that '0' without port expands to '0.0.0.0' with default port."""
+        call_command(self.cmd, addrport="0")
+        self.assertServerSettings("0.0.0.0", "8000")
+        output = self.output.getvalue()
+        self.assertIn("0.0.0.0:8000", output)
+        self.assertNotIn("http://0:8000", output)
+
+    @unittest.skipUnless(socket.has_ipv6, "platform doesn't support IPv6")
+    def test_runserver_addr_zero_ipv6(self):
+        """Test that '0' with IPv6 flag expands to '::' in output."""
+        call_command(self.cmd, addrport="0:8000", use_ipv6=True)
+        self.assertServerSettings("::", "8000", ipv6=True, raw_ipv6=True)
+        output = self.output.getvalue()
+        # For IPv6, '0' should expand to '::'
+        self.assertIn("[::]:8000", output)
+        self.assertNotIn("http://0:8000", output)
+
+    def test_runserver_explicit_addr_unchanged(self):
+        """Test that explicit addresses are not modified in output."""
+        call_command(self.cmd, addrport="1.2.3.4:8000")
+        self.assertServerSettings("1.2.3.4", "8000")
+        output = self.output.getvalue()
+        self.assertIn("1.2.3.4:8000", output)
+
+    def test_runserver_localhost_unchanged(self):
+        """Test that localhost is not modified in output."""
+        call_command(self.cmd, addrport="localhost:8000")
+        self.assertServerSettings("localhost", "8000")
+        output = self.output.getvalue()
+        self.assertIn("localhost:8000", output)
+
     @unittest.skipUnless(socket.has_ipv6, "platform doesn't support IPv6")
     def test_runner_custom_defaults_ipv6(self):
         self.cmd.default_addr_ipv6 = "::"

EOF_114329324912
: '>>>>> Start Test Output'
./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 admin_scripts.tests
: '>>>>> End Test Output'
git checkout 93d4c9ea1de24eb391cb2b3561b6703fd46374df tests/admin_scripts/tests.py
