# Next Steps

This first version is a backup and restore base. It is intentionally conservative.

Recommended next changes:

1. Test `Super+Space` and `Super+Alt+Space` with `my-launcher` and `my-menu`.
2. Validate the new local Waybar click handlers on a fresh install.
3. Decide which optional app bindings should stay, because some still assume apps like Spotify, Obsidian, Signal, lazydocker, or cliamp.
4. Split more theme colors into a small local theme file if you want easier palette switching later.
5. Keep Alacritty as the only terminal and remove terminal-specific distractions.
6. Test restore in a VM before using it for a real reinstall.

High-value replacements:

```text
browser launcher       -> my-browser
app launcher           -> my-launcher
system menu            -> my-menu
lock                   -> my-lock
screenshot             -> my-screenshot
idle toggle            -> my-toggle-service hypridle
```
