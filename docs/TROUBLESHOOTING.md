# Troubleshooting Guide

This guide helps resolve common issues when using the CA Certificate Import Action.

## Common Issues

### 1. Certificate Not Found Error

**Error Message:**
```
[ERROR] Certificate file not found: certs/ca.crt
```

**Causes:**
- File path is incorrect
- File doesn't exist in the repository
- File is not checked into git

**Solutions:**
- Verify the file exists: `ls -la certs/ca.crt`
- Check file is committed to repository
- Use absolute path from repository root
- Ensure checkout action runs before this action

**Example Fix:**
```yaml
- name: Checkout code
  uses: actions/checkout@v4  # Must run before using file paths

- name: Install certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: 'certs/ca.crt'  # Relative to repo root
```

---

### 2. URL Download Failed

**Error Message:**
```
[ERROR] Failed to download certificate from URL
```

**Causes:**
- URL is incorrect or unreachable
- Network connectivity issues
- SSL/TLS verification failure (self-signed cert on source)
- Authentication required

**Solutions:**
- Test URL manually: `curl -v https://your-url/cert.crt`
- Ensure URL is publicly accessible or uses proper authentication
- Check for typos in URL
- Verify the source server is available

**Example Fix:**
```yaml
# If the source uses self-signed certs, you might need:
- name: Download certificate manually
  run: |
    curl -k -o /tmp/ca.crt https://internal.server/ca.crt

- name: Install certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: '/tmp/ca.crt'
```

---

### 3. Invalid Certificate Format

**Error Message:**
```
[ERROR] Invalid certificate format - does not appear to be a valid PEM certificate
```

**Causes:**
- Certificate is not in PEM format
- Certificate is in DER/binary format
- File is corrupted
- Wrong file provided

**Solutions:**
- Verify certificate format: `openssl x509 -in cert.crt -text -noout`
- Convert DER to PEM: `openssl x509 -inform der -in cert.der -out cert.pem`
- Check file contents start with `-----BEGIN CERTIFICATE-----`

**Example Fix:**
```bash
# Convert DER to PEM format
openssl x509 -inform der -in certificate.der -out certificate.pem

# Verify PEM format
cat certificate.pem | head -1
# Should show: -----BEGIN CERTIFICATE-----
```

---

### 4. Permission Denied

**Error Message:**
```
[ERROR] Permission denied when copying certificate
```

**Causes:**
- Insufficient permissions to write to system directories
- Runner security restrictions

**Solutions:**
- This action uses `sudo` automatically
- Ensure runner has sudo capabilities (should be default on ubuntu-22.04)
- Check runner configuration

**Example:**
```yaml
# Standard ubuntu runners should work fine
jobs:
  build:
    runs-on: ubuntu-22.04  # Recommended
```

---

### 5. Certificate Not Trusted After Installation

**Error Message:**
```
SSL certificate problem: unable to get local issuer certificate
```

**Causes:**
- Certificate installed but not in chain of trust
- Intermediate certificates missing
- Certificate expired
- Wrong certificate installed

**Solutions:**
- Install the complete certificate chain
- Verify certificate validity: `openssl x509 -in cert.crt -noout -dates`
- Check certificate is for correct domain
- Install intermediate certificates separately

**Example Fix:**
```yaml
# Install complete chain
- name: Install root CA
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate: 'certs/root-ca.crt'
    certificate-name: 'root-ca.crt'

- name: Install intermediate CA
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate: 'certs/intermediate-ca.crt'
    certificate-name: 'intermediate-ca.crt'
```

---

### 6. Docker Still Can't Pull Images

**Error Message:**
```
Error response from daemon: Get https://registry.example.com/v2/: x509: certificate signed by unknown authority
```

**Causes:**
- Certificate not properly installed in system store
- Certificate installed after BuildKit started
- Wrong certificate installed

**Solutions:**
- Install certificate BEFORE setting up BuildKit
- Verify certificate is for correct domain/CA
- Check certificate is in `/usr/local/share/ca-certificates/`
- Ensure `update-ca-certificates` ran successfully

**Example Fix:**
```yaml
# Correct order - certificate FIRST
- name: Install certificate FIRST
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate: 'certs/ca.crt'
    verbose: true

- name: Set up Docker Buildx AFTER certificate
  uses: docker/setup-buildx-action@v3

- name: Login to registry
  uses: docker/login-action@v3
  with:
    registry: registry.example.com
    username: ${{ secrets.REGISTRY_USER }}
    password: ${{ secrets.REGISTRY_PASS }}
```

---

### 7. Inline Certificate from Secret Not Working

**Error Message:**
```
[ERROR] Could not determine certificate source type
```

**Causes:**
- Secret not properly referenced
- Secret value is empty
- Certificate content doesn't contain PEM markers (`-----BEGIN CERTIFICATE-----`)
- Multiline secret formatting issue

**Solutions:**
- Verify secret exists and has content
- Ensure certificate content includes PEM markers: `-----BEGIN CERTIFICATE-----`
- Test secret value (without exposing): `echo "${{ secrets.YOUR_SECRET }}" | grep -q "BEGIN CERTIFICATE" && echo "Valid" || echo "Invalid"`
- Check secret formatting in GitHub settings

**Example Fix:**
```yaml
# Correct inline usage (auto-detected)
- name: Install from secret
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: ${{ secrets.CA_CERTIFICATE }}  # Auto-detected as inline content
    certificate-name: 'custom-ca.crt'

# Verify secret (verbose)
- name: Check secret (verbose only - remove in production)
  run: |
    if [ -z "${{ secrets.CA_CERTIFICATE }}" ]; then
      echo "Secret is empty!"
    else
      if echo "${{ secrets.CA_CERTIFICATE }}" | grep -q "BEGIN CERTIFICATE"; then
        echo "Secret contains valid PEM certificate"
      else
        echo "Warning: Secret doesn't appear to contain PEM certificate markers"
      fi
    fi
```

---

## Debugging Tips

### Enable Debug Mode

```yaml
- name: Install certificate with verbose output
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate: 'certs/ca.crt'
    verbose: true  # Enables verbose output
```

### Manual Verification

After running the action, verify installation:

```yaml
- name: Verify certificate installation
  run: |
    echo "=== System CA Certificates ==="
    ls -la /usr/local/share/ca-certificates/
    
    echo "=== Verify Certificate ==="
    if [ -f /usr/local/share/ca-certificates/custom-ca-*.crt ]; then
      openssl x509 -in /usr/local/share/ca-certificates/custom-ca-*.crt -noout -subject -issuer -dates
    fi
    
    echo "=== Test Registry Connection ==="
    curl -v https://registry.example.com/v2/
```

### Check Certificate Chain

```yaml
- name: Test certificate chain
  run: |
    echo | openssl s_client -showcerts -servername registry.example.com -connect registry.example.com:443 2>/dev/null | openssl x509 -inform pem -noout -text
```

### Common Debug Commands

```bash
# List installed CA certificates
ls -la /usr/local/share/ca-certificates/

# View certificate details
openssl x509 -in /path/to/cert.crt -text -noout

# Verify certificate
openssl verify -CApath /etc/ssl/certs /path/to/cert.crt

# Test HTTPS connection
curl -v https://your-registry.com/v2/

# View system CA bundle
ls -la /etc/ssl/certs/ca-certificates.crt
```

## Getting Help

If you're still experiencing issues:

1. **Enable verbose mode** in the action
2. **Check action outputs** for certificate path and name
3. **Verify certificate format** using openssl
4. **Test manually** with curl
5. **Open an issue** with:
   - Error messages (redact sensitive info)
   - Workflow file (redact secrets)
   - Debug output
   - Expected vs actual behavior

## Frequently Asked Questions

### Q: Can I use this action on non-Ubuntu runners?
**A:** Currently tested on ubuntu-22.04. Other Ubuntu versions should work. Windows/macOS runners are not currently supported.

### Q: Can I install multiple certificates?
**A:** Yes! Run the action multiple times with different certificates.

### Q: Does this work with self-signed certificates?
**A:** Yes, that's a primary use case.

### Q: Will this persist between job steps?
**A:** Yes, within the same job. Certificates are installed at the OS level and persist for the job duration.

### Q: Can I use this with GitHub-hosted runners?
**A:** Yes, this action is designed for GitHub-hosted runners.

### Q: Does this affect builds in other jobs?
**A:** No, each job runs in a fresh environment.

