# Development Guide

This document provides information for developers who want to contribute to this project.

## Prerequisites

- Node.js 16 or higher (for npm scripts and tooling)
- Git
- Bash shell
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
npm test
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
│   ├── CONTRIBUTING.md        # Contributing guidelines
│   ├── EXAMPLES.md            # Usage examples
│   └── TROUBLESHOOTING.md     # Troubleshooting guide
├── test-certs/                 # Test certificates for testing
├── package.json                # Dependencies and scripts
├── buildkit.toml              # BuildKit configuration template
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
   npm test              # Run tests via act
   ```

4. **Commit your changes**:
   - Use clear, descriptive commit messages
   - Consider using [Conventional Commits](https://www.conventionalcommits.org/) format

5. **Push and create a Pull Request**

### Code Standards

- **Shell Scripts**: Use bash with proper error handling (`set -euo pipefail`)
- **Validation**: Validate all inputs and provide clear error messages
- **Documentation**: Keep README and docs updated

### Available Scripts

```bash
# Testing
npm test                  # Run tests via act
npm run test:local        # Run tests locally with act
npm run ci:local          # Run CI workflow locally

# Releasing
npm run release:patch     # Create patch release (1.0.0 → 1.0.1)
npm run release:minor     # Create minor release (1.0.0 → 1.1.0)
npm run release:major     # Create major release (1.0.0 → 2.0.0)
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

Quick start:
```bash
npm test              # Run tests via act
npm run test:local    # Run tests locally
```

## Contributing

### Pull Request Process

1. **Fork the repository** (if external contributor)

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Write code following project standards
   - Test your changes thoroughly
   - Update documentation

4. **Ensure all checks pass**:
   ```bash
   npm test
   ```

5. **Commit your changes**:
   - Use clear commit messages
   - Consider Conventional Commits format

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

## Releasing

This project uses [`standard-version`](https://github.com/conventional-changelog/standard-version) for automated release tag creation with commit summaries.

### Pre-Release Checklist

Before creating a release, ensure:

1. **All local tests pass**:
   ```bash
   npm test
   ```

2. **CI workflow has passed**:
   - Push changes to `main`
   - Wait for CI workflow to complete successfully

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

The release command automatically:
1. Bumps the version in `package.json` (patch/minor/major)
2. Analyzes commits since the last tag to generate a commit summary
3. Creates a git commit with message like "chore: release v1.0.1"
4. Creates a git tag with a message that includes:
   - Version number
   - Summary of commits since last release
   - Formatted changelog-style content
5. Pushes the tag and commit to trigger the GitHub Actions release workflow

The release workflow then:
- Runs tests as a safety check
- Validates action.yml and shell scripts
- Generates release notes from PRs/commits
- Creates a GitHub release
- Creates/updates floating version tags

### Tag Messages

Release tag messages automatically include commit summaries formatted like:
```
v1.0.1

### Features
* Add new feature

### Bug Fixes
* Fix critical bug

### Chores
* Update dependencies
```

This works with conventional commits (recommended) or regular commit messages.

## Troubleshooting

### Test Issues

If tests fail:
1. Ensure you're in the project root directory
2. Verify `act` is installed: `act --version`
3. Check `~/.actrc` configuration file exists
4. Ensure Docker is running

### Permission Issues

If scripts fail with permission errors:
```bash
chmod +x install-certificate.sh
chmod +x scripts/*.sh
```

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Shell Scripting Best Practices](https://google.github.io/styleguide/shellguide.html)

## Getting Help

- Open an issue on GitHub for bug reports or feature requests
- Check existing issues for similar problems
- Review the [TESTING.md](./TESTING.md) for testing-related questions
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues

