#!/bin/bash

# Build script for CaffeinateControl pmset helper
# Creates a universal binary (arm64 + x86_64) for macOS

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_FILE="$SCRIPT_DIR/caffeinatecontrol-pmset.c"
OUTPUT_NAME="caffeinatecontrol-pmset"
OUTPUT_DIR="${1:-$SCRIPT_DIR/../build}"

echo "🔨 Building CaffeinateControl pmset helper..."
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "⚠️  Not on macOS - skipping helper build"
    echo "   The helper must be built on macOS for proper architecture support"
    exit 0
fi

# Check for source file
if [ ! -f "$SOURCE_FILE" ]; then
    echo "❌ Source file not found: $SOURCE_FILE"
    exit 1
fi

# Compile for arm64 (Apple Silicon)
echo "📦 Compiling for arm64 (Apple Silicon)..."
clang -arch arm64 \
    -O2 \
    -Wall -Wextra -Werror \
    -o "$OUTPUT_DIR/${OUTPUT_NAME}_arm64" \
    "$SOURCE_FILE"

# Compile for x86_64 (Intel)
echo "📦 Compiling for x86_64 (Intel)..."
clang -arch x86_64 \
    -O2 \
    -Wall -Wextra -Werror \
    -o "$OUTPUT_DIR/${OUTPUT_NAME}_x86_64" \
    "$SOURCE_FILE"

# Create universal binary using lipo
echo "🔗 Creating universal binary..."
lipo -create \
    "$OUTPUT_DIR/${OUTPUT_NAME}_arm64" \
    "$OUTPUT_DIR/${OUTPUT_NAME}_x86_64" \
    -output "$OUTPUT_DIR/$OUTPUT_NAME"

# Clean up architecture-specific binaries
rm -f "$OUTPUT_DIR/${OUTPUT_NAME}_arm64" "$OUTPUT_DIR/${OUTPUT_NAME}_x86_64"

# Verify the universal binary
echo ""
echo "✅ Universal binary created successfully!"
echo ""
echo "📋 Binary info:"
file "$OUTPUT_DIR/$OUTPUT_NAME"
echo ""
echo "📊 Architectures:"
lipo -info "$OUTPUT_DIR/$OUTPUT_NAME"
echo ""
echo "📏 Size: $(du -h "$OUTPUT_DIR/$OUTPUT_NAME" | cut -f1)"
echo ""
echo "📍 Location: $OUTPUT_DIR/$OUTPUT_NAME"
echo ""
echo "🔐 To install with proper permissions, run:"
echo "   sudo chown root:wheel $OUTPUT_DIR/$OUTPUT_NAME"
echo "   sudo chmod 4755 $OUTPUT_DIR/$OUTPUT_NAME"
echo "   sudo mv $OUTPUT_DIR/$OUTPUT_NAME /usr/local/bin/"
