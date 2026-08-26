---
name: wp-playground
description: Use when spinning up a Playground instance, writing or editing a Playground blueprint, or testing plugin/admin/block changes locally before shipping a build.
---

# WordPress Playground

Playground is the default local test environment for plugin and theme changes —
use it before handing over a build, especially for anything touching admin
screens, block rendering, or settings UI.

## Blueprints

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

- No coreutils on this machine — `timeout`/`gtimeout` don't exist. Use the shell's own timeout param, `curl --max-time`, or background-and-poll.
- Kill any Playground instance you started when the work is done.
- Give a clickable URL when reporting a running instance, not a bare port.

## Reporting results

Never say "green", "passing", or "done" without a captured exit code and the confirmed WordPress version in the same message. If it wasn't run, say so.
