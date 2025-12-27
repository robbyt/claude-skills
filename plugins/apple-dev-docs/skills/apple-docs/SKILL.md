---
name: apple-docs
description: On-demand access to Apple Developer Documentation via the apple-docs-mcp server. Triggers when users ask about SwiftUI, UIKit, iOS, macOS, watchOS, tvOS, visionOS, Swift, Xcode, WWDC, Apple APIs, or Apple frameworks.
---

# Apple Developer Documentation

Provides on-demand access to Apple Developer Documentation via the apple-docs-mcp server. Triggers when users ask about SwiftUI, UIKit, iOS, macOS, watchOS, tvOS, visionOS, Swift, Xcode, WWDC, Apple APIs, or Apple frameworks.

## Invocation

Use the wrapper script to call MCP tools:

```bash
$PLUGIN_DIR/scripts/apple-docs.sh <tool_name> '<json_arguments>'
```

The script starts the MCP server, sends a JSON-RPC request, returns the response, and terminates. Each call is independent.

## Tool Selection Strategy

### Prefer WWDC Tools for Speed (Bundled Offline)

WWDC content (2014-2025, 1,266 videos) is bundled in the npm package. These tools are fast and work offline:

- `list_wwdc_years` - Get available years and video counts
- `browse_wwdc_topics` - List topic categories (19 topics)
- `list_wwdc_videos` - Browse sessions by year/topic
- `search_wwdc_content` - Full-text search transcripts and code
- `get_wwdc_video` - Get full transcript and code examples
- `get_wwdc_code_examples` - Browse code from sessions
- `find_related_wwdc_videos` - Discover related sessions

### Live Documentation Tools (Network Required)

These query Apple's servers:

- `search_apple_docs` - Search documentation
- `get_apple_doc_content` - Get full doc content
- `list_technologies` - Browse frameworks
- `search_framework_symbols` - Find APIs in a framework
- `get_related_apis` - API relationships
- `find_similar_apis` - Alternative APIs
- `get_platform_compatibility` - Platform/version support
- `get_sample_code` - Sample projects
- `get_documentation_updates` - Latest updates
- `get_technology_overviews` - Comprehensive guides

## Common Patterns

### Search Documentation

```bash
$PLUGIN_DIR/scripts/apple-docs.sh search_apple_docs '{"query":"SwiftUI List","type":"documentation"}'
```

Arguments:
- `query` (required): Search terms
- `type`: "all", "documentation", or "sample"

### Get Document Content

```bash
$PLUGIN_DIR/scripts/apple-docs.sh get_apple_doc_content '{"url":"https://developer.apple.com/documentation/swiftui/list"}'
```

Arguments:
- `url` (required): Full Apple docs URL
- `includeRelatedApis`: Include inheritance/conformances
- `includePlatformAnalysis`: Check platform availability

### Browse Frameworks

```bash
$PLUGIN_DIR/scripts/apple-docs.sh list_technologies '{"category":"App frameworks"}'
```

Arguments:
- `category`: "App frameworks", "Graphics and games", "App services", etc.
- `language`: "swift" or "occ"
- `includeBeta`: Include beta frameworks

### Search Framework Symbols

```bash
$PLUGIN_DIR/scripts/apple-docs.sh search_framework_symbols '{"framework":"swiftui","symbolType":"struct","namePattern":"*View"}'
```

Arguments:
- `framework` (required): Framework identifier (lowercase)
- `symbolType`: "class", "struct", "protocol", "enum", etc.
- `namePattern`: Wildcard pattern like "*View", "UI*"

### Search WWDC Content

```bash
$PLUGIN_DIR/scripts/apple-docs.sh search_wwdc_content '{"query":"async await","searchIn":"both"}'
```

Arguments:
- `query` (required): Search terms
- `searchIn`: "transcript", "code", or "both"
- `year`: Filter by year
- `language`: "swift", "objc", "javascript"

### Get WWDC Video

```bash
$PLUGIN_DIR/scripts/apple-docs.sh get_wwdc_video '{"year":"2024","videoId":"10176","includeTranscript":true}'
```

Arguments:
- `year` (required): WWDC year
- `videoId` (required): Session ID
- `includeTranscript`: Include full transcript
- `includeCode`: Include code examples

### Browse WWDC Topics

```bash
$PLUGIN_DIR/scripts/apple-docs.sh browse_wwdc_topics '{}'
```

Returns 19 topic categories: swift, swiftui-ui-frameworks, machine-learning-ai, spatial-computing, etc.

### Get Sample Code

```bash
$PLUGIN_DIR/scripts/apple-docs.sh get_sample_code '{"searchQuery":"animation","framework":"SwiftUI"}'
```

Arguments:
- `searchQuery`: Keywords
- `framework`: Framework filter
- `beta`: "include", "exclude", or "only"

## Response Format

All responses are JSON-RPC format:

```json
{"result":{"content":[{"type":"text","text":"...markdown content..."}]},"jsonrpc":"2.0","id":2}
```

Extract the `text` field from `result.content[0]` for the actual content.

## Error Handling

If a tool fails, the response contains an error:

```json
{"error":{"code":-32602,"message":"Invalid params","data":"...details..."}}
```

Common issues:
- Network timeout for live docs
- Invalid URL format for get_apple_doc_content
- Unknown framework identifier
