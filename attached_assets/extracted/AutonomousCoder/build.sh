#!/bin/bash

# Autonomous Coder Build Script
# This script builds the entire Autonomous Coder project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build configuration
BUILD_CONFIGURATION=${BUILD_CONFIGURATION:-release}
ENABLE_TESTING=${ENABLE_TESTING:-true}
ENABLE_DOCS=${ENABLE_DOCS:-true}

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for Swift
    if ! command -v swift &> /dev/null; then
        print_error "Swift is not installed. Please install Xcode or Swift toolchain."
        exit 1
    fi
    
    # Check Swift version
    SWIFT_VERSION=$(swift --version | head -n1)
    print_info "Swift version: $SWIFT_VERSION"
    
    # Check for Xcode (macOS builds)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v xcodebuild &> /dev/null; then
            print_warning "Xcode not found. macOS app builds will be skipped."
            SKIP_MACOS=true
        fi
    fi
    
    print_success "Prerequisites check completed"
}

setup_directories() {
    print_header "Setting Up Directories"
    
    # Create build directories
    mkdir -p .build/debug
    mkdir -p .build/release
    mkdir -p .build/docs
    mkdir -p .build/test-results
    
    # Create data directories
    mkdir -p "${HOME}/Library/Application Support/AutonomousCoder"
    mkdir -p "${HOME}/Library/Logs/AutonomousCoder"
    
    print_success "Directories created"
}

build_shared_modules() {
    print_header "Building Shared Modules"
    
    # Build Core module
    print_info "Building Core module..."
    swift build --target AutonomousCoderCore --configuration "$BUILD_CONFIGURATION"
    print_success "Core module built"
    
    # Build AI module
    print_info "Building AI module..."
    swift build --target AutonomousCoderAI --configuration "$BUILD_CONFIGURATION"
    print_success "AI module built"
    
    # Build Data module
    print_info "Building Data module..."
    swift build --target AutonomousCoderData --configuration "$BUILD_CONFIGURATION"
    print_success "Data module built"
    
    # Build Security module
    print_info "Building Security module..."
    swift build --target AutonomousCoderSecurity --configuration "$BUILD_CONFIGURATION"
    print_success "Security module built"
    
    # Build Monitoring module
    print_info "Building Monitoring module..."
    swift build --target AutonomousCoderMonitoring --configuration "$BUILD_CONFIGURATION"
    print_success "Monitoring module built"
    
    # Build Orchestration module
    print_info "Building Orchestration module..."
    swift build --target AutonomousCoderOrchestration --configuration "$BUILD_CONFIGURATION"
    print_success "Orchestration module built"
}

build_cli() {
    print_header "Building CLI"
    
    print_info "Building AutonomousCoderCLI..."
    swift build --target AutonomousCoderCLI --configuration "$BUILD_CONFIGURATION"
    
    # Create symlink for easy access
    ln -sf "$(swift build --show-bin-path --configuration "$BUILD_CONFIGURATION")/AutonomousCoderCLI" .build/autonomous-coder 2>/dev/null || true
    
    print_success "CLI built"
}

build_macos_app() {
    if [[ "$SKIP_MACOS" == "true" ]]; then
        print_warning "Skipping macOS app build"
        return
    fi
    
    print_header "Building macOS App"
    
    cd macOS
    
    if [[ -f "AutonomousCoder.xcodeproj/project.pbxproj" ]]; then
        print_info "Building macOS app with xcodebuild..."
        
        xcodebuild \
            -project AutonomousCoder.xcodeproj \
            -scheme AutonomousCoder \
            -configuration "$BUILD_CONFIGURATION" \
            build
        
        print_success "macOS app built"
    else
        print_warning "macOS Xcode project not found, skipping"
    fi
    
    cd ..
}

build_ios_app() {
    if [[ "$SKIP_MACOS" == "true" ]]; then
        print_warning "Skipping iOS app build (requires macOS)"
        return
    fi
    
    print_header "Building iOS App"
    
    cd ios
    
    if [[ -f "AutonomousCoder.xcodeproj/project.pbxproj" ]]; then
        print_info "Building iOS app with xcodebuild..."
        
        xcodebuild \
            -project AutonomousCoder.xcodeproj \
            -scheme AutonomousCoder \
            -configuration "$BUILD_CONFIGURATION" \
            -sdk iphonesimulator \
            build
        
        print_success "iOS app built"
    else
        print_warning "iOS Xcode project not found, skipping"
    fi
    
    cd ..
}

run_tests() {
    if [[ "$ENABLE_TESTING" != "true" ]]; then
        print_warning "Testing disabled"
        return
    fi
    
    print_header "Running Tests"
    
    # Run unit tests
    print_info "Running unit tests..."
    swift test --parallel
    
    # Generate test coverage if available
    if swift test --help | grep -q "--enable-code-coverage"; then
        print_info "Generating test coverage report..."
        swift test --enable-code-coverage
    fi
    
    print_success "Tests completed"
}

generate_documentation() {
    if [[ "$ENABLE_DOCS" != "true" ]]; then
        print_warning "Documentation generation disabled"
        return
    fi
    
    print_header "Generating Documentation"
    
    # Check for swift-doc
    if command -v swift-doc &> /dev/null; then
        print_info "Generating API documentation..."
        swift-doc generate Sources --module-name AutonomousCoder --output .build/docs
        print_success "Documentation generated"
    else
        print_warning "swift-doc not found, skipping documentation generation"
    fi
}

create_package() {
    print_header "Creating Distribution Package"
    
    local package_name="AutonomousCoder-$(date +%Y%m%d)"
    local package_dir=".build/packages/$package_name"
    
    mkdir -p "$package_dir"
    
    # Copy binaries
    if [[ -f ".build/autonomous-coder" ]]; then
        cp .build/autonomous-coder "$package_dir/"
    fi
    
    # Copy configuration
    cp -r Resources "$package_dir/" 2>/dev/null || true
    
    # Copy documentation
    cp README.md LICENSE "$package_dir/"
    
    # Create package
    if command -v zip &> /dev/null; then
        cd ".build/packages"
        zip -r "$package_name.zip" "$package_name"
        cd ../..
        
        print_success "Package created: .build/packages/$package_name.zip"
    elif command -v tar &> /dev/null; then
        cd ".build/packages"
        tar -czf "$package_name.tar.gz" "$package_name"
        cd ../..
        
        print_success "Package created: .build/packages/$package_name.tar.gz"
    fi
}

run_integration_tests() {
    print_header "Running Integration Tests"
    
    # Test CLI
    if [[ -f ".build/autonomous-coder" ]]; then
        print_info "Testing CLI help command..."
        if .build/autonomous-coder help &>/dev/null; then
            print_success "CLI integration test passed"
        else
            print_error "CLI integration test failed"
        fi
    fi
    
    # Test configuration loading
    print_info "Testing configuration system..."
    if swift run AutonomousCoderCLI config show &>/dev/null; then
        print_success "Configuration test passed"
    else
        print_error "Configuration test failed"
    fi
}

cleanup() {
    print_header "Cleanup"
    
    # Remove temporary files
    find . -name "*.swp" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    print_success "Cleanup completed"
}

print_summary() {
    print_header "Build Summary"
    
    echo -e "${GREEN}✅ Shared modules built${NC}"
    echo -e "${GREEN}✅ CLI built${NC}"
    
    if [[ "$SKIP_MACOS" != "true" ]]; then
        echo -e "${GREEN}✅ macOS app built${NC}"
        echo -e "${GREEN}✅ iOS app built${NC}"
    fi
    
    if [[ "$ENABLE_TESTING" == "true" ]]; then
        echo -e "${GREEN}✅ Tests passed${NC}"
    fi
    
    if [[ "$ENABLE_DOCS" == "true" ]]; then
        echo -e "${GREEN}✅ Documentation generated${NC}"
    fi
    
    print_info "Build artifacts located in .build/"
    print_info "CLI binary: .build/autonomous-coder"
    print_info "Run './build.sh help' for usage information"
}

show_help() {
    cat << EOF
Autonomous Coder Build Script

Usage: ./build.sh [OPTIONS]

Options:
    --debug             Build in debug configuration (default: release)
    --no-tests          Skip running tests
    --no-docs           Skip generating documentation
    --clean             Clean build artifacts before building
    --package           Create distribution package
    --help              Show this help message

Examples:
    ./build.sh                          # Build everything in release mode
    ./build.sh --debug                  # Build in debug mode
    ./build.sh --no-tests --no-docs     # Build without tests and docs
    ./build.sh --clean --package        # Clean build and create package

Environment Variables:
    BUILD_CONFIGURATION    Build configuration (debug|release)
    ENABLE_TESTING         Enable/disable tests (true|false)
    ENABLE_DOCS           Enable/disable documentation (true|false)

EOF
}

# Main build process
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --debug)
            BUILD_CONFIGURATION="debug"
            shift
            ;;
        --no-tests)
            ENABLE_TESTING="false"
            shift
            ;;
        --no-docs)
            ENABLE_DOCS="false"
            shift
            ;;
        --clean)
            print_info "Cleaning build artifacts..."
            rm -rf .build
            shift
            ;;
        --package)
            CREATE_PACKAGE="true"
            shift
            ;;
    esac
    
    print_header "Autonomous Coder Build Script"
    print_info "Configuration: $BUILD_CONFIGURATION"
    print_info "Testing: $ENABLE_TESTING"
    print_info "Documentation: $ENABLE_DOCS"
    
    check_prerequisites
    setup_directories
    build_shared_modules
    build_cli
    build_macos_app
    build_ios_app
    run_tests
    generate_documentation
    
    if [[ "$CREATE_PACKAGE" == "true" ]]; then
        create_package
    fi
    
    run_integration_tests
    cleanup
    print_summary
}

# Run main function with all arguments
main "$@"