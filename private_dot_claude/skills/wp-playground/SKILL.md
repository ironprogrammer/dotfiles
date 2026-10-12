---
name: wp-playground
description: Use when spinning up a Playground instance or testing plugin/admin/block changes locally before shipping a build. Also applies alongside the blueprint skill whenever a blueprint is written or run.
---

# WordPress Playground

Playground is the default local test environment for plugin and theme changes —
use it before handing over a build, especially for anything touching admin
screens, block rendering, or settings UI.

## Blueprints

Use the `blueprint` skill for schema, steps, and resources. The rules below override it where they differ.

Default to v1 blueprints. Use v2 only when asked for it.

When using a blueprint, settings like WP and PHP versions should be set there and not passed in through CLI calls, or they may be ignored and cause unexpected results. E.g.:

```json
"preferredVersions": { "wp": "beta", "php": "8.5" }
```

`wp` version includes options for `latest`, `beta` (current RC), `nightly` (trunk), and pinned numbers like `7.0` / `7.1-RC4`.

### Confirm the running version; never infer it from the blueprint

Ask the instance what it's actually running before trusting any result:

```sh
curl -s http://127.0.0.1:PORT/ | grep -o '<meta name="generator" content="[^"]*"'
# <meta name="generator" content="WordPress 7.1.1"

# or use feed if generator is stripped from FE
curl -s 'http://127.0.0.1:PORT/?feed=rss2' | grep -o '<generator>[^<]*'
```

Report that version, not the one requested. E.g. "wp": "7.1" resolves to the newest 7.1.x.

## Running

- Check the port is free before starting; if it's taken, free it and pick one to stick with for the project.
- Pass **absolute paths** for `--mount` and `--blueprint` to avoid double-mount.
- Don't `sleep n` then curl. Poll instead:

```sh
until curl -sf --max-time 2 http://127.0.0.1:PORT/ >/dev/null; do sleep 1; done
```

- Kill any Playground instance you started when the work is done.

## Reporting results

Never say "green", "passing", or "done" without a captured exit code and the confirmed WordPress version in the same message. If it wasn't run, say so.
