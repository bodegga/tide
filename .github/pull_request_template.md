# Pull Request Checklist

## File Organization

Before submitting, ensure files are in the correct directories:

- [ ] **Documentation** (`*.md` files) → `docs/` or `docs/guides/`
- [ ] **Deployment scripts** (`deploy-*.sh`, `*-deploy.sh`) → `deployment/<platform>/`
- [ ] **Testing scripts** (`test-*.sh`, `*-test.sh`) → `testing/`
- [ ] **Build scripts** (`build-*.sh`) → `scripts/build/`
- [ ] **Runtime scripts** (gateway logic) → `scripts/runtime/`
- [ ] **Configuration files** (`*.yaml`, `*.conf`, `torrc*`) → `config/`
- [ ] **Experimental/old scripts** → `archive/old-scripts/`

## Root Directory Rules

**ONLY these files belong in root:**
- `README.md` - Main project README
- `START-HERE.md` - Quick start guide
- `LICENSE` - MIT License
- `VERSION` - Version number
- `.gitignore` - Git ignore rules
- `tide-install.sh` - Symlink to `scripts/install/tide-install.sh`

**Everything else goes in a subdirectory!**

## Changes Made

<!-- Describe your changes here -->

## Testing

- [ ] Tested on target platform
- [ ] Documentation updated
- [ ] No files left in root (except allowed files above)
