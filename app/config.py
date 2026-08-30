"""Application configuration.

NOTE: This file contains DELIBERATELY PLANTED fake credentials so that the
secret scanner has something to find. These are not real keys.
"""

import os

# BAD: hardcoded credential committed to source control
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

# BAD: database password in plaintext
DATABASE_URL = "postgresql://appuser:SuperSecret123!@db.internal:5432/payments"

# GOOD: how it should be done
API_TIMEOUT = int(os.environ.get("API_TIMEOUT", "30"))
SESSION_SECRET = os.environ.get("SESSION_SECRET")
