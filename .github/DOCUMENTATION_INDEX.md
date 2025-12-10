# Tide Gateway Documentation Index

Complete guide to all documentation in this repository.

---

## 📚 For Users

### Getting Started
- **[README.md](../README.md)** - Project overview and quick start
- **[START-HERE.md](../START-HERE.md)** - First-time user guide
- **[DEPLOYMENT-GUIDE.md](../DEPLOYMENT-GUIDE.md)** - Deployment instructions
- **[FRESH-INSTALL-GUIDE.md](../FRESH-INSTALL-GUIDE.md)** - Manual installation

### Understanding Tide
- **[CHANGELOG.md](../CHANGELOG.md)** - Version history and changes
- **[HISTORY.md](../HISTORY.md)** - Complete development narrative
- **[ROADMAP.md](../ROADMAP.md)** - Future plans and features

### Security
- **[SECURITY.md](../SECURITY.md)** - Security policy and reporting
- **[docs/KILLA-WHALE-MODE-WARNING.md](../docs/KILLA-WHALE-MODE-WARNING.md)** - Legal and safety warnings

---

## 🛠️ For Contributors

### Contributing
- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - How to contribute
- **[LICENSE](../LICENSE)** - MIT License terms

### Development
- **[.github/VERSIONING.md](VERSIONING.md)** - Version numbering guide
- **[.github/RELEASE_PROCESS.md](RELEASE_PROCESS.md)** - How to create releases
- **[.github/MAINTENANCE.md](MAINTENANCE.md)** - Ongoing maintenance tasks

### Templates
- **[.github/release-template.md](release-template.md)** - Release notes template

---

## 📖 Technical Documentation

### Build Docs (dev-docs/)
- **[dev-docs/BUILD_INSTRUCTIONS.md](../dev-docs/BUILD_INSTRUCTIONS.md)** - How to build from source
- **[dev-docs/PARALLELS_BUILD.md](../dev-docs/PARALLELS_BUILD.md)** - Parallels VM building
- **[dev-docs/QUICK_BUILD.md](../dev-docs/QUICK_BUILD.md)** - Quick build guide
- **[dev-docs/AUTO_BUILD.md](../dev-docs/AUTO_BUILD.md)** - Automated build process

### Client Documentation (client/)
- **[client/README.md](../client/README.md)** - Client overview
- **[client/QUICKSTART.md](../client/QUICKSTART.md)** - Client quick start
- **[client/README-CLIENTS.md](../client/README-CLIENTS.md)** - Client apps guide

### Archived Docs (_dev-archive/)
Historical documentation from early development. For reference only.

---

## 🗂️ File Organization

```
tide/
├── README.md                    # Project overview
├── CHANGELOG.md                 # Version history ✨ NEW
├── HISTORY.md                   # Development narrative ✨ NEW
├── VERSION                      # Current version ✨ NEW
├── CONTRIBUTING.md              # Contribution guide
├── LICENSE                      # MIT License
├── SECURITY.md                  # Security policy
├── ROADMAP.md                   # Future plans
├── START-HERE.md                # Quick start
├── DEPLOYMENT-GUIDE.md          # Deployment instructions
├── FRESH-INSTALL-GUIDE.md       # Manual install
│
├── .github/                     # GitHub-specific files
│   ├── DOCUMENTATION_INDEX.md   # This file ✨ NEW
│   ├── VERSIONING.md            # Version guide ✨ NEW
│   ├── RELEASE_PROCESS.md       # Release checklist ✨ NEW
│   ├── MAINTENANCE.md           # Maintenance guide ✨ NEW
│   ├── release-template.md      # Release template ✨ NEW
│   └── tide-social-preview.png  # Social media image
│
├── docs/                        # Additional documentation
│   ├── KILLA-WHALE-MODE-WARNING.md
│   └── OPSEC-VM_ARCHIVE.md
│
├── dev-docs/                    # Development documentation
│   ├── BUILD_INSTRUCTIONS.md
│   ├── PARALLELS_BUILD.md
│   ├── QUICK_BUILD.md
│   └── AUTO_BUILD.md
│
├── client/                      # Client application docs
│   ├── README.md
│   ├── QUICKSTART.md
│   └── README-CLIENTS.md
│
└── _dev-archive/                # Historical docs (reference)
    └── [various archived files]
```

---

## 🎯 Documentation by Audience

### I'm a New User
Start here:
1. [README.md](../README.md) - Understand what Tide does
2. [START-HERE.md](../START-HERE.md) - Get started quickly
3. [DEPLOYMENT-GUIDE.md](../DEPLOYMENT-GUIDE.md) - Deploy it

### I'm a Power User
You want:
1. [CHANGELOG.md](../CHANGELOG.md) - See what's new
2. [docs/KILLA-WHALE-MODE-WARNING.md](../docs/KILLA-WHALE-MODE-WARNING.md) - Understand advanced modes
3. [ROADMAP.md](../ROADMAP.md) - See what's coming

### I'm a Contributor
Read these:
1. [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
2. [.github/VERSIONING.md](VERSIONING.md) - Version numbering
3. [.github/MAINTENANCE.md](MAINTENANCE.md) - Project maintenance

### I'm a Maintainer
Essential docs:
1. [.github/RELEASE_PROCESS.md](RELEASE_PROCESS.md) - Release checklist
2. [.github/VERSIONING.md](VERSIONING.md) - Version decisions
3. [.github/MAINTENANCE.md](MAINTENANCE.md) - Daily/weekly tasks
4. [.github/release-template.md](release-template.md) - Release notes template

### I'm a Security Researcher
Check:
1. [SECURITY.md](../SECURITY.md) - Security policy
2. [CHANGELOG.md](../CHANGELOG.md) - Security fixes history
3. [.github/MAINTENANCE.md](MAINTENANCE.md) - Security issue process

---

## 📝 Documentation Standards

### Writing Style
- **Clear and concise** - No jargon unless necessary
- **User-focused** - Write for your audience
- **Action-oriented** - Tell people what to do
- **Professional but friendly** - We're humans helping humans

### Formatting
- Use **bold** for emphasis
- Use `code blocks` for commands
- Use > blockquotes for important notes
- Use tables for comparisons
- Use checklists [ ] for tasks

### Structure
```markdown
# Document Title

Brief description of what this doc covers.

---

## Major Section

### Subsection

Content here.

**Key Point:**
- Bullet list
- More points

### Another Subsection

More content.

---

## Links

- External link
- Internal link

---

*Last updated: YYYY-MM-DD*
*Tide Gateway - freedom within the shell* 🌊
```

---

## 🔄 Keeping Docs Updated

### When to Update Documentation

| Trigger | Update These Docs |
|---------|-------------------|
| New release | CHANGELOG.md, VERSION, README badge |
| New feature | README.md, relevant guides, ROADMAP.md |
| Bug fix | CHANGELOG.md |
| Breaking change | CHANGELOG.md, VERSIONING.md, upgrade guides |
| Security fix | CHANGELOG.md, SECURITY.md |
| Process change | RELEASE_PROCESS.md, MAINTENANCE.md |
| New contributor | Thank in CHANGELOG.md and release notes |

### Documentation Review Checklist

**Quarterly review:**
- [ ] All links work
- [ ] Screenshots are current
- [ ] Version numbers accurate
- [ ] Commands tested and working
- [ ] Terminology consistent
- [ ] Spelling/grammar correct
- [ ] Examples up-to-date

**Tool for checking:**
```bash
# Check for broken links
npm install -g markdown-link-check
find . -name "*.md" -exec markdown-link-check {} \;

# Check for outdated version references
grep -r "v1.0" . --include="*.md"
grep -r "v1.1" . --include="*.md"
```

---

## 🎨 Documentation Improvements

### Always Welcome
- Fix typos
- Improve clarity
- Add examples
- Better organization
- Add diagrams/screenshots
- Fill gaps

### How to Contribute Documentation
1. Fork the repository
2. Make your improvements
3. Test that they render correctly
4. Submit a pull request
5. Describe what you improved

**Small fixes:** Can be made directly via GitHub's web editor  
**Large changes:** Clone locally and test with a markdown previewer

---

## 🏆 Documentation Quality Goals

### Current Status
- ✅ User documentation (README, guides)
- ✅ Version history (CHANGELOG, HISTORY)
- ✅ Contribution guidelines
- ✅ Release process
- ✅ Maintenance guides
- ⏳ Video tutorials (future)
- ⏳ Interactive demos (future)

### Future Improvements
- [ ] Add diagrams/architecture visuals
- [ ] Create video walkthroughs
- [ ] Build interactive documentation site
- [ ] Add troubleshooting flowcharts
- [ ] Create FAQ from common issues
- [ ] Add translations (if community wants)

---

## 📚 External Resources

### Learning More
- **Tor Project**: https://www.torproject.org/
- **Alpine Linux**: https://alpinelinux.org/
- **Keep a Changelog**: https://keepachangelog.com/
- **Semantic Versioning**: https://semver.org/

### Writing Documentation
- **Write the Docs**: https://www.writethedocs.org/
- **Markdown Guide**: https://www.markdownguide.org/
- **GitHub Docs Writing**: https://github.com/github/docs/blob/main/contributing/content-style-guide.md

---

## 🎯 Quick Links

| I want to... | Go to... |
|--------------|----------|
| Get started with Tide | [START-HERE.md](../START-HERE.md) |
| See what's new | [CHANGELOG.md](../CHANGELOG.md) |
| Report a bug | [GitHub Issues](https://github.com/bodegga/tide/issues) |
| Contribute code | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| Report security issue | [SECURITY.md](../SECURITY.md) |
| Create a release | [RELEASE_PROCESS.md](RELEASE_PROCESS.md) |
| Understand versions | [VERSIONING.md](VERSIONING.md) |
| Maintain the project | [MAINTENANCE.md](MAINTENANCE.md) |

---

## 📞 Questions?

If you can't find what you're looking for:
1. Search this documentation index
2. Check GitHub Issues
3. Open a Discussion
4. Create a new Issue (tagged "documentation")

---

**This documentation is a living resource. If something is missing, unclear, or wrong - please let us know!**

---

*Last updated: 2025-12-09*  
*Tide Gateway - freedom within the shell* 🌊
