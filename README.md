# CA Certificate Import GitHub Action

A GitHub Action that installs custom SSL/TLS certificates into the CI/CD runner environment, enabling Docker and other tools to work with private registries and internal resources that use custom certificate authorities.

## Features

- 📁 **Multiple Input Methods**: Local file, URL, or inline certificate content
- 🔒 **System Integration**: Installs to system CA store and runs `update-ca-certificates`
- 🐳 **BuildKit Support**: Optional generation of `buildkit.toml` configuration file
- ✅ **Simple**: Just install the cert - Docker will automatically trust it
- 🛡️ **Robust**: Comprehensive error handling and validation
- 🔄 **Idempotent**: Safe to run multiple times

## Usage

### Quick Start

```yaml
- name: Install custom certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate-source: 'certs/company-ca.crt'
```

### From URL

```yaml
- name: Install certificate from URL
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate-source: 'https://pki.company.com/ca.crt'
```

### From GitHub Secret

```yaml
- name: Install certificate from secret
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate-source: 'inline'
    certificate-body: ${{ secrets.CUSTOM_CA_CERT }}
    certificate-name: 'company-ca.crt'
```

### With BuildKit Configuration

```yaml
- name: Install certificate and generate buildkit.toml
  id: install-cert
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v1
  with:
    certificate-source: 'certs/company-ca.crt'
    generate-buildkit: 'true'

- name: Use buildkit.toml for Docker builds
  run: |
    echo "buildkit.toml generated at: ${{ steps.install-cert.outputs.buildkit-path }}"
    # Copy to Docker BuildKit config directory
    mkdir -p ~/.docker/buildx
    cp ${{ steps.install-cert.outputs.buildkit-path }} ~/.docker/buildx/config.toml
```

📚 **More examples:** See [docs/EXAMPLES.md](docs/EXAMPLES.md)

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `certificate-source` | Certificate source: file path, URL, or 'inline' | Yes | - |
| `certificate-body` | Certificate content (required when source is 'inline') | No | - |
| `certificate-name` | Name for certificate file | No | Auto-generated |
| `debug` | Enable debug output | No | `false` |
| `generate-buildkit` | Generate buildkit.toml configuration file | No | `false` |
| `buildkit-runtime` | Container runtime for BuildKit (e.g., 'io.containerd.runc.v2'). Leave empty to omit runtime configuration | No | - |

## Outputs

| Output | Description |
|--------|-------------|
| `certificate-path` | Path where certificate was installed |
| `certificate-name` | Name of the installed certificate file |
| `buildkit-path` | Path to the generated buildkit.toml file (only set if generate-buildkit is true) |

## How It Works

1. **Acquires Certificate**: Downloads/reads certificate from specified source
2. **Validates Format**: Ensures certificate is valid PEM format
3. **System Installation**: Copies to `/usr/local/share/ca-certificates/` and runs `update-ca-certificates`
4. **BuildKit Configuration** (optional): Generates `buildkit.toml` file with CA certificate settings
5. **Reports Success**: Outputs installation path, certificate name, and buildkit.toml path

Once installed, the certificate is trusted by:
- ✅ Docker (push/pull from registries with custom certs)
- ✅ curl, wget, and other HTTP clients
- ✅ pip, npm, apt, and other package managers
- ✅ Git operations over HTTPS
- ✅ Any tool that uses the system CA store

## Requirements

- Ubuntu runner (tested on ubuntu-22.04)
- Appropriate permissions to write to system directories

### Input Methods

The action supports three methods for providing certificates:

1. **Local File Path** - Reference a certificate file in the repository
   ```yaml
   certificate-source: 'certs/company-ca.crt'
   ```

2. **URL** - Download certificate from a web location
   ```yaml
   certificate-source: 'https://pki.company.com/ca.crt'
   ```

3. **Certificate Body** - Provide certificate content directly
   ```yaml
   certificate-source: 'inline'
   certificate-body: ${{ secrets.CUSTOM_CA_CERT }}
   ```

### Use Cases

- **Private Docker Registry**: Install corporate CA to pull/push images
- **Internal Resources**: Access internal URLs during build (pip, npm, etc.)
- **Development Environments**: Support self-signed certificates in test pipelines
- **Security Compliance**: Use organization-specific certificate authorities

## Versioning

This action follows [Semantic Versioning](https://semver.org/).

**Recommended usage:**
```yaml
uses: LiquidLogicLabs/git-action-ca-certificate-import@v1  # Gets latest v1.x.x
```

## 🚀 Quick Release

```bash
npm run release:patch      # Bug fixes
npm run release:minor      # New features  
npm run release:major      # Breaking changes
```

See [docs/MAINTAINERS.md](docs/MAINTAINERS.md) for full release automation guide.

## Documentation

- 📖 [Examples](docs/EXAMPLES.md) - Comprehensive usage examples
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- 🛠️ [Contributing](docs/CONTRIBUTING.md) - Development guidelines
- 👥 [Maintainers](docs/MAINTAINERS.md) - Publishing, testing, and release automation

## Troubleshooting

Having issues? Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for common problems and solutions.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT License](LICENSE) - see LICENSE file for details.

