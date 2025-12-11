# Quick Start - Idea Capture System

**Goal:** Capture ideas in <5 seconds without breaking flow.

## The Fast Way

```bash
# Add idea (uses smart defaults)
./scripts/utils/idea quick "Add status API endpoint"

# List all ideas
./scripts/utils/idea list

# See statistics
./scripts/utils/idea stats
```

That's it. You're done.

---

## Common Workflows

### During Development
```bash
# Have an idea mid-coding session
./scripts/utils/idea quick "Add RPi support"

# Back to work (captured in 3 seconds)
```

### Weekly Review
```bash
# Monday morning - review backlog
./scripts/utils/idea list
./scripts/utils/idea stats

# Pick 2-3 high-value items to work on
```

### Convert to Task
```bash
# Export as GitHub issue template
./scripts/utils/idea export 5

# Or create issue directly
./scripts/utils/idea export 5 | gh issue create --title "Add RPi support" --body-file -
```

### Mark Complete
```bash
# When you've built the feature
./scripts/utils/idea done 5
```

---

## Full Options

```bash
# Add with all metadata
./scripts/utils/idea add "Add IPv6 support" \
  --category Features \
  --priority Critical \
  --description "Full dual-stack IPv6 support"

# Show specific idea
./scripts/utils/idea show 5

# Delete idea
./scripts/utils/idea delete 5
```

---

## Categories

Features | Improvements | Platforms | Documentation | Infrastructure | Security | UX

**Default:** Features (when using `quick`)

---

## Priorities

🔴 **Critical** - Must-have, blocking, security issues  
🟡 **Important** - Should-have, valuable features  
🟢 **Nice-to-have** - Would be cool, low priority  

**Default:** Nice-to-have (when using `quick`)

---

## Files

- **`IDEAS.md`** - The wishlist (human-readable)
- **`./scripts/utils/idea`** - CLI tool (this script)
- **`docs/IDEA-CAPTURE-GUIDE.md`** - Full documentation
- **`scripts/utils/README-IDEA-SYSTEM.md`** - System design docs

---

## Shell Alias (Optional)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias idea='~/Documents/Personal-Projects/tide/scripts/utils/idea'
```

Now from anywhere: `idea quick "My great idea"`

---

## Philosophy

> "Ideas are cheap. Execution is everything. But capture them first."

**Fast capture** → **Weekly review** → **Convert to tasks** → **Execute**

---

## Help

```bash
./scripts/utils/idea help
```

Full docs: `docs/IDEA-CAPTURE-GUIDE.md`

---

**Built to get out of your way. Use it.**
