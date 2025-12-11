# Tide Gateway - Idea Capture System Guide

> Quick reference for capturing ideas without breaking flow.

## TL;DR

```bash
# During development - have an idea
./scripts/utils/idea quick "Add status endpoint"

# Weekly - review ideas
./scripts/utils/idea list

# Ready to build - create task
./scripts/utils/idea export 5 | gh issue create --title "Add Raspberry Pi support" --body-file -
```

---

## Why This Exists

**Problem:** During development sessions, you have great ideas but don't want to:
- Stop coding to document them properly
- Lose them because you forgot
- Clutter your code with TODO comments
- Context-switch to GitHub/Notion/etc.

**Solution:** Terminal-native idea capture in <5 seconds.

---

## The 3 Workflows

### 1. Capture (During Development)

You're deep in code. An idea hits. Capture it:

```bash
./scripts/utils/idea quick "Add bandwidth graphs to dashboard"
```

**Time cost:** 3 seconds  
**Context switch:** Zero  
**Ideas saved:** All of them

### 2. Review (Weekly Planning)

Every Monday, review your backlog:

```bash
# See what you've captured
./scripts/utils/idea list

# Check priority breakdown
./scripts/utils/idea stats

# Review specific idea
./scripts/utils/idea show 5
```

Pick 2-3 high-value items to work on this week.

### 3. Execute (Convert to Tasks)

Ready to build? Convert idea to GitHub issue:

```bash
# Export as markdown
./scripts/utils/idea export 5 > raspberry-pi-support.md

# Or create GitHub issue directly
./scripts/utils/idea export 5 | gh issue create \
  --title "Add Raspberry Pi support" \
  --label enhancement \
  --body-file -

# Mark as done when implemented
./scripts/utils/idea done 5
```

---

## Command Reference

### Quick Commands (Use These Most)

```bash
# Fast capture
idea quick "Your idea here"

# List all ideas
idea list

# Show statistics
idea stats
```

### Full Commands (When You Need Details)

```bash
# Full add with metadata
idea add "Add IPv6 support" \
  --category Features \
  --priority Critical \
  --description "Full dual-stack support for modern networks"

# Show specific idea
idea show 5

# Export to GitHub
idea export 5

# Mark complete
idea done 5

# Delete idea
idea delete 5
```

---

## Categories Explained

| Category | Use For | Examples |
|----------|---------|----------|
| **Features** | New functionality | API endpoints, monitoring, kill switches |
| **Improvements** | Enhance existing | Better error handling, faster startup |
| **Platforms** | Deployment targets | Raspberry Pi, cloud providers, ARM builds |
| **Documentation** | Guides/tutorials | Video series, troubleshooting docs |
| **Infrastructure** | Dev workflow | CI/CD, testing, automation |
| **Security** | Hardening/audits | Penetration testing, compliance |
| **UX** | User experience | Better CLI output, web dashboard |

**Default:** Features (when using `quick` command)

---

## Priority Levels

| Priority | Meaning | When to Use |
|----------|---------|-------------|
| **Critical** 🔴 | Must-have, blocking | Security issues, breaking bugs, core features |
| **Important** 🟡 | Should-have, valuable | High-value features, significant improvements |
| **Nice-to-have** 🟢 | Would be cool | Polish, extras, experimental ideas |

**Default:** Nice-to-have (when using `quick` command)

---

## Integration with Git

### Before Committing
Check if your work closes an idea:

```bash
idea list
# See if current work relates to any ideas
git commit -m "Add bandwidth monitoring (closes idea #1)"
idea done 1
```

### In Commit Messages
Reference ideas for context:

```bash
git commit -m "Implement kill switch feature

Adds automatic internet cutoff when Tor connection drops.
Configurable strict/relaxed modes.

Related to idea #2"
```

---

## Integration with GitHub

### Manual Issue Creation

```bash
# 1. Export idea
./scripts/utils/idea export 6 > issue.md

# 2. Review/edit issue.md

# 3. Create issue via gh CLI
gh issue create --title "Add Raspberry Pi support" --body-file issue.md

# 4. Mark idea as in-progress or done
./scripts/utils/idea done 6
```

### Automated Issue Creation

```bash
# Create issue directly from idea
./scripts/utils/idea export 6 | gh issue create \
  --title "$(./scripts/utils/idea show 6 | grep Title: | cut -d: -f2-)" \
  --label enhancement \
  --body-file -
```

### Batch Export All Critical Ideas

```bash
# Get all Critical priority idea IDs
for id in $(grep -B3 "Priority: Critical" IDEAS.md | grep -o '#[0-9]*' | tr -d '#'); do
    echo "Creating issue for idea #$id..."
    ./scripts/utils/idea export $id | gh issue create \
      --title "$(./scripts/utils/idea show $id | grep Title: | cut -d: -f2- | xargs)" \
      --label critical \
      --body-file -
    ./scripts/utils/idea done $id
done
```

---

## Best Practices

### ✅ Do This

- **Capture immediately** - Don't wait, don't forget
- **Use quick command** - Defaults are fine for capture
- **Review weekly** - Make it a ritual (Monday mornings)
- **Convert before building** - Turn ideas into tracked tasks
- **Mark as done** - Clean up completed ideas

### ❌ Avoid This

- **Don't overthink categories** - Use defaults, refine later
- **Don't edit manually** - Use CLI tool for consistency
- **Don't ignore ideas** - Review regularly or they pile up
- **Don't skip marking done** - Completion feels good

---

## Example Session

### Development Session

```bash
# Working on gateway improvements
cd ~/Documents/Personal-Projects/tide

# ... coding ...

# Idea hits: "What if we had a status API?"
./scripts/utils/idea quick "Add REST API for gateway status"
# ✓ Added idea #16

# Back to coding immediately

# ... more coding ...

# Another idea: "RPi would be perfect for this"
./scripts/utils/idea quick "Build ARM images for Raspberry Pi"
# ✓ Added idea #17

# Continue working, ideas are safe
```

### Planning Session

```bash
# Monday morning - planning week
./scripts/utils/idea stats
# === Statistics ===
# Total Active: 17
# Critical: 2
# Important: 7
# Nice-to-have: 8

# Review critical items
./scripts/utils/idea list | grep Critical
# #3 - DNS leak protection validation
# #13 - Security audit checklist

# Decide to work on idea #3 this week
./scripts/utils/idea show 3
# Shows full details

# Convert to GitHub issue
./scripts/utils/idea export 3 | gh issue create \
  --title "DNS leak protection validation" \
  --label security,critical \
  --body-file -

# Start working...
```

### Completion Flow

```bash
# Finished implementing idea #3
git commit -m "Add DNS leak protection tests (closes idea #3)"
git push

# Mark idea as done
./scripts/utils/idea done 3
# ✓ Marked idea #3 as done

# Close GitHub issue
gh issue close <issue-number>
```

---

## Advanced Tips

### Shell Alias
Add to `~/.bashrc` or `~/.zshrc`:

```bash
alias idea='~/Documents/Personal-Projects/tide/scripts/utils/idea'
```

Now from anywhere:
```bash
idea quick "Cool idea I just had"
```

### Quick Stats in Prompt
Show idea count in your shell prompt:

```bash
# Add to ~/.bashrc
export PS1="[$(~/path/to/tide/scripts/utils/idea stats 2>/dev/null | grep 'Total Active' | cut -d: -f2 | xargs) ideas] $ "
```

### Search Ideas
```bash
# Find all platform ideas
grep -A3 "### Platforms" IDEAS.md

# Find all critical items
grep -B1 "Critical" IDEAS.md

# Full-text search
grep -i "bandwidth" IDEAS.md
```

### Export All Ideas
```bash
# Create JSON dump
./scripts/utils/idea list > ideas-backup-$(date +%Y%m%d).txt
```

---

## Files

| File | Purpose | Edit? |
|------|---------|-------|
| `IDEAS.md` | The wishlist | Via CLI or manually |
| `scripts/utils/idea` | CLI tool | No (it's the tool) |
| `scripts/utils/README-IDEA-SYSTEM.md` | System docs | Reference only |
| `docs/IDEA-CAPTURE-GUIDE.md` | This file | Reference only |

---

## Troubleshooting

### Command not found
```bash
# Make sure script is executable
chmod +x ~/Documents/Personal-Projects/tide/scripts/utils/idea

# Or use full path
./scripts/utils/idea help
```

### Category not found
Categories are case-sensitive. Valid options:
- Features
- Improvements
- Platforms
- Documentation
- Infrastructure
- Security
- UX

### Can't find idea number
```bash
# List all IDs
./scripts/utils/idea list
```

### Want to edit IDEAS.md manually
Go ahead! It's just markdown. The CLI tool parses it.

---

## Philosophy

### Speed Over Perfection
Capture quickly with defaults. Refine later if needed.

```bash
# Fast (DO THIS)
idea quick "Add API endpoint"

# Slow (AVOID)
# [Opens editor, writes detailed spec, categorizes, prioritizes]
```

### Weekly Review Ritual
Ideas are worthless if never reviewed.

**Every Monday:**
1. Run `idea stats`
2. Run `idea list`
3. Pick 2-3 high-value items
4. Convert to tasks or GitHub issues
5. Execute

### Completion Matters
Seeing ideas move to "Done" is motivating.

```bash
# Always mark as done when implemented
idea done 5
```

### Ideas → Tasks → Code
The pipeline:
1. **Capture** - Quick add during development
2. **Review** - Weekly planning session
3. **Prioritize** - Pick high-value items
4. **Convert** - Create GitHub issues
5. **Execute** - Build the feature
6. **Complete** - Mark idea as done

---

## Quick Reference Card

```
CAPTURE
  idea quick "Your idea"

REVIEW
  idea list
  idea stats
  idea show <id>

EXECUTE
  idea export <id>
  idea done <id>

DELETE
  idea delete <id>

HELP
  idea help
```

---

## Success Metrics

You're using this system successfully if:

✅ You capture ideas without breaking flow  
✅ You review ideas weekly  
✅ You convert high-value ideas to tasks  
✅ You mark completed ideas as done  
✅ You never lose a good idea again

---

*Built for developers who want to stay in flow.*

**Fast. Simple. Effective.**
