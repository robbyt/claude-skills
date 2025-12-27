#!/bin/bash
# Apple Docs MCP wrapper - invokes apple-docs-mcp via JSON-RPC
# Usage: apple-docs.sh <tool_name> '<json_arguments>'
# Example: apple-docs.sh search_apple_docs '{"query":"SwiftUI List"}'

set -e

# External MCP server configuration
# Package: https://github.com/kimsungwhee/apple-docs-mcp
# Install: npx will auto-install on first run
MCP_PACKAGE="@kimsungwhee/apple-docs-mcp"
MCP_VERSION="1.0.26"

TOOL_NAME="$1"
TOOL_ARGS="$2"

if [ -z "$TOOL_NAME" ]; then
    echo "Usage: apple-docs.sh <tool_name> '<json_arguments>'"
    echo ""
    echo "Tools: search_apple_docs, get_apple_doc_content, list_technologies,"
    echo "       search_framework_symbols, get_related_apis, find_similar_apis,"
    echo "       get_platform_compatibility, resolve_references_batch,"
    echo "       get_documentation_updates, get_technology_overviews, get_sample_code,"
    echo "       list_wwdc_videos, search_wwdc_content, get_wwdc_video,"
    echo "       get_wwdc_code_examples, browse_wwdc_topics, find_related_wwdc_videos,"
    echo "       list_wwdc_years"
    exit 1
fi

# Default to empty object if no args provided
if [ -z "$TOOL_ARGS" ]; then
    TOOL_ARGS="{}"
fi

# Create temp file for output
OUTFILE=$(mktemp)
trap "rm -f $OUTFILE" EXIT

# Send JSON-RPC messages to MCP server
{
    printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"apple-docs-wrapper","version":"1.0"}}}'
    printf '%s\n' '{"jsonrpc":"2.0","method":"notifications/initialized"}'
    printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"$TOOL_NAME\",\"arguments\":$TOOL_ARGS}}"
} | npx -y "${MCP_PACKAGE}@${MCP_VERSION}" 2>/dev/null > "$OUTFILE" &

PID=$!

# Wait up to 30 seconds for response
for i in {1..30}; do
    sleep 1
    # Check if we have the tool response (id:2)
    if grep -q '"id":2' "$OUTFILE" 2>/dev/null; then
        kill $PID 2>/dev/null || true
        break
    fi
    # Check if process died
    if ! kill -0 $PID 2>/dev/null; then
        break
    fi
done

# Kill if still running
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true

# Extract and output the tool response (second JSON line)
if [ -f "$OUTFILE" ]; then
    # Get the line containing the tool response
    RESPONSE=$(grep '"id":2' "$OUTFILE" 2>/dev/null || echo "")
    if [ -n "$RESPONSE" ]; then
        echo "$RESPONSE"
    else
        echo '{"error":"No response received from MCP server"}'
        exit 1
    fi
else
    echo '{"error":"Failed to get response"}'
    exit 1
fi
