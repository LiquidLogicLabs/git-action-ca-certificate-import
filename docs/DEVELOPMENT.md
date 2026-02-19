# Development Guide

This document provides information for developers and maintainers who want to contribute to this project.

## Prerequisites

- Node.js 16 or higher (for npm scripts and tooling)
- Git
- Bash shell
- [act](https://github.com/nektos/act) (optional, for local testing)
- (Optional) VS Code with Dev Container support for consistent development environment

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/LiquidLogicLabs/git-action-ca-certificate-import.git
cd git-action-ca-certificate-import
```

### Install Dependencies

```bash
npm install
```

### Development Environment

#### Local Setup

This is a composite action (shell-based), so development is straightforward:

```bash
# Install dependencies (for tooling)
npm install

# Verify setup
npm run test:act
```

## Project Structure

```
git-action-ca-certificate-import/
├── action.yml                  # Action metadata and steps
├── install-certificate.sh      # Main shell script
├── scripts/
│   └── install-dependencies.sh # Dependency installation script
├── docs/                       # Documentation
│   ├── DEVELOPMENT.md         # This file
│   ├── TESTING.md             # Testing documentation
│   ├── EXAMPLES.md            # Usage examples
│   └── TROUBLESHOOTING.md     # Troubleshooting guide
├── test-certs/                 # Test certificates for testing
├── package.json                # Dependencies and scripts
├── .github/
│   └── workflows/
│       ├── ci.yml             # CI workflow
│       ├── test.yml           # Test workflow
│       ├── release.yml        # Release workflow
│       └── .act/              # Act event files for local testing
└── README.md                  # User-facing documentation
```

## Development Workflow

### Making Changes

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Edit `install-certificate.sh` for core functionality
   - Update `action.yml` for action metadata/inputs
   - Update documentation as needed
   - Test your changes locally (see Testing section)

3. **Test locally**:
   ```bash
   npm run test:act              # Run tests via act
   ```

4. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Consider using [Conventional Commits](https://www.conventionalcommits.org/) format

5. **Push and create a Pull Request**

## Code Standards

### Code Style

- **Shell Scripts**: Use bash with proper error handling (`set -euo pipefail`)
- **Validation**: Validate all inputs and provide clear error messages
- **Documentation**: Keep README and docs updated
- Use clear, descriptive variable names
- Add comments for complex logic
- Follow shell scripting best practices
- Use consistent indentation (2 spaces for YAML, 4 spaces for bash)
- Include error handling for edge cases

### Available Scripts

```bash
# Testing
npm run test:act                # Run test workflow via act
npm run test:act:verbose        # Run tests with verbose output
npm run test:act:ci             # Run CI workflow locally
npm run test:act:release        # Test release workflow locally
npm run lint:act                # Run validation job locally

# Releasing
npm run release:patch           # Create patch release (1.0.0 → 1.0.1)
npm run release:minor           # Create minor release (1.0.0 → 1.1.0)
npm run release:major           # Create major release (1.0.0 → 2.0.0)
```

## Building

This is a composite action (shell-based), so there's no build step required. The action runs shell scripts directly.

**Note**: Ensure all shell scripts have executable permissions:
```bash
chmod +x install-certificate.sh
chmod +x scripts/*.sh
```

## Testing

See [TESTING.md](./TESTING.md) for comprehensive testing documentation.

### Quick Start

```bash
# Run test workflow locally
npm run test:act

# Run with verbose output
npm run test:act:verbose
```

### Testing Requirements

Before submitting a PR, ensure:

- All existing tests pass
- New functionality includes tests
- Manual testing in a workflow environment
- Test with all three input methods (file, URL, inline)
- Verify all outputs are correctly set

### Installing Act

#### macOS
```bash
brew install act
```

#### Linux / Windows (WSL)
```bash
# Download latest release
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Running Tests Locally

You can test the action locally using [act](https://github.com/nektos/act). The test workflow includes:

- Local file installation
- BuildKit generation (with and without runtime)
- URL-based certificate source (requires TEST_CERTIFICATE_URL variable)
- Inline certificate source
- Auto-generated certificate names
- Output verification for all outputs

#### Basic Act Usage

```bash
# Run the test workflow
npm run test:act

# Run with verbose output
npm run test:act:verbose

# Run specific job
act -W .github/workflows/test.yml -j test

# List all jobs without running
act -W .github/workflows/test.yml -l
```

#### Act Configuration

Create `.actrc` file in repository root for act configuration:

```bash
# Use larger Docker image with more tools
-P ubuntu-latest=catthehacker/ubuntu:full-latest

# Bind mount for certificates (if needed)
--bind

# Verbose output
-v
```

#### Testing with Environment Variables

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

#### Common Act Issues

**Permission Denied Error:**
```bash
# Use --privileged flag
act -W .github/workflows/test.yml --privileged
```

**Action Not Found:**
- Ensure you're in the repository root directory
- Check that action.yml exists and is valid

**Docker Image Too Small:**
```bash
# Use a fuller Ubuntu image
act -P ubuntu-latest=catthehacker/ubuntu:full-latest
```

See [TESTING.md](./TESTING.md) for detailed testing instructions.

## Contributing

Thank you for your interest in contributing! This section covers how to contribute to this project.

### How to Contribute

#### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected vs actual behavior**
- **Environment details** (OS, runner version, etc.)
- **Relevant logs** (with sensitive information redacted)

#### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** explaining why this enhancement would be useful
- **Proposed implementation** if you have ideas
- **Alternative solutions** you've considered

#### Pull Request Process

1. **Fork the repository** (if external contributor) and create your branch from `main`

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Write code following project standards (see Code Standards section)
   - Test your changes thoroughly
   - Update documentation as needed

4. **Ensure all checks pass**:
   ```bash
   npm run test:act
   ```

5. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Consider using [Conventional Commits](https://www.conventionalcommits.org/) format:
     - `feat:` for new features
     - `fix:` for bug fixes
     - `docs:` for documentation changes
     - `test:` for test changes
     - `chore:` for maintenance tasks

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**:
   - Provide a clear description of changes
   - Reference any related issues
   - Ensure CI checks pass

### Code Review

- All PRs require review before merging
- Address review feedback promptly
- Keep PRs focused and reasonably sized

### Documentation Updates

When contributing, keep documentation up to date:

- Keep README.md focused on usage (not development details)
- Update EXAMPLES.md for new features
- Update relevant documentation in `docs/` directory
- Include inline comments for complex logic

## Releasing

This project uses npm lifecycle hooks (`version`/`postversion`) with `conventional-changelog-cli` for versioning and changelog generation.

### Pre-Release Checklist

**CRITICAL**: Never create a release tag until ALL of the following are complete:

1. **Local Testing Phase** (MUST complete successfully):
   - Run `npm run test:act` - All tests must pass
   - Run `npm run lint:act` - Validation must pass
   - Fix any issues found in tests or validation
   - Repeat until all local checks pass

2. **CI Verification Phase** (MUST complete successfully):
   - Push changes to main branch: `git push`
   - Monitor CI workflow to completion
   - Wait for CI workflow to complete (status: `completed`, conclusion: `success`)
   - If CI fails, fix issues and repeat

3. **Release Tag Creation** (ONLY after steps 1 and 2 are complete):
   - Create semver tag: `npm run release:patch` (or `minor`/`major`)
   - Tag will be automatically pushed and trigger the release workflow

### Creating a Release

Once the pre-release checklist is complete:

```bash
# For patch release (1.0.0 → 1.0.1)
npm run release:patch

# For minor release (1.0.0 → 1.1.0)
npm run release:minor

# For major release (1.0.0 → 2.0.0)
npm run release:major
```

### What Happens

The release command triggers `npm version` which automatically:
1. Bumps the version in `package.json` (patch/minor/major)
2. Updates CHANGELOG.md from conventional commits via the `version` hook
3. Creates a git commit with message like "chore(release): 1.0.1"
4. Creates a git tag (e.g., `v1.0.1`)
5. Pushes the tag and commit to trigger the GitHub Actions release workflow via the `postversion` hook

The release workflow then:
- Runs tests as a safety check
- Validates action.yml and shell scripts
- Generates release notes from PRs/commits
- Creates a GitHub release
- Creates/updates floating version tags (`v1`, `v1.1`, `latest`)

### Commit Message Format

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

### Versioning Strategy

- **Patch** (1.0.0 → 1.0.1): Bug fixes, no breaking changes
- **Minor** (1.0.0 → 1.1.0): New features, no breaking changes
- **Major** (1.0.0 → 2.0.0): Breaking changes

Users on `@v1` get patches and minor updates automatically.
Users on `@v1.0.0` never get updates (pinned).

### Version Pinning

Users can pin to different version levels:

- `@v1` - Latest v1.x.x (major version) - gets updates automatically
- `@v1.1` - Latest v1.1.x (minor version) - gets patch updates
- `@latest` - Latest stable release
- `@v1.1.3` - Exact version - never gets updates

## Repository Settings

### General Settings

Configure these settings after publishing:

- **Description**: "GitHub Action for importing custom CA certificates into CI/CD environments"
- **Topics**: `github-actions`, `docker`, `certificates`, `ssl`, `tls`, `devops`
- **Website**: Link to docs if available

### Actions Permissions

1. Go to: Settings → Actions → General
2. Workflow permissions: "Read and write permissions"
3. Allow GitHub Actions to create and approve pull requests: ✅

### Branch Protection (Recommended)

1. Settings → Branches → Add rule
2. Branch name pattern: `main`
3. Enable:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
   - ✅ Include administrators

### GitHub Marketplace (Optional)

To publish to GitHub Marketplace:

1. Ensure `action.yml` includes branding:
   ```yaml
   branding:
     icon: 'shield'
     color: 'blue'
   author: 'LiquidLogicLabs'
   ```

2. Go to Releases → Draft a new release
3. Check ✅ "Publish this Action to the GitHub Marketplace"
4. Fill in category: "Deployment"
5. Add tags: docker, ssl, certificates
6. Publish

## Support & Community

### Issue Templates

Create issue templates for better organization:

```bash
mkdir -p .github/ISSUE_TEMPLATE
```

### Pull Request Template

Create `.github/PULL_REQUEST_TEMPLATE.md` to guide contributors.

### Enable Discussions

Settings → Features → ✅ Discussions

### Security Policy

Create `SECURITY.md` with vulnerability reporting information.

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discriminatory comments
- Personal attacks or trolling
- Publishing others' private information
- Other conduct inappropriate in a professional setting

## Troubleshooting

### Test Issues

If tests fail:
1. Ensure you're in the project root directory
2. Verify `act` is installed: `act --version`
3. Ensure Docker is running
4. Check that test certificates exist in `test-certs/` directory

### Permission Issues

If scripts fail with permission errors:
```bash
chmod +x install-certificate.sh
chmod +x scripts/*.sh
```

### Local Testing with Act

If act tests fail to find jobs:
- Ensure event files exist in `.github/workflows/.act/`
- Check that workflows use `workflow_call` or `workflow_dispatch` triggers for local testing
- Use `npm run test:act:verbose` for more detailed output
- Try using `--privileged` flag: `act -W .github/workflows/test.yml --privileged`

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Shell Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Act Documentation](https://github.com/nektos/act)
- [Act Runner Images](https://github.com/catthehacker/docker_images)

## Getting Help

- Open an issue on GitHub for bug reports or feature requests
- Check existing issues for similar problems
- Review the [TESTING.md](./TESTING.md) for testing-related questions
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
