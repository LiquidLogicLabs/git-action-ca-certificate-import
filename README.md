# CA Certificate Import GitHub Action

[![CI](https://github.com/LiquidLogicLabs/git-action-ca-certificate-import/actions/workflows/ci.yml/badge.svg)](https://github.com/LiquidLogicLabs/git-action-ca-certificate-import/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A GitHub Action that installs custom SSL/TLS certificates into the CI/CD runner environment, enabling Docker and other tools to work with private registries and internal resources that use custom certificate authorities.

## Features

- 📁 **Multiple Input Methods**: Local file, URL, or inline certificate content
- 🔒 **System Integration**: Installs to system CA store and runs `update-ca-certificates`
- 🐳 **BuildKit Support**: Optional generation of `buildkit.toml` configuration file
- ✅ **Simple**: Just install the cert - Docker will automatically trust it
- 🛡️ **Robust**: Comprehensive error handling and validation
- 🔄 **Idempotent**: Safe to run multiple times

## Usage

The action **auto-detects** the certificate source type (file path, URL, or inline content), making it simple to use.

### Quick Start (File Path)

```yaml
- name: Install custom certificate
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: 'certs/company-ca.crt'
```

### From URL (Auto-Detected)

```yaml
- name: Install certificate from URL
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: 'https://pki.company.com/ca.crt'
```

### From GitHub Secret (Auto-Detected as Inline)

```yaml
- name: Install certificate from secret
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: ${{ secrets.CUSTOM_CA_CERT }}
    certificateName: 'company-ca.crt'
```

### With BuildKit Configuration

```yaml
- name: Install certificate and generate buildkit.toml
  id: install-cert
  uses: LiquidLogicLabs/git-action-ca-certificate-import@v2
  with:
    certificate: 'certs/company-ca.crt'
    generateBuildkit: 'true'

- name: Use buildkit.toml for Docker builds
  run: |
    echo "buildkit.toml generated at: ${{ steps.install-cert.outputs.buildkitPath }}"
    # Copy to Docker BuildKit config directory
    mkdir -p ~/.docker/buildx
    cp ${{ steps.install-cert.outputs.buildkitPath }} ~/.docker/buildx/config.toml
```

📚 **More examples:** See [docs/EXAMPLES.md](docs/EXAMPLES.md)

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `certificate` | Certificate source: auto-detects file path, URL, or inline content. See [Input Methods](#input-methods) below | Yes | - |
| `certificateName` | Name for certificate file | No | Auto-generated |
| `verbose` | Enable verbose debug logging | No | `false` |
| `generateBuildkit` | Generate buildkit.toml configuration file | No | `false` |
| `buildkitRuntime` | Container runtime for BuildKit (e.g., 'io.containerd.runc.v2'). Leave empty to omit runtime configuration | No | - |
| `skipCertificateCheck` | Skip TLS certificate verification when downloading certificates from URLs | No | `false` |

## Outputs

| Output | Description |
|--------|-------------|
| `certificatePath` | Path where certificate was installed |
| `certificateName` | Name of the installed certificate file |
| `buildkitPath` | Path to the generated buildkit.toml file (only set if generateBuildkit is true) |

## How It Works

1. **Auto-Detects Source**: Automatically detects if input is a URL, file path, or inline content
2. **Acquires Certificate**: Downloads from URL, reads from file, or uses inline content
3. **Validates Format**: Ensures certificate is valid PEM format
4. **System Installation**: Copies to `/usr/local/share/ca-certificates/` and runs `update-ca-certificates`
5. **BuildKit Configuration** (optional): Generates `buildkit.toml` file with CA certificate settings
6. **Reports Success**: Outputs installation path, certificate name, and buildkit.toml path

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

The action **auto-detects** the certificate source type - just provide the certificate and it figures out the rest!

1. **Local File Path** - Reference a certificate file in the repository (auto-detected)
   ```yaml
   certificate: 'certs/company-ca.crt'
   ```

2. **URL** - Download certificate from a web location (auto-detected if starts with `http://` or `https://`)
   ```yaml
   certificate: 'https://pki.company.com/ca.crt'
   ```

3. **Inline Content** - Provide certificate content directly (auto-detected if contains `-----BEGIN CERTIFICATE-----`)
   ```yaml
   certificate: ${{ secrets.CUSTOM_CA_CERT }}
   ```

The action automatically detects which type you're using based on the input format - no need to specify!

### Use Cases

- **Private Docker Registry**: Install corporate CA to pull/push images
- **Internal Resources**: Access internal URLs during build (pip, npm, etc.)
- **Development Environments**: Support self-signed certificates in test pipelines
- **Security Compliance**: Use organization-specific certificate authorities

## Versioning

This action follows [Semantic Versioning](https://semver.org/).

**Recommended usage:**
```yaml
uses: LiquidLogicLabs/git-action-ca-certificate-import@v2  # Gets latest v2.x.x
```

**Version pinning options:**
- `@v2` - Latest v2.x.x (major version) - **Recommended** (includes auto-detection)
- `@v1` - Latest v1.x.x (legacy - requires certificate-source and certificate-body)
- `@latest` - Latest stable release
- `@v2.0.0` - Exact version

**Breaking Change Notice**: Version v2.0.0 introduces auto-detection. The `certificate-source` and `certificate-body` inputs have been replaced with a single `certificate` input that auto-detects the source type.

## Security

### Security Considerations

- **Certificate Validation**: The action validates that certificates are in valid PEM format before installation
- **System Access**: Requires `sudo` privileges to write to `/usr/local/share/ca-certificates/` and run `update-ca-certificates`
- **Certificate Source**: Always verify the source of certificates, especially when using URLs or inline content
- **Secrets Management**: When using inline certificates, store the certificate content in GitHub Secrets and reference via `${{ secrets.CERT_NAME }}`
- **Network Security**: URL-based certificate downloads use standard `curl` with TLS verification enabled

### Best Practices

- ✅ Use GitHub Secrets for sensitive certificate content
- ✅ Verify certificate fingerprints before installation
- ✅ Use specific version tags (`@v1.1.3`) in production workflows
- ✅ Regularly update to the latest stable version for security patches
- ⚠️ Avoid committing certificates directly to repositories
- ⚠️ Use organization-approved certificate sources only

## Documentation

- 📖 [Examples](docs/EXAMPLES.md) - Comprehensive usage examples
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- 🛠️ [Development](docs/DEVELOPMENT.md) - Development setup, contributing guidelines, and release procedures

## Troubleshooting

Having issues? Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for common problems and solutions.

## Contributing

Contributions welcome! See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for development setup and contribution guidelines.

## License

[MIT License](LICENSE) - see LICENSE file for details.

