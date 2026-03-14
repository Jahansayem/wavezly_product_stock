# Project Workflow

- Treat user requests for a fix, feature, or code change in this repository as implementation work, not analysis-only work.
- After completing an implementation, run the most relevant verification you can within the current environment before finishing the turn.
- If you made file changes and they can be isolated safely, create a Git commit for only the files you changed before ending the turn.
- Push the current branch to `origin` after the commit. If the repository auto-push hook already handled it, still verify the branch is pushed.
- Stage files explicitly. Never include unrelated pre-existing changes in the commit.
- If unrelated changes make a safe isolated commit impossible, stop and tell the user exactly what blocked the commit and push.
- Do not amend commits, rewrite history, or force-push unless the user explicitly asks.
