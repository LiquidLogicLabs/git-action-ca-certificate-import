# Testing Guide

This document outlines testing approaches for this composite action.

## Test Structure

This is a composite action (shell-based), so testing is done via:
- **Workflow tests**: Using `act` to test the action in a GitHub Actions-like environment
- **Manual testing**: Testing shell scripts directly in a local environment

## Running Tests

### Via Act (Recommended)

Test the action using `act`:

```bash
npm test              # Run test workflow via act
npm run test:local    # Run tests locally with act
npm run ci:local      # Run CI workflow locally
```

### Manual Testing

For manual testing of shell scripts:

```bash
# Test install-certificate.sh directly
./install-certificate.sh
```

Set environment variables to simulate GitHub Actions inputs:
```bash
export INPUT_CERTIFICATE='path/to/cert.crt'
export INPUT_CERTIFICATE_NAME='test-cert.crt'
export INPUT_VERBOSE='true'
./install-certificate.sh
```

## Test Environment

### Local Development

Tests run locally using:
- `act` tool for workflow testing
- Docker for isolated test environments
- Bash shell for script execution

### CI/CD

Tests run in GitHub Actions via `.github/workflows/test.yml`:
- Uses `ubuntu-latest` runner
- Tests action in real GitHub Actions environment
- Validates all input/output combinations

## Test Coverage

### Test Scenarios

1. **Certificate from file path** (auto-detected)
   - Input: `certificate: 'path/to/cert.crt'`
   - Verifies: Certificate is installed to system CA store, auto-detected as file path

2. **Certificate from URL** (auto-detected)
   - Input: `certificate: 'https://example.com/ca.crt'`
   - Verifies: Certificate is downloaded and installed, auto-detected as URL

3. **Certificate from inline content** (auto-detected)
   - Input: `certificate: '-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----'`
   - Verifies: Certificate content is saved and installed, auto-detected as inline content via PEM markers

4. **BuildKit configuration generation**
   - Input: `generate-buildkit: 'true'`
   - Verifies: `buildkit.toml` is generated with correct settings

5. **Error handling**
   - Invalid certificate source
   - Missing required inputs
   - Invalid certificate format

## Manual Testing

For comprehensive manual testing:

1. **Prepare test certificates**:
   ```bash
   # Use test-certs/ directory for test certificates
   ```

2. **Test each input scenario**:
   ```bash
   # File path
   export INPUT_CERTIFICATE='test-certs/test.crt'
   ./install-certificate.sh

   # URL
   export INPUT_CERTIFICATE='https://example.com/ca.crt'
   ./install-certificate.sh

   # Inline
   export INPUT_CERTIFICATE='-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----'
   ./install-certificate.sh
   ```

3. **Verify installation**:
   ```bash
   # Check certificate is installed
   ls /usr/local/share/ca-certificates/
   update-ca-certificates
   ```

## Troubleshooting Tests

### Act Test Failures

If `act` tests fail:
- Verify `act` is installed: `act --version`
- Check `~/.actrc` configuration file exists
- Ensure Docker is running
- Check workflow files exist in `.github/workflows/`

### Permission Issues

If scripts fail with permission errors:
```bash
chmod +x install-certificate.sh
chmod +x scripts/*.sh
```

### Certificate Installation Issues

If certificates don't install:
- Check certificate format is valid PEM
- Verify system CA store location (`/usr/local/share/ca-certificates/`)
- Check `update-ca-certificates` command is available

## Writing New Tests

### Adding Workflow Tests

1. Add test scenarios to `.github/workflows/test.yml`
2. Test different input combinations
3. Verify outputs are correct
4. Test error cases

### Test Best Practices

- ✅ Test all input scenarios
- ✅ Test error cases
- ✅ Verify outputs are set correctly
- ✅ Test idempotency (running multiple times)
- ✅ Validate certificate installation

## Resources

- [Act Documentation](https://github.com/nektos/act)
- [Composite Actions Testing](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)

