# Usage Examples

This document provides comprehensive examples of using the CA Certificate Import Action in various scenarios.

## Basic Examples

### 1. Install Certificate from Local File

```yaml
- name: Install company CA certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'certs/company-ca.crt'
```

### 2. Install Certificate from URL

```yaml
- name: Install certificate from PKI server
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'https://pki.company.com/certs/root-ca.crt'
    certificate-name: 'company-root-ca.crt'
```

### 3. Install Certificate from GitHub Secret

```yaml
- name: Install certificate from secret
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: ${{ secrets.CUSTOM_CA_CERT }}
    certificate-name: 'custom-ca.crt'
```

## Advanced Examples

### 4. Multiple Certificates (Certificate Chain)

```yaml
- name: Install root CA
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'certs/root-ca.crt'
    certificate-name: 'root-ca.crt'

- name: Install intermediate CA
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'certs/intermediate-ca.crt'
    certificate-name: 'intermediate-ca.crt'
```

### 5. With Debug Output

```yaml
- name: Install certificate with verboseging
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'certs/verbose-ca.crt'
    verbose: true
```

### 6. Generate BuildKit Configuration

BuildKit runs in its own container and does not use the runner's trust store. Name every registry host it must trust the CA for in `buildkit-registries`, and pass `buildkit-path` to `docker/setup-buildx-action`:

```yaml
- name: Install certificate and generate buildkit.toml
  id: install-cert
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'certs/company-ca.crt'
    certificate-name: 'company-ca.crt'
    generate-buildkit: 'true'
    buildkit-registries: |
      registry.company.com
      registry.company.com:5000
    verbose: true

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    buildkitd-config: ${{ steps.install-cert.outputs.buildkit-path }}
```

Each host gets its own `[registry."<host>"]` table; BuildKit has no wildcard host, and the host must match the image reference exactly, port included. Without `buildkit-registries` the generated file is ignored by BuildKit (the action warns), and a push fails with `x509: certificate signed by unknown authority`.

### 7. Generate BuildKit Configuration with Custom Runtime

```yaml
- name: Install certificate and generate buildkit.toml with custom runtime
  id: install-cert
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: 'certs/company-ca.crt'
    certificate-name: 'company-ca.crt'
    generate-buildkit: 'true'
    buildkit-registries: 'registry.company.com'
    buildkit-runtime: 'io.containerd.runc.v2'
    verbose: true

- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    buildkitd-config: ${{ steps.install-cert.outputs.buildkit-path }}
```

`buildkit-runtime` writes `[worker.containerd.runtime] name = "..."`, which only BuildKit's containerd worker reads. The `docker-container` builder that `setup-buildx-action` creates uses the OCI worker, so there the setting is accepted but has no effect.

## Complete Workflow Examples

### 7. Build and Push to Private Registry

```yaml
name: Build Docker Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      
      - name: Install custom CA certificate
        id: install-cert
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: ${{ secrets.COMPANY_CA_CERT }}
          certificate-name: 'company-ca.crt'
          generate-buildkit: 'true'
          buildkit-registries: 'registry.company.com'
      
      # BuildKit does not use the runner's trust store; without buildkitd-config
      # the push fails with "x509: certificate signed by unknown authority".
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          buildkitd-config: ${{ steps.install-cert.outputs.buildkit-path }}
      
      - name: Login to registry
        uses: docker/login-action@v3
        with:
          registry: registry.company.com
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: registry.company.com/myapp:latest
```

### 8. Multi-Platform Build with Custom Certificate

```yaml
name: Multi-Platform Build

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Install certificate from URL
        id: install-cert
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: 'https://pki.internal.net/ca/root.crt'
          generate-buildkit: 'true'
          buildkit-registries: 'harbor.internal.net'
          verbose: true
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          buildkitd-config: ${{ steps.install-cert.outputs.buildkit-path }}
      
      - name: Login to Harbor
        uses: docker/login-action@v3
        with:
          registry: harbor.internal.net
          username: ${{ secrets.HARBOR_USERNAME }}
          password: ${{ secrets.HARBOR_PASSWORD }}
      
      - name: Build and push multi-platform
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            harbor.internal.net/myapp:${{ github.ref_name }}
            harbor.internal.net/myapp:latest
```

### 9. Python Package Build with Internal PyPI

```yaml
name: Build Python Package

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Install custom CA for internal PyPI
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: ${{ secrets.PYPI_CA_CERT }}
          certificate-name: 'internal-pypi-ca.crt'
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies from internal PyPI
        run: |
          pip install --index-url https://pypi.internal.company.com/simple/ -r requirements.txt
      
      - name: Build package
        run: |
          python -m build
```

### 10. Node.js Build with Internal npm Registry

```yaml
name: Build Node.js App

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Install custom CA for internal npm
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: 'https://pki.company.com/npm-ca.crt'
      
      - name: Set up Node.js
        uses: actions/setup-node@v6
        with:
          node-version: '24'
          registry-url: 'https://npm.internal.company.com'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build
        run: npm run build
```

### 11. Docker Build with Internal Resources

Installing the CA on the runner does **not** reach `RUN` steps: they execute inside the build's base image, with that image's trust store. Pass the CA into the build, for example as a build secret:

```yaml
name: Docker Build with Internal Resources

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Install custom CA certificate
        id: install-cert
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: 'certs/internal-ca.crt'
      
      - name: Build image (Dockerfile reaches internal resources with the CA)
        uses: docker/build-push-action@v6
        with:
          context: .
          push: false
          tags: myapp:test
          secret-files: |
            company-ca=${{ steps.install-cert.outputs.certificate-path }}
```

```dockerfile
# The secret is mounted only for this RUN step and is not stored in the image.
RUN --mount=type=secret,id=company-ca,target=/tmp/company-ca.crt \
    curl --cacert /tmp/company-ca.crt -fsSL https://files.corp.internal/tool.tar.gz -o /tmp/tool.tar.gz
```

If the base image is pulled from a registry signed by the same CA, also generate the BuildKit config as in [example 6](#6-generate-buildkit-configuration).

## Troubleshooting Examples

### 12. Verify Certificate Installation

```yaml
- name: Install certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  id: install-cert
  with:
    certificate: 'certs/ca.crt'

- name: Verify certificate was installed
  run: |
    echo "Certificate installed at: ${{ steps.install-cert.outputs.certificate-path }}"
    echo "Certificate name: ${{ steps.install-cert.outputs.certificate-name }}"
    
    # Check if certificate exists
    ls -la ${{ steps.install-cert.outputs.certificate-path }}
    
    # Check certificate details
    openssl x509 -in ${{ steps.install-cert.outputs.certificate-path }} -noout -subject -issuer -dates
    
    # Verify certificate is in CA bundle
    openssl verify -CApath /etc/ssl/certs ${{ steps.install-cert.outputs.certificate-path }}
```

### 13. Test Registry Connection After Installation

```yaml
- name: Install certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: ${{ secrets.REGISTRY_CA }}
    certificate-name: 'registry-ca.crt'
    verbose: true

- name: Test registry connectivity
  run: |
    echo "Testing connection to registry.company.com..."
    curl -v https://registry.company.com/v2/
    
    echo "Testing Docker registry API..."
    docker login registry.company.com -u ${{ secrets.REGISTRY_USER }} -p ${{ secrets.REGISTRY_PASS }}
    docker pull registry.company.com/test/hello-world || echo "Pull failed (image may not exist)"
```

## Integration with Existing Workflows

### 14. Replace Existing Certificate Installation

**Before:**
```yaml
- name: Copy custom certificate
  if: ${{ env.CUSTOM_CERTIFICATE }}
  run: |
    if [ -f /certs/${{ env.CUSTOM_CERTIFICATE }} ]; then
      mkdir -p /usr/local/share/ca-certificates
      cp /certs/${{ env.CUSTOM_CERTIFICATE }} /usr/local/share/ca-certificates/
      update-ca-certificates
    fi
```

**After:**
```yaml
- name: Install custom certificate
  if: ${{ env.CUSTOM_CERTIFICATE }}
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: '/certs/${{ env.CUSTOM_CERTIFICATE }}'
```

### 15. Conditional Certificate Installation

```yaml
- name: Install certificate (production only)
  if: github.ref == 'refs/heads/main'
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
  with:
    certificate: ${{ secrets.PROD_CA_CERT }}
    certificate-name: 'prod-ca.crt'
```

### 16. Dynamic Certificate from Environment

```yaml
env:
  CERT_URL: 'https://pki.company.com/certs/current-ca.crt'
  
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Install certificate from environment URL
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: ${{ env.CERT_URL }}
```

## Real-World Use Cases

### 17. Corporate Infrastructure Build

```yaml
name: Corporate Build Pipeline

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      # Install corporate CA certificate; tools on the runner trust it from here on
      - name: Install corporate CA
        id: install-cert
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: ${{ secrets.CORPORATE_CA_CERT }}
          certificate-name: 'corporate-ca.crt'
          generate-buildkit: 'true'
          buildkit-registries: 'harbor.corp.internal'
      
      # BuildKit has its own trust store: it gets the CA through buildkitd-config
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
        with:
          buildkitd-config: ${{ steps.install-cert.outputs.buildkit-path }}
      
      - name: Login to internal registry
        uses: docker/login-action@v3
        with:
          registry: harbor.corp.internal
          username: ${{ secrets.HARBOR_USER }}
          password: ${{ secrets.HARBOR_PASS }}
      
      - name: Build with access to all internal resources
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            harbor.corp.internal/myteam/myapp:${{ github.sha }}
            harbor.corp.internal/myteam/myapp:latest
          # BuildKit trusts harbor.corp.internal (pull and push) via buildkitd-config.
          # RUN steps that call pypi/npm/maven.corp.internal use the base image's
          # trust store instead; pass the CA in as shown in example 11.
```

### 18. Advanced BuildKit Configuration with Custom CA

```yaml
name: BuildKit with Custom CA Configuration

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6
      
      - name: Install certificate and generate buildkit.toml
        id: cert-install
        uses: LiquidLogicLabs/git-action-ca-certificate-import@v3
        with:
          certificate: ${{ secrets.COMPANY_CA_CERT }}
          certificate-name: 'company-ca.crt'
          generate-buildkit: 'true'
          # Every registry the build pulls from or pushes to through this CA
          buildkit-registries: |
            registry.company.com
            mirror.company.com:5000
          verbose: true
      
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3
      
      # buildx create --config copies the CA named in buildkit.toml into the
      # builder container and rewrites the path; nothing to copy by hand.
      - name: Set up Docker Buildx with the generated config
        id: buildx
        uses: docker/setup-buildx-action@v3
        with:
          buildkitd-config: ${{ steps.cert-install.outputs.buildkit-path }}
      
      - name: Build with custom BuildKit configuration
        uses: docker/build-push-action@v6
        with:
          context: .
          builder: ${{ steps.buildx.outputs.name }}
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            registry.company.com/myapp:${{ github.sha }}
            registry.company.com/myapp:latest
          # BuildKit trusts the CA for the registries listed above. RUN steps
          # do not; see example 11 for passing the CA into the build.
```
