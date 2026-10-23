# Templates 📄

This folder contains **templates for local configuration and message files**.

Copy the files you need to your status directory (the repository root, or the
folder pointed to by `MY_STATUS_CONFIG_DIR`) and customize them:

```shell
cp templates/status_hostname_list.txt .
cp templates/config-example config
cp templates/status_maintenance_text.txt .   # optional
cp templates/status_past_maintenance_text.txt .   # optional
cp templates/status_website_list.txt .       # optional, for scripts/check-websites.sh
```

The actual files in the status directory are **ignored by git** (see
`.gitignore`), so local changes to your configuration, hostnames, and
maintenance messages stay private and do not create merge conflicts with
upstream updates.

| Template | Purpose |
|---|---|
| `status_hostname_list.txt` | What should be monitored (ping, nc, curl, grep, http-status, script, traceroute) |
| `config-example` | Optional additional configuration for `status.sh` |
| `status_maintenance_text.txt` | Message displayed during maintenance (degrades all errors) |
| `status_past_maintenance_text.txt` | Message about past maintenance work |
| `status_website_list.txt` | Website list for `scripts/check-websites.sh` |
