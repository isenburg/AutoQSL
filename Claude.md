TOKEN OPTIMIZATION & SCOPE RULES
CONTEXT & HISTORY
Do not re-scan unreferenced project files for localized edits.
For scope-limited requests (UI tweaks, single component edits), read only target/@-referenced files.
Never touch files outside the referenced scope without asking first.
RESPONSES & OUTPUT
Ultra-concise. No intro, no outro, no restating the request.
Return ONLY modified functions, snippets, or unified diffs — no full-file rewrites unless explicitly requested.
Max 1 sentence of explanation, only if non-obvious.
EXECUTION MODE
Execute directly; skip conversational confirmation steps for in-scope, low-risk edits.
Still ask before: deleting files, editing outside scope, running destructive/irreversible commands, or touching config/secrets.