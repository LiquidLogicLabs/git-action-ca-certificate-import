# Maintainer Documentation

This document contains information for developers and maintainers of the CA Certificate Import Action.

## Table of Contents

- [Publishing Guide](#publishing-guide)
- [Local Testing](#local-testing)
- [Release Automation](#release-automation)
- [Development Workflow](#development-workflow)

## Publishing Guide

### Quick Publish Guide

#### Step 1: Create GitHub Repository

1. Go to: https://github.com/new
2. Repository name: `git-action-ca-certificate-import`
3. Description: `GitHub Action for importing custom CA certificates into CI/CD environments`
4. Public repository
5. **Don't** initialize with README (we have one)
6. Click "Create repository"

#### Step 2: Connect & Push

```bash
# Navigate to action directory
cd ./git-action-ca-certificate-import

# Initialize git (if not done)
git init

# Add all files
git add .

# Initial commit
git commit -m "feat: Initial release - CA Certificate Import Action

- Install custom certificates from file, URL, or inline content
- Automatic system CA trust store integration
- Works with Docker registry authentication
- Comprehensive error handling and validation"

# Add GitHub remote
git remote add origin https://github.com/LiquidLogicLabs/git-action-ca-certificate-import.git

# Push to GitHub
git branch -M main
git push -u origin main
```

#### Step 3: Create First Release

```bash
# Use the automated release script
npm run release:major

# This will:
# - Create tag v1.0.0
# - Update CHANGELOG
# - Push tag to GitHub
# - Trigger GitHub Actions to create release
# - Set up v1 major version tag
```

#### Step 4: Verify

1. **Check repository:** https://github.com/LiquidLogicLabs/git-action-ca-certificate-import
2. **Check release:** https://github.com/LiquidLogicLabs/git-action-ca-certificate-import/releases
3. **Check tags:** Should see both `v1.0.0` and `v1`

#### Step 5: Test in Another Workflow

Create a test workflow in any repository:

```yaml
name: Test Action

on: [push]

jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
      - name: Test certificate action
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
        with:
          certificate-source: 'https://curl.se/ca/cacert.pem'
          certificate-name: 'test.crt'
          debug: true
```

## Local Testing

### Installing Act

#### macOS
```bash
brew install act
```

#### Linux
```bash
# Download latest release
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

#### Windows (WSL)
```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Basic Testing

#### 1. Test the Existing Test Workflow

```bash
# Run the test workflow
act -W .github/workflows/test.yml

# Run specific job
act -W .github/workflows/test.yml -j test

# List all jobs without running
act -W .github/workflows/test.yml -l
```

#### 2. Create a Simple Test Workflow

Create `.github/workflows/act-test.yml`:

```yaml
name: Act Local Test

on: [push]

jobs:
  test-local:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      
      - name: Create test certificate
        run: |
          mkdir -p test-certs
          openssl req -x509 -newkey rsa:2048 -keyout test-certs/test-key.pem \
            -out test-certs/test-ca.crt -days 365 -nodes \
            -subj "/C=US/ST=Test/L=Test/O=Test/CN=test.local"
      
      - name: Test certificate installation
        uses: ./  # This references the local action
        with:
          certificate-source: 'test-certs/test-ca.crt'
          debug: true
      
      - name: Verify installation
        run: |
          echo "=== Checking installed certificate ==="
          ls -la /usr/local/share/ca-certificates/
          
          if [ -f /usr/local/share/ca-certificates/custom-ca-*.crt ]; then
            echo "✓ Certificate installed successfully"
            openssl x509 -in /usr/local/share/ca-certificates/custom-ca-*.crt -noout -subject
          else
            echo "✗ Certificate not found"
            exit 1
          fi
```

#### 3. Run the Test

```bash
# Run the test workflow
act -W .github/workflows/act-test.yml

# With verbose output
act -W .github/workflows/act-test.yml -v
```

### Testing Different Scenarios

#### Test with Local File

```bash
# Create test certificate first
mkdir -p test-certs
openssl req -x509 -newkey rsa:2048 -keyout test-certs/test-key.pem \
  -out test-certs/test-ca.crt -days 365 -nodes \
  -subj "/C=US/ST=Test/L=Test/O=Test/CN=test.local"

# Run test
act -W .github/workflows/test.yml -j test --privileged
```

### Act Configuration

#### Create `.actrc` File

In your repository root, create `.actrc`:

```bash
# Use larger Docker image with more tools
-P ubuntu-latest=catthehacker/ubuntu:full-latest

# Bind mount for certificates (if needed)
--bind

# Verbose output
-v
```

#### Use Environment Variables

Create `.secrets` file for testing with secrets:

```env
CUSTOM_CA_CERT=-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAKL0UG+mRHGfMA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
...
-----END CERTIFICATE-----
```

Run with secrets:
```bash
act --secret-file .secrets
```

### Common Act Issues & Solutions

#### Issue: Permission Denied

**Error:**
```
Error: Permission denied when installing certificate
```

**Solution:**
Act runs in Docker with limited permissions. Use `--privileged`:

```bash
act -W .github/workflows/test.yml --privileged
```

#### Issue: Action Not Found

**Error:**
```
Error: Unable to resolve action ./
```

**Solution:**
Ensure you're in the repository root:

```bash
cd ./git-action-ca-certificate-import
act -W .github/workflows/test.yml
```

#### Issue: Docker Image Too Small

**Error:**
```
bash: update-ca-certificates: command not found
```

**Solution:**
Use a fuller Ubuntu image:

```bash
act -P ubuntu-latest=catthehacker/ubuntu:full-latest
```

### Quick Test Script

The repository includes `act-build.sh` for convenient local testing:

```bash
./act-build.sh
```

This script will:
- ✅ Check if act is installed
- ✅ Auto-create test certificates if needed
- ✅ Run the full test suite from `test.yml`
- ✅ Provide helpful next steps

## Release Automation

### Ultra-Simple Release Automation 🚀

The **simplest possible** release automation using `npm` and existing tools.

#### One-Line Releases

```bash
# Full Releases (creates tag, triggers CI/CD pipeline)
npm run release:patch      # v1.0.1 → v1.0.2 (bug fixes)
npm run release:minor      # v1.0.1 → v1.1.0 (new features)
npm run release:major      # v1.0.1 → v2.0.0 (breaking changes)

# Pre-Releases (creates pre-release tag, triggers CI/CD pipeline)
npm run release:pre-alpha  # v1.0.1 → v1.0.2-alpha.0
npm run release:pre-beta   # v1.0.1 → v1.0.2-beta.0
npm run release:pre-rc     # v1.0.1 → v1.0.2-rc.0
npm run release:pre-dev    # v1.0.1 → v1.0.2-dev.0

# Interactive mode (asks what type)
npm run release
```

**That's it!** Commands create git tags which automatically trigger the CI/CD pipeline for testing, building, packaging, and releasing.

#### What Happens Automatically

When you run any of the above commands:

1. ✅ **Version Detection**: Reads current version from git tags
2. ✅ **Version Bump**: Calculates next version (patch/minor/major)
3. ✅ **Changelog**: Generates changelog from conventional commits
4. ✅ **Package Update**: Updates package.json version
5. ✅ **Git Commit**: Commits changes with proper message
6. ✅ **Git Tag**: Creates version tag (e.g., v1.0.2)
7. ✅ **Push**: Pushes commits and tags to GitHub
8. ✅ **GitHub Release**: GitHub Actions creates the release automatically

#### Commit Message Format

Use conventional commits for automatic changelog generation:

```bash
# Bug fixes (creates patch release)
git commit -m "fix: resolve certificate validation issue"

# New features (creates minor release)
git commit -m "feat: add buildkit.toml generation support"

# Breaking changes (creates major release)  
git commit -m "feat!: change input parameter names"

# Documentation
git commit -m "docs: update installation guide"

# Chores (hidden in changelog)
git commit -m "chore: update dependencies"
```

## Development Workflow

### Making Updates

```bash
# 1. Make changes to code
# 2. Update CHANGELOG.md under [Unreleased]
# 3. Release new version
npm run release:patch   # or minor/major

# GitHub Actions automatically:
# - Creates release
# - Updates v1 tag
# - Users on @v1 get updates automatically
```

### Versioning Strategy

- **Patch** (1.0.0 → 1.0.1): Bug fixes, no breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, no breaking changes
- **Major** (1.0.0 → 2.0.0): Breaking changes

Users on `@v1` get patches and minor updates automatically.
Users on `@v1.0.0` never get updates (pinned).

### Testing Before Release

```bash
# Test locally with act
npm run test:local        # Run tests locally
npm run ci:local          # Run full CI/CD pipeline locally
```

### Repository Settings

After publishing, configure these settings:

#### General Settings
- ✅ Description: "GitHub Action for importing custom CA certificates into CI/CD environments"
- ✅ Topics: `github-actions`, `docker`, `certificates`, `ssl`, `tls`, `devops`
- ✅ Website: Link to docs if you have them

#### Actions Permissions
1. Go to: Settings → Actions → General
2. Workflow permissions: "Read and write permissions"
3. Allow GitHub Actions to create and approve pull requests: ✅

#### Branch Protection (Optional but Recommended)
1. Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
   - ✅ Include administrators

### GitHub Marketplace (Optional)

To publish to GitHub Marketplace:

#### Step 1: Add Marketplace Metadata to action.yml

```yaml
# Add these fields to action.yml
branding:
  icon: 'shield'      # Already have this ✅
  color: 'blue'       # Already have this ✅

# Author field (add if not present)
author: 'LiquidLogicLabs'
```

#### Step 2: Publish to Marketplace

1. Go to your repository
2. Click on "Releases"
3. Click "Draft a new release"
4. Check ✅ "Publish this Action to the GitHub Marketplace"
5. Fill in category: "Deployment"
6. Add tags: docker, ssl, certificates
7. Publish

## Complete Checklist

Before publishing:
- [ ] All tests pass (`.github/workflows/test.yml`)
- [ ] CHANGELOG.md is up to date
- [ ] README.md is complete
- [ ] No sensitive data in files
- [ ] LICENSE file present ✅
- [ ] .gitignore configured ✅

During publishing:
- [ ] GitHub repository created
- [ ] Git remote added
- [ ] Initial commit pushed
- [ ] First release created (v1.0.0)
- [ ] Major version tag exists (v1)

After publishing:
- [ ] Test action in another workflow
- [ ] Verify both @v1 and @v1.0.0 work
- [ ] Update dependent projects
- [ ] Consider publishing to Marketplace
- [ ] Share with team/community

## Ready to Publish?

Run these commands to publish right now:

```bash
# 1. Create repo on GitHub (do this first)
# Repository: git-action-ca-certificate-import

# 2. Run these commands
cd ./git-action-ca-certificate-import
git init
git add .
git commit -m "feat: Initial release - CA Certificate Import Action"
git remote add origin https://github.com/LiquidLogicLabs/git-action-ca-certificate-import.git
git branch -M main
git push -u origin main

# 3. Create first release
npm run release:major

# 4. Done! Check:
# https://github.com/LiquidLogicLabs/git-action-ca-certificate-import
```

## Support & Community

### Add GitHub Templates

```bash
# Create issue templates
mkdir -p .github/ISSUE_TEMPLATE

# Create pull request template
echo "..." > .github/PULL_REQUEST_TEMPLATE.md

# Add to next commit
```

### Enable Discussions

Settings → Features → ✅ Discussions

### Security Policy

Create `SECURITY.md` with vulnerability reporting info.

## Resources

- [Act Documentation](https://github.com/nektos/act)
- [Act Runner Images](https://github.com/catthehacker/docker_images)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
