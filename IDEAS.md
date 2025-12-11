# Tide Gateway - Ideas & Wishlist

> Quick capture for features, improvements, and platform ideas.
> Add ideas fast, convert to tasks later.

**Last Updated:** 2025-12-10

---

## 🎯 Active Ideas

### Features

- [ ] **#1** - Add bandwidth monitoring dashboard
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** Real-time bandwidth usage graphs in web dashboard. Show current usage, historical data, and per-connection stats.

- [ ] **#2** - Implement kill switch for internet connectivity
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Auto-disable internet if Tor connection drops. Prevents leak scenarios. Should be configurable (strict/relaxed modes).

- [ ] **#3** - DNS leak protection validation
  - **Priority:** Critical
  - **Added:** 2025-12-10
  - **Description:** Automated testing to verify no DNS leaks under all scenarios. Run tests on startup and periodically.

- [ ] **#4** - WebSocket API for real-time updates
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** Add WebSocket support for real-time gateway status updates in the web dashboard.

### Improvements

- [ ] **#5** - Auto-update Tor bridges from BridgeDB
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** Script to fetch fresh bridges automatically when old ones fail. Reduces manual configuration when in restricted networks.

- [ ] **#6** - One-command deployment script
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Single command to deploy Tide to any platform (VM, Docker, cloud). Should detect platform and adjust automatically.

### Platforms

- [ ] **#7** - Raspberry Pi support
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** ARM builds for Raspberry Pi. Lightweight gateway for home networks. Could be perfect for permanent deployments.

- [ ] **#8** - Android client app
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** Mobile client for Android devices. Simpler than ADB workarounds. Tap to connect/disconnect.

- [ ] **#9** - AWS AMI for cloud deployment
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** Pre-built AMI for easy AWS deployment. One-click launch for temporary or permanent cloud gateways.

### Documentation

- [ ] **#10** - Video tutorial series
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** YouTube series covering: setup, usage, troubleshooting, advanced configs. Reach non-technical users.

- [ ] **#11** - Troubleshooting flowchart
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Visual flowchart for common issues. "Connection failed? → Check this → Try that." Reduce support burden.

### Infrastructure

- [ ] **#12** - Automated CI/CD pipeline
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** GitHub Actions for testing and building releases. Auto-test on every commit, build artifacts on tags.

- [ ] **#13** - Multi-architecture Docker builds
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Support amd64, arm64, armv7. Single `docker pull` works on any platform. Use Docker buildx.

- [ ] **#14** - Metrics export to Prometheus
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Export gateway metrics to Prometheus for monitoring and alerting.

### Security

- [ ] **#15** - Security audit checklist
  - **Priority:** Critical
  - **Added:** 2025-12-10
  - **Description:** Comprehensive security review process. Include penetration testing, code audit, dependency scanning.

- [ ] **#16** - Encrypted configuration backups
  - **Priority:** Important
  - **Added:** 2025-12-10
  - **Description:** Automatic encrypted backups of Tor configs and bridge lists. Restore easily after rebuilds.

### UX

- [ ] **#17** - Status indicator LED support
  - **Priority:** Nice-to-have
  - **Added:** 2025-12-10
  - **Description:** Physical LED feedback on Raspberry Pi builds. Green=connected, Red=disconnected, Blinking=connecting.

---

## ✅ Completed Ideas

*(Ideas marked as done will be moved here)*

---

## 📊 Summary

- **Total Active Ideas:** 17
- **Critical:** 2
- **Important:** 6
- **Nice-to-have:** 9

**By Category:**
- Features: 4
- Improvements: 2
- Platforms: 3
- Documentation: 2
- Infrastructure: 3
- Security: 2
- UX: 1

---

## 🔗 Related

- Use `./scripts/utils/idea` CLI tool to manage this file
- Convert ideas to GitHub issues when ready to implement
- Review this file weekly to prioritize

---

*Ideas are cheap. Execution is everything. But capture them first.*
