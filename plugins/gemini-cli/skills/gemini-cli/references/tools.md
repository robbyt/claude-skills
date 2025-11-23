# Gemini CLI Built-in Tools

Gemini's unique capabilities and tool comparison with Claude Code.

## Unique Tools (Gemini Only)

### google_web_search

Real-time internet search via Google Search API.

**Usage:**
```bash
gemini "What are the latest React 19 features? Use Google Search." -o text
```

**Best For:**
- Current events and news
- Latest library versions/documentation
- Community opinions and benchmarks
- Anything requiring post-cutoff information

**Examples:**
- "What are the security vulnerabilities in lodash 4.x? Use Google Search."
- "Best practices for Next.js 14 app router in November 2025."

---

### codebase_investigator

Deep architectural analysis and dependency mapping.

**Usage:**
```bash
gemini "Use codebase_investigator to analyze this project" -o text
```

**Output Includes:**
- Architecture overview
- Component relationships
- Dependency chains
- Potential issues/inconsistencies

**Best For:**
- Onboarding to unfamiliar codebases
- Understanding legacy systems
- Finding hidden dependencies
- Architecture documentation

**Example:**
```bash
gemini "Use codebase_investigator to map the authentication flow" -o text
```

---

### save_memory

Cross-session persistent memory storage.

**Usage:**
```bash
gemini "Remember that this project uses Zustand for state management. Save this to memory." -o text
```

**Best For:**
- Project conventions
- User preferences
- Recurring context
- Custom instructions

---

## Tool Comparison

Gemini has standard file/search tools similar to Claude Code, plus unique capabilities:

| Capability | Claude Code | Gemini CLI |
|------------|-------------|------------|
| File listing | LS, Glob | list_directory, glob |
| File reading | Read | read_file |
| Code search | Grep | search_file_content |
| Web fetch | WebFetch | web_fetch |
| **Web search** | WebSearch | **google_web_search** ⭐ |
| **Architecture** | Task (Explore) | **codebase_investigator** ⭐ |
| **Memory** | N/A | **save_memory** ⭐ |
| Task tracking | TodoWrite | write_todos |

⭐ = Gemini's unique advantages

---

## JSON Output Stats

When using `-o json`, tool usage is reported in stats:

```json
{
  "response": "actual content",
  "stats": {
    "tools": {
      "totalCalls": 3,
      "byName": {
        "google_web_search": {
          "count": 1,
          "success": 1,
          "durationMs": 3000
        }
      }
    }
  }
}
```

---

## Tool Combination Patterns

Leverage multiple tools in single prompts:

**Research → Implement:**
```bash
gemini "Use Google Search to find best practices for [topic], then implement them" -o text
```

**Analyze → Report:**
```bash
gemini "Use codebase_investigator to analyze the project, then write a summary report" -o text
```

**Search → Suggest:**
```bash
gemini "Find all files using deprecated API, read them, and suggest updates" -o text
```
