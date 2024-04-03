# add_header.py
"""
This script enhances the testing of Cloud Run applications or HTTP services that do not allow
unauthenticated invocations by automatically adding an Authorization header with a Bearer token
to each request. For API-only testing, using CURL will be more straightforward, e.g.:

    curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" API_ENDPOINT_URL

To use this script:

1. Install mitmproxy
   - Ensure Python and pip are installed on your system.
   - Install via pip using `pip install mitmproxy`.

2. Run mitmproxy with this script
   - Execute `mitmproxy -s add_header.py` to start mitmproxy using this script.
   - Ensure this script is in your current directory or specify the full path.

3. Install mitmproxy's CA certificate:
   - Find the CA certificate in `%USERPROFILE%\.mitmproxy` on Windows or `~/.mitmproxy/` on Linux.
   - Install this certificate in your computer to avoid SSL/TLS certificate validation errors.
   - This step is crucial for HTTPS traffic inspection and modification.

4. Configure your web browser:
   - Set your browser's proxy to `127.0.0.1:8080` to route traffic through mitmproxy.
   - This allows the script to intercept HTTP requests and add Authorization header.

5. Access your Cloud IAM-protected Web Application:
    - Open Chrome and navigate to your Cloud Run service URL.
    - The script will automatically add the Authorization header to each request.
"""

import subprocess
from mitmproxy import http

# Path to the gcloud CLI executable
CMD = "c:/Users/danie/AppData/Local/cloud-code/installer/google-cloud-sdk/bin/gcloud.cmd"

def get_identity_token():
    """ Fetches an identity token from the gcloud CLI."""
    result = subprocess.run([CMD, "auth", "print-identity-token"],capture_output=True, text=True)
    return result.stdout.strip()

# Fetch the token once when the script starts
IDENTITY_TOKEN = get_identity_token()

def request(flow: http.HTTPFlow) -> None:
    """ Use the pre-fetched identity token. """
    flow.request.headers["Authorization"] = f"Bearer {IDENTITY_TOKEN}"
