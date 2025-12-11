# Contributing to Tide

Thanks for your interest in contributing to Tide! This project aims to make privacy-focused Tor networking accessible and secure.

## How to Contribute

### Reporting Issues
- Use GitHub Issues to report bugs or suggest features
- Include your OS, Docker version (if applicable), and Tide mode
- For bugs: steps to reproduce, expected vs actual behavior
- For security issues: see SECURITY.md

### Pull Requests
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (see Testing below)
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your fork (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Setup

**Docker development:**
```bash
git clone https://github.com/bodegga/tide.git
cd tide
cp .env.example .env
docker-compose up -d
```

**Test your changes:**
```bash
# Proxy mode test
curl --socks5 10.101.101.10:9050 https://check.torproject.org/api/ip

# Router mode test
docker run --rm --network tide_tidenet alpine sh -c "
  apk add curl && 
  udhcpc -i eth0 -n -q && 
  curl https://check.torproject.org/api/ip
"
```

### Code Style
- Shell scripts: Use `shellcheck` for linting
- Python: Follow PEP 8
- Keep it simple - readability over cleverness
- Comment complex logic

### Testing Checklist
Before submitting a PR, verify:
- [ ] Proxy mode works (SOCKS5 + DNS)
- [ ] Router mode works (DHCP + transparent routing)
- [ ] No clearnet leaks (test with `curl` outside Tor)
- [ ] Documentation updated if behavior changed
- [ ] No hardcoded credentials or secrets

## Areas We Need Help

### Priority Projects
1. **Client GUI** (`/client/tide-client.py`) - Cross-platform system tray app
2. **Takeover Mode** - ARP hijacking implementation (router mode)
3. **Testing** - More comprehensive test suite
4. **Documentation** - Tutorials, troubleshooting guides

### Good First Issues
- Improve error messages in scripts
- Add more example configurations
- Write how-to guides for specific use cases
- Test on different platforms and report results

## Project Structure

```
tide/
├── client/           # Client applications (GUI, CLI)
├── docker/           # Docker containers and compose files
├── scripts/
│   ├── install/      # VM/bare-metal install scripts
│   ├── runtime/      # Gateway runtime scripts
│   ├── build/        # VM image builders
│   └── test/         # Test scripts
├── docs/             # Documentation
├── config/           # Configuration templates
└── README.md         # Start here!
```

## Security Guidelines

**IMPORTANT:** Tide is a privacy/security tool. All contributions must:
- Never leak clearnet traffic
- Fail closed (block traffic if Tor fails)
- Handle credentials securely
- Not introduce backdoors or logging

If you find a security vulnerability, please see SECURITY.md for responsible disclosure.

## Questions?

- Check the [README.md](README.md) and [docs/](docs/) first
- Open a GitHub Discussion for general questions
- Open an Issue for bugs or feature requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make privacy accessible!** 🌊
