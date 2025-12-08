# Contributing to ARM64 Tor Gateway Suite

Thank you for your interest in contributing to the first ARM64 anonymous computing stack!

## 🎯 Project Vision

Create a simple, auditable, production-ready Tor gateway solution for ARM64 that:
- Works out-of-the-box on Apple Silicon
- Matches Whonix security guarantees
- Remains minimal and understandable
- Serves as the reference implementation

## 🤝 How to Contribute

### Testing & Bug Reports

**Most valuable contribution right now:**

1. **Test on your hardware**
   - M1/M2/M3/M4 Macs
   - Different hypervisors (Parallels, UTM, VMware)
   - Different Debian versions
   - Report what works/doesn't work

2. **Report issues clearly**
   ```
   Hardware: M2 MacBook Pro
   Hypervisor: UTM 4.x
   Issue: Gateway can't reach internet
   Steps to reproduce: ...
   Expected: ...
   Actual: ...
   Logs: [paste relevant logs]
   ```

### Documentation

- Fix typos and grammar
- Add clarifications
- Translate to other languages
- Create video tutorials
- Write blog posts

### Code Contributions

**Current needs:**

1. **Alpine Linux variant** - Reduce gateway from 1.5GB to 150MB
2. **Automated installer** - One-command setup
3. **Firewall improvements** - More granular rules
4. **Monitoring tools** - Dashboard for Tor status

**Guidelines:**
- Keep it simple (favor clarity over cleverness)
- Comment everything
- Test on real hardware
- Update documentation
- Follow existing style

### Research & Security

- Security audits welcome
- ARM64 optimization ideas
- Threat model improvements
- Performance benchmarks

## 📝 Contribution Process

1. **Discuss first** - Open an issue before major work
2. **Fork & branch** - Make changes in a feature branch
3. **Test thoroughly** - On real Apple Silicon
4. **Document changes** - Update relevant docs
5. **Submit** - Clear description of what and why

## ✅ What We're Looking For

### High Priority

- [ ] Alpine Linux gateway (minimal disk usage)
- [ ] UTM installation guide
- [ ] Automated setup script
- [ ] Video walkthrough
- [ ] Security audit

### Medium Priority

- [ ] Tor Browser integration
- [ ] GUI management interface
- [ ] Stream isolation
- [ ] Performance benchmarks
- [ ] Alternative firewall configs

### Low Priority

- [ ] Onion service hosting
- [ ] VPN-over-Tor
- [ ] Mobile support
- [ ] Container-based gateway

## 🚫 What We're NOT Looking For

- Complex features that hurt auditability
- Dependency on proprietary software
- Breaking changes without strong justification
- Unmaintained code contributions

## 🎓 Coding Standards

### Shell Scripts

```bash
#!/bin/bash
# Brief description of script purpose

set -e  # Exit on error

# Use meaningful variable names
GATEWAY_IP="10.152.152.10"

# Comment complex logic
# This redirects DNS to Tor's DNSPort
iptables -t nat -A PREROUTING -i eth1 -p udp --dport 53 -j REDIRECT --to-ports 5353

# Error handling
if ! systemctl start tor; then
    echo "ERROR: Failed to start Tor"
    exit 1
fi
```

### Configuration Files

- Document every non-obvious setting
- Explain security implications
- Provide defaults that work
- Warn about dangerous options

### Documentation

- Clear, concise language
- Step-by-step instructions
- Expected output examples
- Troubleshooting section
- Links to references

## 🛡️ Security Policy

### Reporting Security Issues

**DO NOT open public issues for security vulnerabilities**

Instead:
1. Email privately to maintainer
2. Include detailed description
3. Proof of concept if applicable
4. Suggested fix if you have one

### Security-Sensitive Changes

Changes affecting:
- Firewall rules
- Tor configuration
- Network isolation
- Cryptography

Require:
- Thorough explanation
- Security impact analysis
- Testing methodology
- Community review

## 📜 License

All contributions are released into the **public domain**.

By contributing, you agree:
- No copyright claims on your contribution
- No restrictions on use
- No warranty provided

Why? Privacy tools should be freely available without legal barriers.

## 🎯 Roadmap Alignment

See [README.md](README.md) for current roadmap.

Contributions that align with roadmap goals are prioritized.

## 💬 Communication

### Be Respectful

- Assume good faith
- Be patient with new users
- Help others learn
- Celebrate diversity of thought

### Be Clear

- Specific rather than vague
- Examples over theory
- Show your work
- Admit when you don't know

### Be Constructive

- Suggest solutions, not just problems
- Explain the "why" behind your ideas
- Accept feedback gracefully
- Iterate based on discussion

## 🙏 Recognition

Contributors will be:
- Listed in commit history (forever)
- Mentioned in release notes
- Credited in documentation
- Appreciated by the community

We don't have badges or titles. Your work speaks for itself.

## ❓ Questions?

Not sure if your idea fits? **Ask!**

- Open a discussion issue
- Describe what you want to do
- Get feedback before investing time

Better to ask early than submit unsuitable work.

---

**Thank you for helping make anonymous computing available to ARM64 users!**

Together we're proving that ARM64 is ready for serious privacy work.
