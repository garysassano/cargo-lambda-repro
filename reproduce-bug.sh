#!/bin/bash

# Cargo Lambda Target Bug Reproduction Script
# This script helps reproduce the bug where cargo-lambda auto-installs
# a target but then fails to use it properly.

set -e

echo "======================================"
echo "Cargo Lambda Target Bug Reproduction"
echo "======================================"
echo

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found. Please install Rust first."
    exit 1
fi

if ! command -v zig &> /dev/null; then
    echo "❌ Zig not found. Please install Zig 0.13.0 or newer."
    echo "   Visit: https://ziglang.org/download/"
    exit 1
fi

if ! command -v "cargo-lambda" &> /dev/null; then
    echo "❌ cargo-lambda not found. Please install it first:"
    echo "   pip3 install cargo-lambda"
    echo "   OR"
    echo "   cargo install cargo-lambda"
    exit 1
fi

echo "✅ All prerequisites found"
echo

# Show current state
echo "Current environment:"
echo "  Rust:        $(rustc --version)"
echo "  Cargo:       $(cargo --version)"
echo "  Zig:         $(zig version)"
echo "  cargo-lambda: $(cargo lambda --version)"
echo

echo "Currently installed targets:"
rustup target list --installed
echo

# Check if ARM64 target is installed
if rustup target list --installed | grep -q "aarch64-unknown-linux-gnu"; then
    echo "⚠️  ARM64 target is already installed. Removing it to reproduce the bug..."
    rustup target remove aarch64-unknown-linux-gnu
    echo "✅ ARM64 target removed"
else
    echo "✅ ARM64 target not installed (good for reproducing bug)"
fi
echo

echo "Targets after cleanup:"
rustup target list --installed
echo

# Now try to build - this should trigger the bug
echo "======================================"
echo "Attempting cargo lambda build --arm64"
echo "======================================"
echo "This should:"
echo "1. ✅ Detect missing aarch64-unknown-linux-gnu target"
echo "2. ✅ Automatically install the target"
echo "3. ❌ Fail with 'target may not be installed' error"
echo

echo "Running: cargo lambda build --release --arm64"
echo

# Capture the exit code but continue
if cargo lambda build --release --arm64; then
    echo
    echo "🤔 Unexpected: Build succeeded! The bug might be fixed or environment-specific."
else
    exit_code=$?
    echo
    echo "❌ Build failed with exit code: $exit_code"
    echo "   This demonstrates the bug!"
fi

echo
echo "======================================"
echo "Post-build analysis"
echo "======================================"

echo "Targets after build attempt:"
rustup target list --installed
echo

if rustup target list --installed | grep -q "aarch64-unknown-linux-gnu"; then
    echo "✅ ARM64 target WAS installed by cargo-lambda"
else
    echo "❌ ARM64 target was NOT installed"
fi

echo
echo "Target directory contents:"
if [ -d "target" ]; then
    find target -name "bootstrap*" -o -name "*.so" -o -name "lambda" | head -10
else
    echo "No target directory found"
fi

echo
echo "======================================"
echo "Workaround test"
echo "======================================"
echo "Ensuring target is properly installed and trying again..."

rustup target add aarch64-unknown-linux-gnu
echo "Running: cargo lambda build --release --arm64"

if cargo lambda build --release --arm64; then
    echo
    echo "✅ Workaround successful! Pre-installing the target fixes the issue."
else
    echo
    echo "❌ Even the workaround failed. There might be other issues."
fi

echo
echo "Final target directory contents:"
find target -name "bootstrap*" -o -name "*.so" -o -name "lambda" | head -10

echo
echo "======================================"
echo "Summary"
echo "======================================"
echo "This reproduction demonstrates that cargo-lambda has an issue"
echo "with automatically installed targets. The workaround is to"
echo "pre-install the target with: rustup target add aarch64-unknown-linux-gnu"
