# Maintenance Guide for Tide Gateway

This guide covers ongoing maintenance tasks, issue handling, and keeping the project healthy.

---

## 📋 Daily/Weekly Tasks

### Monitor GitHub Activity

**Daily** (if active development):
- [ ] Check new issues
- [ ] Respond to questions
- [ ] Review pull requests
- [ ] Monitor discussions

**Weekly**:
- [ ] Triage open issues
- [ ] Update project board
- [ ] Close stale issues
- [ ] Merge ready PRs

### Quick Commands

```bash
# See open issues
gh issue list

# See open PRs
gh pr list

# Check recent activity
gh api /repos/bodegga/tide/events | jq '.[0:10]'

# View download stats
gh release list
```

---

## 🐛 Issue Management

### Issue Triage Process

**1. New Issue Arrives**
- [ ] Thank reporter
- [ ] Add appropriate labels
- [ ] Ask for clarification if needed
- [ ] Reproduce if it's a bug

**2. Labeling System**

| Label | When to Use |
|-------|-------------|
| `bug` | Something isn't working |
| `enhancement` | New feature request |
| `documentation` | Docs improvements |
| `question` | User asking for help |
| `security` | Security-related issue |
| `good first issue` | Easy for new contributors |
| `help wanted` | Looking for contributors |
| `wontfix` | Not going to address |
| `duplicate` | Already reported |
| `invalid` | Not a real issue |

**3. Priority Labels**

| Label | Meaning | Response Time |
|-------|---------|---------------|
| `critical` | Blocks usage | < 24 hours |
| `high` | Important but not blocking | < 1 week |
| `medium` | Would be nice | < 1 month |
| `low` | Someday/maybe | No timeline |

**4. Close Issues When**
- [ ] Bug is fixed and released
- [ ] Feature is implemented
- [ ] Question is answered
- [ ] Duplicate of another issue
- [ ] Invalid or won't fix

### Issue Templates

GitHub issue templates in `.github/ISSUE_TEMPLATE/`:

**bug_report.md:**
```markdown
---
name: Bug report
about: Report a bug to help us improve
---

**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Deploy Tide Gateway using '...'
2. Configure '...'
3. Run '...'
4. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- Tide version: [e.g. v1.1.1]
- Hypervisor: [e.g. Parallels, QEMU, bare-metal]
- Host OS: [e.g. macOS 14.1, Ubuntu 22.04]
- Deployment mode: [e.g. Killa Whale]

**Logs**
```
Paste relevant logs here
```

**Additional context**
Any other details.
```

**feature_request.md:**
```markdown
---
name: Feature request
about: Suggest a new feature
---

**Problem Statement**
What problem does this solve?

**Proposed Solution**
How would this feature work?

**Alternatives Considered**
What other approaches did you think about?

**Additional Context**
Any mockups, examples, or references.
```

---

## 🔒 Security Issue Handling

### Private Disclosure

**If someone reports a security vulnerability:**

1. **Respond Privately**
   ```
   Thank you for the responsible disclosure. 
   I'm investigating this and will keep you updated.
   Please do not disclose publicly until we have a fix.
   ```

2. **Verify the Vulnerability**
   - [ ] Reproduce the issue
   - [ ] Assess severity (Critical, High, Medium, Low)
   - [ ] Determine affected versions

3. **Develop Fix**
   - [ ] Create private branch
   - [ ] Implement fix
   - [ ] Test thoroughly
   - [ ] Prepare patch

4. **Coordinate Disclosure**
   - [ ] Agree on disclosure timeline (typically 90 days)
   - [ ] Prepare security advisory
   - [ ] Request CVE (if applicable)

5. **Release Fix**
   - [ ] Release patch version (e.g., v1.1.2)
   - [ ] Mark as security update
   - [ ] Publish security advisory
   - [ ] Update SECURITY.md

6. **Thank Researcher**
   - [ ] Credit in release notes (if they want)
   - [ ] Add to security hall of fame (if you have one)

### Using GitHub Security Advisories

```bash
# Create security advisory (via GitHub web UI)
# Settings → Security → Security advisories → New draft

# Or via API
gh api -X POST /repos/bodegga/tide/security-advisories \
  --field summary="Security issue in Tor config" \
  --field description="Details..." \
  --field severity="high"
```

---

## 🔄 Dependency Updates

### Regular Dependency Checks

**Monthly:**
- [ ] Check for Alpine Linux updates
- [ ] Check for Tor updates
- [ ] Update all documentation if needed

**Commands:**

```bash
# Check Alpine package versions
docker run alpine:3.21 apk update && apk list --upgrades

# Check Tor version
curl -s https://www.torproject.org/download/ | grep "Tor Browser"
```

### Update Process

1. **Test in Staging**
   - [ ] Build VM with new versions
   - [ ] Test all deployment modes
   - [ ] Verify Tor routing works

2. **Document Changes**
   - [ ] Update CHANGELOG.md
   - [ ] Note any breaking changes
   - [ ] Update version dependencies

3. **Release**
   - [ ] Bump version (PATCH for compatible, MAJOR for breaking)
   - [ ] Create release
   - [ ] Notify users

---

## 📊 Project Health Metrics

### Things to Monitor

**GitHub Insights:**
- Open issue count (keep < 20)
- Open PR count (keep < 5)
- Issue response time (target < 48 hours)
- PR merge time (target < 1 week)

**Release Metrics:**
- Download count per release
- Time between releases (target: 1-2 months)
- Bug fix rate (closed bugs vs opened)

**Community Engagement:**
- Stars/forks growth
- Contributors count
- Discussion activity

### Dashboard

Create a simple dashboard:

```bash
#!/bin/bash
# project-health.sh

echo "=== Tide Gateway Health Check ==="
echo ""

# Issues
OPEN_ISSUES=$(gh issue list --state open --json number | jq length)
echo "Open Issues: $OPEN_ISSUES"

# PRs
OPEN_PRS=$(gh pr list --state open --json number | jq length)
echo "Open PRs: $OPEN_PRS"

# Stars
STARS=$(gh api /repos/bodegga/tide | jq .stargazers_count)
echo "Stars: $STARS"

# Latest release downloads
LATEST_DL=$(gh release view --json assets | jq '[.assets[].downloadCount] | add')
echo "Latest Release Downloads: $LATEST_DL"

# Days since last release
LAST_RELEASE=$(gh release list --limit 1 --json publishedAt | jq -r '.[0].publishedAt')
DAYS_SINCE=$(( ($(date +%s) - $(date -d "$LAST_RELEASE" +%s)) / 86400 ))
echo "Days Since Last Release: $DAYS_SINCE"

echo ""
if [ $OPEN_ISSUES -gt 20 ]; then
  echo "⚠️  Warning: Too many open issues"
fi

if [ $DAYS_SINCE -gt 60 ]; then
  echo "⚠️  Warning: No release in 60+ days"
fi
```

---

## 📝 Documentation Maintenance

### Keep Docs Updated

**When to update docs:**
- After every release (CHANGELOG, VERSION)
- When features are added (README, guides)
- When bugs are discovered (troubleshooting)
- When questions are repeated (FAQ)

**Documentation Checklist:**
- [ ] README.md accurate
- [ ] CHANGELOG.md complete
- [ ] All guides tested and working
- [ ] Links not broken
- [ ] Screenshots up-to-date
- [ ] Version badges current

**Check for broken links:**

```bash
# Install markdown-link-check
npm install -g markdown-link-check

# Check all markdown files
find . -name "*.md" -exec markdown-link-check {} \;
```

---

## 🧹 Repository Cleanup

### Monthly Cleanup Tasks

**Close Stale Issues:**

```bash
# List issues with no activity in 60 days
gh issue list --state open --json number,title,updatedAt \
  | jq -r '.[] | select(.updatedAt < (now - 60*86400 | strftime("%Y-%m-%d"))) | "#\(.number) \(.title)"'

# Add "stale" label
gh issue edit {NUMBER} --add-label "stale"

# Close with message
gh issue close {NUMBER} --comment "Closing due to inactivity. Please reopen if still relevant."
```

**Archive Old Branches:**

```bash
# List merged branches
git branch --merged main | grep -v "main"

# Delete merged branches
git branch --merged main | grep -v "main" | xargs git branch -d

# Push deletions
git push origin --delete {branch-name}
```

**Clean Release Artifacts:**

- [ ] Review old release assets
- [ ] Remove superseded pre-releases
- [ ] Keep stable releases indefinitely

---

## 🔄 Continuous Integration

### If You Add CI/CD

**GitHub Actions workflow (.github/workflows/test.yml):**

```yaml
name: Test Tide Gateway

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Test installer script
        run: |
          bash -n tide-install.sh  # Syntax check
          
      - name: Test deployment scripts
        run: |
          bash -n DEPLOY-TEMPLATE.sh
          bash -n ONE-COMMAND-DEPLOY.sh
          
      - name: Validate markdown
        uses: gaurav-nelson/github-action-markdown-link-check@v1
```

**Maintain CI:**
- [ ] Keep actions up-to-date
- [ ] Fix failing builds promptly
- [ ] Add tests for new features

---

## 📢 Communication

### Release Announcements

**Where to announce:**
- [x] GitHub Release Notes
- [ ] Twitter/X (if you have account)
- [ ] Reddit r/privacy, r/tor (if appropriate)
- [ ] Hacker News (if significant release)
- [ ] Personal blog (if you have one)

**Template:**

```
🌊 Tide Gateway v1.X.X Released!

New features:
- Feature 1
- Feature 2

Download: https://github.com/bodegga/tide/releases/latest
Docs: https://github.com/bodegga/tide

#privacy #tor #opensource #security
```

### Community Engagement

**Respond to mentions:**
```bash
# Search for Tide mentions
gh search repos "tide gateway"
gh search issues "tide gateway"
```

**Be responsive:**
- Respond to issues within 48 hours
- Acknowledge PRs within 1 week
- Thank contributors publicly

---

## 🎯 Quarterly Tasks

### Every 3 Months

**1. Review Roadmap**
- [ ] Update ROADMAP.md
- [ ] Close completed items
- [ ] Add new planned features
- [ ] Solicit community feedback

**2. Dependency Audit**
- [ ] Review all dependencies
- [ ] Check for security advisories
- [ ] Update where needed
- [ ] Test thoroughly

**3. Documentation Audit**
- [ ] Read all docs start to finish
- [ ] Fix outdated information
- [ ] Add missing sections
- [ ] Improve unclear parts

**4. Code Cleanup**
- [ ] Review TODOs in code
- [ ] Remove obsolete scripts
- [ ] Refactor messy parts
- [ ] Update comments

**5. Community Health**
- [ ] Review contributor guidelines
- [ ] Update code of conduct (if needed)
- [ ] Thank active contributors
- [ ] Recruit new maintainers (if project grows)

---

## 🏆 Recognition

### Thank Contributors

**In Releases:**
```markdown
## Contributors

Thanks to everyone who contributed to this release:

- @username - Fixed critical bug (#123)
- @username2 - Improved documentation (#124)
- @username3 - Tested beta release
```

**GitHub Insights:**
```bash
# List contributors
gh api /repos/bodegga/tide/contributors | jq '.[] | {login, contributions}'

# Create contributors list for README
gh api /repos/bodegga/tide/contributors \
  | jq -r '.[] | "- [@\(.login)](\(.html_url)) - \(.contributions) contributions"'
```

---

## 🚨 Emergency Response

### If Something Breaks in Production

**1. Immediate Response (< 1 hour)**
- [ ] Acknowledge the issue publicly
- [ ] Assess severity
- [ ] Determine affected versions
- [ ] Add "critical" label

**2. Mitigation (< 4 hours)**
- [ ] Provide workaround if possible
- [ ] Update documentation with warning
- [ ] Begin working on fix

**3. Fix (< 24 hours for critical)**
- [ ] Develop and test fix
- [ ] Create hotfix release
- [ ] Update all documentation
- [ ] Announce fix

**4. Post-Mortem**
- [ ] Document what happened
- [ ] Explain why it happened
- [ ] Describe how it was fixed
- [ ] Detail steps to prevent recurrence

**Template post-mortem:**

```markdown
# Post-Mortem: [Issue Title]

## Summary
Brief description of the incident.

## Timeline
- HH:MM - Issue first reported
- HH:MM - Acknowledged and began investigation
- HH:MM - Root cause identified
- HH:MM - Fix deployed
- HH:MM - Verified resolved

## Root Cause
What actually caused the problem.

## Impact
Who/what was affected.

## Resolution
How it was fixed.

## Prevention
Steps taken to prevent recurrence.

## Lessons Learned
What we learned from this.
```

---

## 🛠️ Maintenance Scripts

### Helpful Automation

**check-project-health.sh:**
```bash
#!/bin/bash
# Comprehensive project health check

echo "=== Tide Gateway Health Check ==="
date

# GitHub metrics
echo -e "\n=== GitHub Metrics ==="
echo "Open Issues: $(gh issue list --state open --json number | jq length)"
echo "Open PRs: $(gh pr list --state open --json number | jq length)"
echo "Stars: $(gh api /repos/bodegga/tide | jq .stargazers_count)"
echo "Forks: $(gh api /repos/bodegga/tide | jq .forks_count)"

# Release info
echo -e "\n=== Latest Release ==="
gh release view --json tagName,publishedAt,assets \
  | jq -r '"Version: \(.tagName)\nPublished: \(.publishedAt)\nAssets: \(.assets | length)"'

# Stale issues
echo -e "\n=== Stale Issues (60+ days) ==="
gh issue list --state open --json number,title,updatedAt \
  | jq -r --arg cutoff "$(date -d '60 days ago' +%Y-%m-%d)" \
    '.[] | select(.updatedAt < $cutoff) | "#\(.number) - \(.title)"' \
  | head -10

# Recent commits
echo -e "\n=== Recent Commits ==="
git log -5 --oneline

echo -e "\n✅ Health check complete"
```

**update-version-references.sh:**
```bash
#!/bin/bash
# Update version across all files

if [ -z "$1" ]; then
  echo "Usage: $0 <new-version>"
  exit 1
fi

NEW_VERSION=$1

echo "Updating to v$NEW_VERSION..."

# Update VERSION file
echo "$NEW_VERSION" > VERSION

# Update README badge
sed -i '' "s/version-[0-9.]*-green/version-$NEW_VERSION-green/" README.md

# Update any scripts with embedded versions
find . -type f -name "*.sh" -exec sed -i '' "s/VERSION=\"[0-9.]*\"/VERSION=\"$NEW_VERSION\"/" {} \;

# Show changes
git diff

echo "✅ Version updated to v$NEW_VERSION"
echo "Review changes above, then commit."
```

---

## 📚 Resources

### Maintainer Resources

- **GitHub Docs**: https://docs.github.com/en/repositories
- **Semantic Versioning**: https://semver.org/
- **Keep a Changelog**: https://keepachangelog.com/
- **Open Source Guides**: https://opensource.guide/
- **Code of Conduct**: https://www.contributor-covenant.org/

### Tools

- **gh CLI**: GitHub command line tool
- **markdown-link-check**: Check for broken links
- **shellcheck**: Bash script linting
- **prettier**: Markdown formatting

---

## 🎓 Best Practices

### Do's ✅

- **Respond promptly** to issues and PRs
- **Be kind** and welcoming to all
- **Document decisions** in issues/PRs
- **Keep releases regular** (monthly or bi-monthly)
- **Thank contributors** publicly
- **Maintain high code quality**
- **Write clear commit messages**
- **Test before releasing**

### Don'ts ❌

- **Don't ignore** security issues
- **Don't delete** issues/PRs unless spam
- **Don't rush** releases
- **Don't be dismissive** of feedback
- **Don't let issues pile up**
- **Don't forget** to update docs
- **Don't break** semantic versioning

---

## 📞 When You Need Help

**Feeling overwhelmed?**

1. **Take a break** - It's okay to pause
2. **Ask for help** - Recruit co-maintainers
3. **Set boundaries** - You don't owe anyone 24/7 support
4. **Automate** - Use bots and CI/CD
5. **Document** - Make it easier for others to help

**Burnout prevention:**
- Set expectations in README (response times)
- Use GitHub's "limited availability" feature
- Take breaks between releases
- Don't feel guilty about saying "no"

---

**Remember:** You built something cool and shared it with the world. That's already awesome. Maintenance is important, but your wellbeing comes first.

---

*Last updated: 2025-12-09*  
*Tide Gateway - freedom within the shell* 🌊
