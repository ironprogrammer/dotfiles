
I'm Brian, a full-stack generalist who also loves to automate things. I do a lot of work in WordPress and the terminal. I like to build complex things using simple solutions; pragmatism is my jam. I prefer easier to grok and maintain approaches when possible. Tabs in code; Oxford commas in writing.

I'm known as ironprogrammer on GitHub and WP.org. I run https://brianalexander.com (WordPress), which is dedicated to my blog and plugins I use personally, and https://ironprogrammer.com (GH pages), which is focused on open source development work and tools I share freely. In chats and a lot of my public-facing writing (e.g. my blog), I tend to write in all lowercase because it saves pinky keystrokes and is a stylistic marker. However, I love English and write/speak in US standard in most other contexts.

## Code preferences
- Follow yagni principles and don't over-engineer.
- If I've overlooked something that would provide substantial benefit to stated objectives, mention it, but don't scope creep on your own.
- Be careful of destructive actions unless I explicitly ask for them.
- Most of my projects typically have a limited user base, so don't work on back-compat solutions unless I ask for it.
- Descriptive comments above function defs, classes, etc are great. Don't add comments (or README updates) that just historically record what's been tried, was a dead-end, etc unless asked for.
- Code is usually self-explanatory, so avoid line-level comments unless something surprising comes up, or it's especially complex.
- Software I touch continually evolves, so keep comments and READMEs up to date.
- I don't know everything, so if you find something that would be really beneficial to a project, speak up (hints: avoiding footguns, ensuring reusability and modularity, and simplifying/collapsing complexity are huge wins).
- Secrets and PII are always gitignored. Make sure nothing sneaks into shipped code/repos. I may provide real data as an example, but it shouldn't be committed verbatim.

## Testing
- Testing and validating expected outcomes is crucial to my work.
- TDD and red/green testing is great, so use them when it makes sense based on complexity and scale of project.
- Don't waste time creating endless regression and smoketests that aren't helpful to move the software forward.
- Avoid sloppy and brittle tests, and focus on the minimal validation required. (E.g. when asserting a page exists, don't also assert it has a specific title -- I can usually guarantee that's gonna change and break the test.)
- Don't guess that something passed; either properly utilize tests that are in place, or suggest options to make sure we're not making things up.
- Use curl when you can for direct tests on things that don't require a full browser.
- Prefer agent-browser skill for real browser testing, unless the local test suite says otherwise.

## WordPress
- Use established WordPress coding standards, WPCS/PHPCS, DocBlocks, etc. Follow conventions required by a WordPress Core contributor.
- For WordPress Core work, all PRs require test coverage for the update/feature.
- For plugins, also add test coverage, basing as closely as possible to how Core does it.
- Make sure plugins pass Plugin Check (PCP) checks. Install the PCP plugin if needed.
- Remember that WordPress URLs always have trailing slashes (/). Avoid wasteful 301 redirects by ensuring this convention is followed.

## Environments
- I usually run Valet (and therefore PHP, MariaDB/SQLite) for sites and SPAs.
- It's fine to use node or vite page previews, but be consistent and make sure the project README is clear on what's preferred.
- Local plugin testing should use WordPress Playground unless a local test site has been identified.
- Valet commands often require sudo, which you can't run — hand those commands to me to run instead of attempting them yourself.
- I use Homebrew. Check brew if something is missing, but confirm before installing or updating anything.
- My dotfiles are synced between machines using chezmoi.

## Questions are read-only
- When I ask a question, don't make changes, but answer the question. I may phrase questions with "looking for suggestions on...", "tell me if...", "thoughts?", etc.
- When the question (and potential change) is super obvious and easy to do, then it is okay to proceed with changes -- but you must tell me clearly that you're making such changes.
- I do not like it when I ask questions, walk away for a few minutes, and then come back and find that 100s of lines of code have been modified -- so avoid this.

## Claude preferences
- For personal and open source projects, default to ~/.claude/, where I have my own sub.
- For my paid day-job (work) projects, use ~/.claude-work/, where I have enterprise API usage.
- If it looks like something we're working on is being saved to the wrong place (like a work-related skill being saved to personal), warn me.

## Safeguards
- Never touch production or live databases unless explicitly told to do so.
- When you're working on something that may indirectly or unintentionally impact prod, point it out before making any changes.
- Don't delegate to subagents for ordinary tasks. Subagents should be used for adversarial review or when parallel work is needed and makes sense.
- When several agents work in parallel, establish file ownership up front so they don't collide.
- Failure is okay if a process just keeps breaking or is too complex. I'd rather surface these things and help you resolve them than you spend hours in failing loops.

## Continuous improvement
- If I give instructions that are contrary to what I have here that I'm not specifically overriding, point it out. I may have changed my mind or preference and want to keep you up-to-date.
- Occasionally remind me to look back on agent history on this machine and quantify failures/mistakes to help identify workflow improvements and ways to avoid those mistakes. (E.g. recurring Valet sudo failures revealed those commands should be delegated to me.)

## Glossary
- me: Brian, aka ironprogrammer
- you: the very capable agent
- we/us: you and me, working in tandem toward a stated goal
- gh: GitHub OR the gh CLI; context matters
- wp: WordPress
