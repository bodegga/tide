# Idea Capture System

> Lightweight wishlist for Tide Gateway features, improvements, and ideas.

## Quick Start

### 5-Second Capture
```bash
# Quick add (uses defaults)
./scripts/utils/idea quick "Add bandwidth monitoring"

# Done. Back to work.
```

### Full Add (Interactive)
```bash
./scripts/utils/idea add "Add IPv6 support" \
  --category Features \
  --priority Important \
  --description "Full IPv6 support for modern networks"
```

### Review Ideas
```bash
# List all ideas
./scripts/utils/idea list

# Show specific idea
./scripts/utils/idea show 5

# Stats overview
./scripts/utils/idea stats
```

### Complete Work
```bash
# Mark as done
./scripts/utils/idea done 5

# Convert to GitHub issue
./scripts/utils/idea export 5 > new-issue.md
```

---

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `quick <title>` | Fast add with defaults | `idea quick "Add API docs"` |
| `add <title>` | Full add with options | `idea add "RPi support" -c Platforms -p Important` |
| `list` | Show all active ideas | `idea list` |
| `show <id>` | Show idea details | `idea show 5` |
| `done <id>` | Mark as completed | `idea done 5` |
| `delete <id>` | Permanently delete | `idea delete 5` |
| `stats` | Show statistics | `idea stats` |
| `export <id>` | Export as GitHub issue | `idea export 5` |

---

## Categories

- **Features** - New functionality
- **Improvements** - Enhance existing features
- **Platforms** - New deployment targets (RPi, cloud, etc.)
- **Documentation** - Guides, tutorials, wikis
- **Infrastructure** - CI/CD, testing, automation
- **Security** - Hardening, audits, compliance
- **UX** - User experience improvements

---

## Priorities

- **Critical** - Must-have, blocking, security issues
- **Important** - Should-have, valuable features
- **Nice-to-have** - Would be cool, low priority

---

## Workflow

### During Development
1. Have an idea mid-session
2. `./scripts/utils/idea quick "Your idea here"`
3. Keep working (captured in <5 seconds)

### Weekly Review
1. `./scripts/utils/idea list` - Review all ideas
2. Pick high-value items
3. `./scripts/utils/idea export <id>` - Create GitHub issues
4. `./scripts/utils/idea done <id>` - Mark completed work

### Planning Session
1. `./scripts/utils/idea stats` - See priority breakdown
2. Focus on Critical and Important items
3. Convert top ideas to actionable tasks

---

## File Structure

```
tide/
├── IDEAS.md                    # The wishlist (human-readable)
└── scripts/utils/idea          # CLI tool (this script)
```

**IDEAS.md** is the source of truth. Edit manually or use the CLI tool.

---

## Examples

### Quick Capture During Session
```bash
# Working on gateway code, have idea for monitoring
./scripts/utils/idea quick "Add connection status indicators"

# Output:
# ✓ Added idea #16: Add connection status indicators
#   Category: Features | Priority: Nice-to-have
```

### Full Featured Add
```bash
./scripts/utils/idea add "Raspberry Pi ARM builds" \
  --category Platforms \
  --priority Important \
  --description "Build ARM images for RPi 3/4. Lightweight gateway for home networks."

# Output:
# ✓ Added idea #17: Raspberry Pi ARM builds
#   Category: Platforms | Priority: Important
```

### Review Session
```bash
./scripts/utils/idea list

# Output:
# === Active Ideas ===
#
# Features:
#   #1 - Add bandwidth monitoring dashboard
#       🟢 Nice-to-have
#   #2 - Implement kill switch for internet connectivity
#       🟡 Important
# ...
# Total: 15 ideas
```

### Convert to Task
```bash
./scripts/utils/idea export 13 > .github/ISSUE_TEMPLATE/security-audit.md

# Creates GitHub issue template ready for submission
```

---

## Design Philosophy

### Fast Capture
- **Goal:** Capture in <5 seconds
- **Why:** Don't interrupt flow state
- **How:** One-line commands, smart defaults

### Easy Review
- **Goal:** Scan 20 ideas in <1 minute
- **Why:** Weekly reviews should be painless
- **How:** Clean formatting, color coding, filters

### Actionable Output
- **Goal:** Convert idea → task easily
- **Why:** Ideas only matter if executed
- **How:** GitHub issue export, markdown format

### Low Friction
- **Goal:** Use it without thinking
- **Why:** Tools that require effort get ignored
- **How:** No dependencies, works offline, pure bash

---

## Tips

### Alias for Speed
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
alias idea='./scripts/utils/idea'
```

Now just: `idea quick "Add metrics endpoint"`

### Integration with Git
Before committing work, check if it closes an idea:
```bash
idea list
# See if your work relates to any ideas
idea done 5
git commit -m "Add bandwidth monitoring (closes idea #5)"
```

### Weekly Review Ritual
Every Monday:
```bash
cd ~/Documents/Personal-Projects/tide
idea stats              # See what's pending
idea list               # Review priorities
# Pick 2-3 Critical/Important items
# Convert to GitHub issues or start work
```

---

## Advanced Usage

### Batch Export
Export all Critical ideas as GitHub issues:
```bash
for id in $(grep -B3 "Priority: Critical" IDEAS.md | grep -o '#[0-9]*' | tr -d '#'); do
    ./scripts/utils/idea export $id > "issue-$id.md"
done
```

### Search Ideas
```bash
# Find all platform-related ideas
grep -A3 "Platforms" IDEAS.md

# Find all critical priorities
grep -B1 "Critical" IDEAS.md
```

### Custom Categories
Edit `IDEAS.md` manually to add new category sections:
```markdown
### MyCustomCategory

- [ ] **#99** - My custom idea
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Something specific to my use case
```

---

## Troubleshooting

### "Category not found"
Make sure category matches exactly (case-sensitive):
- Features
- Improvements  
- Platforms
- Documentation
- Infrastructure
- Security
- UX

### "ID not found"
Use `idea list` to see all valid IDs.

### Script not executable
```bash
chmod +x ./scripts/utils/idea
```

### macOS vs Linux sed differences
The script handles both automatically. No action needed.

---

## Why This System?

### What We Tried Before
- ❌ GitHub Issues directly - Too heavyweight for quick ideas
- ❌ TODO comments in code - Gets lost, hard to track
- ❌ Notion/Trello boards - Context switching, requires internet
- ❌ Sticky notes - Disorganized, not searchable

### What Works
- ✅ **Fast:** Terminal-native, no context switch
- ✅ **Persistent:** Git-tracked markdown file
- ✅ **Searchable:** Plain text, grep-friendly
- ✅ **Actionable:** Easy export to GitHub
- ✅ **Offline:** Works anywhere, no dependencies

---

## Philosophy

> "Ideas are cheap. Execution is everything. But capture them first."

**The goal:** Never lose a good idea because you were too busy to write it down.

**The method:** Make capture so fast you do it without thinking.

**The payoff:** When you need ideas, you have a backlog ready to execute.

---

*Built for Anthony by OpenCode. Designed to get out of your way.*
