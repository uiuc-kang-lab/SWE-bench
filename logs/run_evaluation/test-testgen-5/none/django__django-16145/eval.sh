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
index 04d2f0e..d0c967a 100644
--- a/tests/admin_scripts/tests.py
+++ b/tests/admin_scripts/tests.py
@@ -1618,6 +1618,61 @@ class ManageRunserver(SimpleTestCase):
         call_command(self.cmd)
         self.assertServerSettings("0.0.0.0", "5000")
 
+    def test_runserver_addr_zero_shorthand(self):
+        """Test that '0' as address is expanded to '0.0.0.0' in output."""
+        from django.core.management import call_command
+        call_command(self.cmd, addrport="0:8000")
+        self.assertServerSettings("0.0.0.0", "8000")
+        # Check that the output message contains the expanded address
+        output = self.output.getvalue()
+        self.assertIn("0.0.0.0:8000", output)
+        self.assertNotIn("http://0:8000", output)
+
+    def test_runserver_addr_zero_explicit(self):
+        """Test that '0.0.0.0' as address works correctly."""
+        from django.core.management import call_command
+        call_command(self.cmd, addrport="0.0.0.0:8000")
+        self.assertServerSettings("0.0.0.0", "8000")
+        output = self.output.getvalue()
+        self.assertIn("0.0.0.0:8000", output)
+
+    def test_runserver_addr_zero_port_only(self):
+        """Test that '0' as port-only argument uses default address."""
+        from django.core.management import call_command
+        call_command(self.cmd, addrport="8080")
+        self.assertServerSettings("127.0.0.1", "8080")
+        output = self.output.getvalue()
+        self.assertIn("127.0.0.1:8080", output)
+
+    @unittest.skipUnless(socket.has_ipv6, "platform doesn't support IPv6")
+    def test_runserver_addr_zero_shorthand_ipv6(self):
+        """Test that '0' with IPv6 is expanded to '::' in output."""
+        from django.core.management import call_command
+        call_command(self.cmd, addrport="0:8000", use_ipv6=True)
+        self.assertServerSettings("::", "8000", ipv6=True, raw_ipv6=True)
+        output = self.output.getvalue()
+        # IPv6 addresses are wrapped in brackets in the output
+        self.assertIn("[::]:8000", output)
+        self.assertNotIn("http://0:8000", output)
+
+    def test_runserver_output_format_standard_addr(self):
+        """Test that standard addresses are displayed correctly in output."""
+        from django.core.management import call_command
+        call_command(self.cmd, addrport="192.168.1.1:9000")
+        self.assertServerSettings("192.168.1.1", "9000")
+        output = self.output.getvalue()
+        self.assertIn("192.168.1.1:9000", output)
+        self.assertIn("Starting development server at", output)
+
+    def test_runserver_output_format_localhost(self):
+        """Test that localhost is displayed correctly in output."""
+        from django.core.management import call_command
+        call_command(self.cmd, addrport="localhost:8000")
+        self.assertServerSettings("localhost", "8000")
+        output = self.output.getvalue()
+        self.assertIn("localhost:8000", output)
+        self.assertIn("Starting development server at", output)
+
     @unittest.skipUnless(socket.has_ipv6, "platform doesn't support IPv6")
     def test_runner_custom_defaults_ipv6(self):
         self.cmd.default_addr_ipv6 = "::"

EOF_114329324912
: '>>>>> Start Test Output'
./tests/runtests.py --verbosity 2 --settings=test_sqlite --parallel 1 admin_scripts.tests
: '>>>>> End Test Output'
git checkout 93d4c9ea1de24eb391cb2b3561b6703fd46374df tests/admin_scripts/tests.py
