# Apple Dev Docs Plugin

On-demand access to Apple Developer Documentation without persistent MCP context overhead.

## How It Works

This plugin provides access to the `@kimsungwhee/apple-docs-mcp` server via JSON-RPC shell-out. Instead of keeping the MCP server running and its 18 tool schemas in context, the plugin:

1. Triggers when you ask about Apple platforms (SwiftUI, UIKit, iOS, macOS, Swift, WWDC, etc.)
2. Invokes the MCP server on-demand via JSON-RPC
3. Returns results and terminates the server

## Features

- **Zero context overhead** when not in use
- **18 MCP tools** available on-demand
- **Bundled WWDC data** (2014-2025) - 1,260+ sessions with full transcripts, offline access
- **Apple JSON API** access for live documentation

## Prerequisites

- Node.js and npm/npx installed
- Network access for live documentation queries (WWDC content is bundled offline)

## Available Tools

### Documentation
- `search_apple_docs` - Search Apple Developer Documentation
- `get_apple_doc_content` - Get detailed documentation content
- `list_technologies` - Browse all Apple technologies/frameworks
- `search_framework_symbols` - Search symbols within a framework

### Discovery
- `get_related_apis` - Find related APIs
- `find_similar_apis` - Discover alternative APIs
- `get_platform_compatibility` - Check platform/version support
- `resolve_references_batch` - Resolve API references

### Updates
- `get_documentation_updates` - Track latest updates
- `get_technology_overviews` - Get comprehensive guides
- `get_sample_code` - Browse sample projects

### WWDC (Bundled Offline)
- `list_wwdc_videos` - Browse WWDC sessions
- `search_wwdc_content` - Full-text search transcripts
- `get_wwdc_video` - Get full video content with transcript
- `get_wwdc_code_examples` - Browse code examples from sessions
- `browse_wwdc_topics` - List topic categories
- `find_related_wwdc_videos` - Discover related sessions
- `list_wwdc_years` - List available years

## Usage

Ask about Apple development topics:

- "How do I create a List in SwiftUI?"
- "What's new in iOS 18?"
- "Search WWDC videos about async/await"
- "Show me ARKit sample code"
- "What protocols does UIViewController conform to?"
