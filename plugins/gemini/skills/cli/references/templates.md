# Gemini CLI Prompt Templates

**Important:** Gemini provides consulting and search services. Claude Code remains responsible for all code writing, file operations, and command execution.

Use these templates for:
- **Code review** (second opinions)
- **Web research** (current information)
- **Architecture analysis** (codebase investigation)

---

## Code Review

### Comprehensive Review
```bash
gemini "Review [file] that Claude Code wrote and tell me:
1) What features it has
2) Any bugs or security issues
3) Suggestions for improvement
4) Code quality assessment" -o text
```

### Security-Focused Review
```bash
gemini "Review [file] for security vulnerabilities including:
- XSS (cross-site scripting)
- SQL injection
- Command injection
- Insecure data handling
- Authentication issues
Report findings with severity levels." -o text
```

### Performance Review
```bash
gemini "Analyze [file] for performance issues:
- Inefficient algorithms
- Memory leaks
- Unnecessary re-renders
- Blocking operations
- Optimization opportunities
Provide specific recommendations." -o text
```

### Code Quality Assessment
```bash
gemini "Assess code quality of [file]:
- Readability and maintainability
- Adherence to best practices
- Potential technical debt
- Suggested improvements" -o text
```

---

## Web Research

### Current Information
```bash
gemini "What are the latest [topic] as of [date]? Use Google Search to find current information. Summarize key points." -o text
```

### Library/API Research
```bash
gemini "Research [library/API] and provide:
- Latest version and changes
- Best practices
- Common patterns
- Gotchas to avoid
Use Google Search for current information." -o text
```

### Comparison Research
```bash
gemini "Compare [option A] vs [option B] for [use case]. Use Google Search for current benchmarks and community opinions. Provide recommendation." -o text
```

### Security Vulnerability Research
```bash
gemini "What are the known security vulnerabilities in [library] version [x.y.z]? Use Google Search. Include CVE numbers and severity ratings." -o text
```

### Best Practices Research
```bash
gemini "What are the current best practices for [topic] as of [date]? Use Google Search to find recent articles and official documentation." -o text
```

---

## Architecture Analysis

### Project Analysis
```bash
gemini "Use the codebase_investigator tool to analyze this project. Report on:
- Overall architecture
- Key dependencies
- Component relationships
- Potential issues" -o text
```

### Dependency Analysis
```bash
gemini "Analyze dependencies in this project:
- Direct vs transitive
- Outdated packages
- Security vulnerabilities
- Bundle size impact
Use available tools to gather information." -o text
```

### Flow Analysis
```bash
gemini "Use codebase_investigator to map the [authentication/payment/data] flow in this project. Identify all components involved." -o text
```

### Technical Debt Assessment
```bash
gemini "Use codebase_investigator to identify potential technical debt:
- Deprecated patterns
- Inconsistent conventions
- Missing documentation
- Complex dependencies" -o text
```

---

## Code Explanation

### Detailed Explanation
```bash
gemini "Explain what [file/function] does in detail:
- Purpose and use case
- How it works step by step
- Key algorithms/patterns used
- Dependencies and side effects" -o text
```

### Error Diagnosis
```bash
gemini "Diagnose this error:
[error message]
Context: [relevant context]
Provide:
- Root cause
- Recommended solution approach
- Prevention tips" -o text
```

### Design Pattern Identification
```bash
gemini "Analyze [file/codebase] and identify the design patterns being used. Explain their purpose and effectiveness." -o text
```

---

## Template Variables

Use these placeholders in templates:

- `[file]` - File path or name
- `[directory]` - Directory path
- `[library/API]` - Library or API name
- `[topic]` - Subject matter for research
- `[date]` - Date for time-sensitive queries
- `[use case]` - Specific use case scenario
- `[option A/B]` - Options to compare
- `[error message]` - Error text
- `[context]` - Relevant contextual information
