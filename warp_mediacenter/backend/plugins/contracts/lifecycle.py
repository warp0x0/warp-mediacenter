"""Lifecycle actions every plugin category shares.

These are dispatched by the host regardless of category.  A plugin may implement
none of them — the host treats an ``unsupported_action`` reply, or a missing
capability, as "nothing to do" for every lifecycle hook.
"""

from __future__ import annotations


class LifecycleAction:
    #: Called once after files are installed and the plugin's own DB migrations
    #: have run.  Somewhere to seed defaults.
    INSTALL = "plugin.install"
    #: Called before the plugin's files and tables are removed.
    UNINSTALL = "plugin.uninstall"
    ENABLE = "plugin.enable"
    DISABLE = "plugin.disable"

    #: Return the settings page description *including current values*, read from
    #: the plugin's own tables.  The host merges auth state and the active flag on
    #: top; it never stores plugin configuration itself.
    SETTINGS_SCHEMA = "plugin.settings.schema"
    #: Persist submitted values.  The plugin validates and writes its own tables.
    SETTINGS_SAVE = "plugin.settings.save"
    #: Invoked by ``action_button`` fields; the concrete id is appended.
    ACTION_PREFIX = "plugin.action."

    @staticmethod
    def action(action_id: str) -> str:
        return f"{LifecycleAction.ACTION_PREFIX}{action_id}"


__all__ = ["LifecycleAction"]
