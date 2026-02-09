#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$INPUT_VERBOSE" = "true" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return $?
    fi

    if command -v sudo >/dev/null 2>&1; then
        sudo "$@"
        return $?
    fi

    log_error "This action requires root privileges (or sudo), but sudo is not available."
    exit 1
}

# Enable verbose mode if requested
if [ "$INPUT_VERBOSE" = "true" ]; then
    set -x
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔍 VERBOSE MODE ENABLED${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_debug "Environment Information:"
    log_debug "  INPUT_CERTIFICATE: ${INPUT_CERTIFICATE:0:50}${INPUT_CERTIFICATE:+...}"
    log_debug "  INPUT_CERTIFICATE_NAME: ${INPUT_CERTIFICATE_NAME:-<not set>}"
    log_debug "  INPUT_VERBOSE: ${INPUT_VERBOSE}"
    log_debug "  INPUT_GENERATE_BUILDKIT: ${INPUT_GENERATE_BUILDKIT:-<not set>}"
    log_debug "  INPUT_SKIP_CERTIFICATE_CHECK: ${INPUT_SKIP_CERTIFICATE_CHECK:-<not set>}"
    log_debug "  Working Directory: $(pwd)"
    log_debug "  User: $(whoami 2>/dev/null || echo '<unknown>')"
    log_debug "  Runner OS: ${RUNNER_OS:-<not set>}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# Validate required inputs
if [ -z "$INPUT_CERTIFICATE" ]; then
    log_error "certificate input is required"
    exit 1
fi

# Function to detect certificate source type
detect_certificate_type() {
    local input="$1"
    
    # 1. Check if it's a URL (highest priority - most specific)
    if [[ "$input" =~ ^https?:// ]]; then
        echo "url"
        return 0
    fi
    
    # 2. Check if it's inline content (contains PEM markers)
    # This check comes before file existence to handle edge cases where
    # a string contains PEM content but also looks like a file path
    # Check for BEGIN and CERTIFICATE markers (handles various PEM formats)
    if echo "$input" | grep -qE "BEGIN[[:space:]]+.*CERTIFICATE" || echo "$input" | grep -qF -- "-----BEGIN CERTIFICATE-----"; then
        echo "inline"
        return 0
    fi
    
    # 3. Check if it's a file path that exists
    if [ -f "$input" ]; then
        echo "file"
        return 0
    fi
    
    # 4. Could not determine type
    echo "unknown"
    return 1
}

# Determine certificate name
CERT_NAME="$INPUT_CERTIFICATE_NAME"
if [ -z "$CERT_NAME" ]; then
    CERT_NAME="custom-ca-$(date +%s).crt"
    log_info "No certificate name provided, using: $CERT_NAME"
else
    log_debug "Using provided certificate name: $CERT_NAME"
fi

# Create temporary directory for certificate processing
TEMP_DIR=$(mktemp -d)
TEMP_CERT="$TEMP_DIR/$CERT_NAME"
log_debug "Created temporary directory: $TEMP_DIR"
log_debug "Temporary certificate path: $TEMP_CERT"

# Detect certificate source type automatically
CERT_TYPE=$(detect_certificate_type "$INPUT_CERTIFICATE")
log_debug "Auto-detected certificate type: $CERT_TYPE"

# Acquire certificate based on auto-detected type
case "$CERT_TYPE" in
    "url")
        log_info "Auto-detected: URL source"
        log_info "Downloading certificate from: $INPUT_CERTIFICATE"
        log_debug "Using curl to download certificate..."
        CURL_FLAGS="-fsSL"
        if [ "$INPUT_SKIP_CERTIFICATE_CHECK" = "true" ]; then
            log_warn "TLS certificate verification is disabled. This is a security risk and should only be used with trusted endpoints."
            CURL_FLAGS="$CURL_FLAGS -k"
        fi
        
        if ! curl $CURL_FLAGS -o "$TEMP_CERT" "$INPUT_CERTIFICATE"; then
            log_error "Failed to download certificate from URL: $INPUT_CERTIFICATE"
            log_error "Please verify the URL is accessible and correct"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        log_info "Certificate downloaded successfully"
        log_debug "Downloaded file size: $(stat -c%s "$TEMP_CERT" 2>/dev/null || stat -f%z "$TEMP_CERT" 2>/dev/null) bytes"
        ;;
        
    "inline")
        log_info "Auto-detected: Inline certificate content"
        log_debug "Certificate content length: ${#INPUT_CERTIFICATE} characters"
        echo "$INPUT_CERTIFICATE" > "$TEMP_CERT"
        ;;
        
    "file")
        log_info "Auto-detected: File path source"
        log_info "Using certificate file: $INPUT_CERTIFICATE"
        log_debug "Source file size: $(stat -c%s "$INPUT_CERTIFICATE" 2>/dev/null || stat -f%z "$INPUT_CERTIFICATE" 2>/dev/null) bytes"
        cp "$INPUT_CERTIFICATE" "$TEMP_CERT"
        ;;
        
    *)
        log_error "Could not determine certificate source type"
        log_error ""
        log_error "The certificate input should be one of:"
        log_error "  1. A URL starting with http:// or https://"
        log_error "     Example: https://pki.company.com/ca.crt"
        log_error ""
        log_error "  2. A file path (relative or absolute) to an existing certificate file"
        log_error "     Example: certs/ca.crt or /path/to/certificate.crt"
        log_error ""
        log_error "  3. Inline certificate content containing -----BEGIN CERTIFICATE----- markers"
        log_error "     Example: Content from GitHub Secrets or workflow variables"
        log_error ""
        log_error "Received input (first 100 chars): ${INPUT_CERTIFICATE:0:100}..."
        rm -rf "$TEMP_DIR"
        exit 1
        ;;
esac

# Show certificate preview in verbose mode
if [ "$INPUT_VERBOSE" = "true" ]; then
    log_debug "Certificate content preview (first 3 lines):"
    head -n 3 "$TEMP_CERT" | sed 's/^/  /'
    log_debug "Certificate content preview (last 2 lines):"
    tail -n 2 "$TEMP_CERT" | sed 's/^/  /'
fi

# Validate certificate format (basic check for PEM format)
log_debug "Validating certificate format..."
if ! grep -q "BEGIN CERTIFICATE" "$TEMP_CERT"; then
    log_error "Invalid certificate format - does not appear to be a valid PEM certificate"
    rm -rf "$TEMP_DIR"
    exit 1
fi

log_info "Certificate format validated"

# Show certificate details in verbose mode
if [ "$INPUT_VERBOSE" = "true" ]; then
    log_debug "Certificate details:"
    if openssl x509 -in "$TEMP_CERT" -noout -subject -issuer -dates 2>/dev/null; then
        log_debug "Certificate parsed successfully"
    else
        log_debug "Could not parse certificate details with openssl (might be a bundle)"
    fi
    
    # Count number of certificates in file
    CERT_COUNT=$(grep -c "BEGIN CERTIFICATE" "$TEMP_CERT")
    log_debug "Number of certificates in file: $CERT_COUNT"
fi

# Install to system CA store
log_info "Installing certificate to system CA store"

# Create directory if it doesn't exist
if [ ! -d /usr/local/share/ca-certificates ]; then
    log_info "Creating /usr/local/share/ca-certificates directory"
    log_debug "Directory does not exist, creating with sudo..."
    run_privileged mkdir -p /usr/local/share/ca-certificates
else
    log_debug "Directory /usr/local/share/ca-certificates already exists"
fi

# Copy certificate
SYSTEM_CERT_PATH="/usr/local/share/ca-certificates/$CERT_NAME"
log_debug "Copying certificate to: $SYSTEM_CERT_PATH"
run_privileged cp "$TEMP_CERT" "$SYSTEM_CERT_PATH"
log_info "Certificate copied to: $SYSTEM_CERT_PATH"

# Verify copy
if [ "$INPUT_VERBOSE" = "true" ]; then
    if [ -f "$SYSTEM_CERT_PATH" ]; then
        log_debug "Certificate file exists at destination"
        log_debug "Destination file size: $(stat -c%s "$SYSTEM_CERT_PATH" 2>/dev/null || stat -f%z "$SYSTEM_CERT_PATH" 2>/dev/null) bytes"
    else
        log_warn "Certificate file not found at destination (might be a permission issue)"
    fi
fi

# Update CA certificates
log_info "Updating system CA certificates"
log_debug "Running update-ca-certificates..."
if [ "$INPUT_VERBOSE" = "true" ]; then
    run_privileged update-ca-certificates -v
else
    run_privileged update-ca-certificates
fi

log_info "System CA certificates updated successfully"

# Generate buildkit.toml if requested
if [ "$INPUT_GENERATE_BUILDKIT" = "true" ]; then
    log_info "Generating buildkit.toml configuration file"
    
    # Create buildkit.toml content
    BUILDKIT_PATH="buildkit.toml"
    cat > "$BUILDKIT_PATH" << EOF
# Docker BuildKit configuration
# Generated by ca-certificate-import-action
# Certificate: $SYSTEM_CERT_PATH

[worker.oci]
  # Custom CA certificates for Docker builds
  image = "moby/buildkit:latest"
  
  # Registry configurations with custom CA
  [[worker.oci.registry]]
    mirrors = ["*"]
    
    # Use custom CA certificate for all registries
    [worker.oci.registry.tls]
      ca = ["$SYSTEM_CERT_PATH"]
      
  # Additional registry-specific configurations can be added here
  # Example for Docker Hub:
  # [[worker.oci.registry]]
  #   mirrors = ["docker.io"]
  #   [worker.oci.registry.tls]
  #     ca = ["$SYSTEM_CERT_PATH"]
EOF

    # Add runtime configuration only if specified
    if [ -n "$INPUT_BUILDKIT_RUNTIME" ]; then
        cat >> "$BUILDKIT_PATH" << EOF

# Container runtime configuration
[worker.containerd]
  runtime = "$INPUT_BUILDKIT_RUNTIME"
  
# Additional buildkit configuration
[worker.containerd.runtimes.runc]
  runtime_type = "$INPUT_BUILDKIT_RUNTIME"
EOF
    fi
    
    log_info "buildkit.toml generated at: $BUILDKIT_PATH"
    
    if [ "$INPUT_VERBOSE" = "true" ]; then
        log_debug "buildkit.toml content:"
        cat "$BUILDKIT_PATH" | sed 's/^/  /'
    fi
    
    # Set buildkit path output
    echo "buildkit-path=$(pwd)/$BUILDKIT_PATH" >> $GITHUB_OUTPUT
    log_debug "Output set: buildkit-path=$(pwd)/$BUILDKIT_PATH"
else
    log_debug "buildkit.toml generation disabled (INPUT_GENERATE_BUILDKIT=false)"
fi

# Set outputs
log_debug "Setting GitHub Action outputs..."
echo "certificate-path=$SYSTEM_CERT_PATH" >> $GITHUB_OUTPUT
echo "certificate-name=$CERT_NAME" >> $GITHUB_OUTPUT
log_debug "Outputs set: certificate-path=$SYSTEM_CERT_PATH, certificate-name=$CERT_NAME"

# Cleanup
log_debug "Cleaning up temporary directory: $TEMP_DIR"
rm -rf "$TEMP_DIR"

if [ "$INPUT_VERBOSE" = "true" ]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Certificate installation completed successfully${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_debug "Final certificate location: $SYSTEM_CERT_PATH"
    log_debug "Certificate is now trusted by Docker and system tools"
    if [ "$INPUT_GENERATE_BUILDKIT" = "true" ]; then
        log_debug "buildkit.toml generated at: $(pwd)/buildkit.toml"
        log_debug "Use this file to configure Docker BuildKit with custom CA certificates"
    fi
    echo ""
else
    log_info "✓ Certificate installation completed successfully"
fi

