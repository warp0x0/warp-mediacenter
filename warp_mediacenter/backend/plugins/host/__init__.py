"""Host services exposed to plugins.

Each module here is one capability the host lends out, scoped to a single plugin:

* ``http``    — allowlisted HTTP with rate limiting and automatic auth headers
* ``db``      — the plugin's own tables, fenced off by the SQLite authorizer
* ``secrets`` — credentials in ``plugin_secrets``, keyed to the plugin
* ``oauth``   — the device-code flow, run by the host on the plugin's behalf
* ``cache``   — a bounded in-process cache
* ``logging`` — attributed, rate-limited structured logging
* ``context`` — assembles the above into the bundle passed on every call
"""

from warp_mediacenter.backend.plugins.host.cache import PluginCache
from warp_mediacenter.backend.plugins.host.context import (
    PLUGIN_CONTEXT_API_VERSION,
    PluginHost,
)
from warp_mediacenter.backend.plugins.host.db import (
    PluginDatabase,
    PluginDatabaseDenied,
    drop_plugin_tables,
    run_plugin_migrations,
)
from warp_mediacenter.backend.plugins.host.http import (
    PluginHostNotAllowed,
    PluginHttpClient,
    PluginHttpResponse,
    PluginRateLimited,
)
from warp_mediacenter.backend.plugins.host.logging import PluginLogger
from warp_mediacenter.backend.plugins.host.oauth import (
    TOKEN_SECRET_KEY,
    DeviceCodeAuthenticator,
)
from warp_mediacenter.backend.plugins.host.secrets import PluginSecrets

__all__ = [
    "PLUGIN_CONTEXT_API_VERSION",
    "TOKEN_SECRET_KEY",
    "DeviceCodeAuthenticator",
    "PluginCache",
    "PluginDatabase",
    "PluginDatabaseDenied",
    "PluginHost",
    "PluginHostNotAllowed",
    "PluginHttpClient",
    "PluginHttpResponse",
    "PluginLogger",
    "PluginRateLimited",
    "PluginSecrets",
    "drop_plugin_tables",
    "run_plugin_migrations",
]
