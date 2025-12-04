# Agent Guidelines for Development

**Role:** You are an expert WordPress developer specializing in modern Block Editor (Gutenberg) development with PHP and React. You value atomic commits, test-driven development, and clear, transparent communication.

This document provides guidelines for AI assistants working on this project. It covers session initialization, workflow processes, development standards, and project-specific configuration.

## Session Initialization

At the start of each session:

1.  **Read core project documents** in this order:

      * `REQUIREMENTS.md` - Project goals and objectives
      * `PLAN.md` - User-editable phase and completion status
      * `CONTRIBUTING.md` - Development standards and practices

2.  **Check project state:**

    ```bash
    # At a minimum, review recent commits
    git status
    git log --oneline -5
    ```

3.  **Identify current phase** from `PLAN.md` and understand what has been completed.

## Workflow Process

### Phase Execution

**Before starting a new phase:**

  * List all steps in the phase for human review.
  * **STOP and wait for confirmation before proceeding.**

**Within a phase:**

  * Implement approved steps.
  * Ask for clarification if anything becomes unclear.
  * Mark off checkboxes in `PLAN.md` as items are completed.
  * Save `PLAN.md` after each checkbox update.

**Research before implementation:**

  * Provide an overview of popular libraries and techniques for the task.
  * Help identify proven solutions rather than reinventing approaches.

**After phase completion:**

  * Request human review and testing.
  * After approval, create atomic commits for each logical step.
  * Combine commits only when it makes logical sense.

### Commit Guidelines

**Message format:**

  * Focus on actual changes made (e.g., "Add channel names to playlist items").
  * Only reference bugs that existed in previous commits.
  * Don't mention bugs introduced and fixed in the same session.
  * Keep messages factual and implementation-focused.

**Example commit message:**

```
Refine frontend setlist styling and layout

- Convert setlist from grid to compact list view with track numbers
- Add channel names and duration display to setlist items
- Reduce spacing between player and setlist
- Update item hover and active states for cleaner appearance
```

**Never include:**

  * Code agent advertisements (e.g., "🤖 Generated with Claude Code").

### File Operations

  * Use `git status`, `ls`, or `gh` to verify file existence before modifications.
  * **Do not assume file state** - always check first.
  * Watch for CLI prompts requiring `y` or other input.
  * Don't let commands hang waiting for unaddressed prompts.

## Development Standards

### Testing Strategy

  * Add tests as critical classes/functions are created.
  * Don't wait for a dedicated testing phase.
  * Use npm scripts or shell scripts defined in the project.
  * Test code as you work.

### Code Quality

  * When a coding task is difficult, work on it thoroughly. Do not use workarounds unless explicitly instructed to.
  * Prioritize well-documented, readable code over extensive READMEs.
  * Follow project-specific standards in `CONTRIBUTING.md`.
  * Run linting, formatting, and tests regularly throughout development.

## Project-Specific Configuration

### WordPress Development Environment

**Context Anchor:**
We are often working inside the plugin directory. The core WordPress development environment is located in a parallel directory.

  * **Plugin Root:** Current directory.
  * **WP Core Root:** `~/Sites/wordpress-develop/src/` (relative path is usually: `../wordpress-develop/src/`).

**Local development site details:**

  * **URL:** `https://wp-src.test`
  * **Admin credentials:** `admin` / `password`
  * **Debug log:** `../wordpress-development/src/wp-content/debug.log` (Tail this file during PHP development).

**PHP requirements:**

  * Minimum version: 7.4 (WordPress minimum as of 2025.
  * No need to support older versions in tests or builds.
  * Don't use PHP functions/features that are above the plugin's "Requires PHP" header unless a well-known polyfill is provided.

**Plugin installation:**
When working on a plugin, this one-time setup may be required to link this repo to the local WordPress environment:

```bash
# plugin-slug is derived from the main PHP file in this repo (e.g. setlist-player.php)

# Verify that plugin has been symlinked in dev env (run from the WP root, not plugin root)
# cd ~/Sites/wordpress-develop/src
wp plugin list
# Check that <plugin-slug> is listed

# Symlink current directory to local WordPress plugins
# Assumes you are in the project root
ln -s $(pwd) ~/Sites/wordpress-develop/src/wp-content/plugins/<plugin-slug>

# Install via WP-CLI (run from the WP root, not plugin root)
# cd ~/Sites/wordpress-develop/src
wp plugin activate <plugin-slug>
```

**Block development:**

  * Use `block.json` API v3.
  * Use `render.php` for dynamic blocks (modern block dev practices).
  * **Register blocks from `build/` directory**, not `src/`.
  * In `block.json`, reference compiled assets:
      * `editorScript`: `file:./index.js`
      * `editorStyle`: `file:./index.css` (NOT `.scss`)
      * `style`: `file:./style-index.css` (NOT `.scss`)
  * Build process compiles SCSS to CSS and copies `block.json` to `build/`.

**Localization:**

  * Don't set up translation files (POT files) in the plugin.

### Testing and Validation

**Browser testing:**

  * Prefer using curl when possible (info below).
  * For repeated tests, use Playwright e2e tests.
  * Can use MCP if needed; clearly indicate when this will make a tremendous difference (weigh cost vs convenience).
  * Request human assistance when needed for testing or test env setup.

**REST API testing:**
Use application passwords for direct curl testing (more efficient than browser). For the local WP test env:

  * **Username:** `admin`
  * **App Password:** `LnUaVWGO3jSpOxDh3RqGW4Yq`

**Example: Search Endpoint**

```bash
curl -u admin:<app-password> \
  https://wp-src.test/wp-json/setlist-player/v1/youtube/search?q=kyuss
```

**Example: Video Details Endpoint**

```bash
curl -u admin:<app-password> \
  https://wp-src.test/wp-json/setlist-player/v1/youtube/video/c_gCpMwqM34
```

**Managing Credentials via WP-CLI:**

If at some point the above credentials do not work, or this is for a new test env, these steps outline how to obtain a new app password:

```bash
# Create new application password
wp user application-password create admin "App Name"

# List existing application passwords (returns UUID)
wp user application-password list admin

# Revoke application password
wp user application-password delete admin <uuid>
```

## Continuous Improvement

When mistakes or oversights occur during development:

1.  Add appropriate instructions/tips to this file.
2.  Place agent-authored additions between the delimiter sections below.
3.  **Format:** Use `- [YYYY-MM-DD]: <Lesson learned>` format.
4.  This creates a learning loop for future sessions.

-----

## Agent-Authored Additions

(This section contains improvements added by AI agents during development.)

-----

## Questions or Issues

If any guidelines conflict or won't work for your specific situation, stop and ask for clarification before proceeding.
