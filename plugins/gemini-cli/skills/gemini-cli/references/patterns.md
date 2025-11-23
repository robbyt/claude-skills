# Gemini CLI Integration Patterns

**Core Principle:** Claude Code handles all code writing, file operations, and commands. Gemini provides consulting (second opinions) and search capabilities.

---

## Pattern 1: Cross-Validation (Primary Pattern)

Leverage both AIs for highest quality by using their complementary strengths.

### Claude Generates, Gemini Reviews
```bash
# 1. Claude writes code (using normal Claude Code tools)
# (Claude generates the code directly)

# 2. Get Gemini's review
gemini "Review this code for bugs and security issues:
[paste code Claude wrote]
Provide specific findings with severity levels." -o text

# 3. Claude implements fixes based on Gemini's feedback
# (Claude makes the changes)
```

### Gemini Researches, Claude Implements
```bash
# 1. Gemini researches best practices
gemini "Use Google Search to find current best practices for [topic]. Summarize key recommendations." -o text

# 2. Claude implements based on research
# (Claude writes the code following the recommendations)

# 3. Optional: Gemini reviews implementation
gemini "Review this implementation of [topic]. Does it follow best practices found earlier?" -o text
```

### Gemini Analyzes Architecture, Claude Refactors
```bash
# 1. Gemini maps the codebase
gemini "Use codebase_investigator to analyze this project's architecture. Identify areas needing improvement." -o text

# 2. Claude refactors based on analysis
# (Claude makes the architectural changes)

# 3. Gemini validates changes
gemini "Use codebase_investigator again. Has the architecture improved?" -o text
```

### Complementary Strengths
- **Claude:** Complex reasoning, following instructions, writing code, file operations
- **Gemini:** Current web knowledge, Google Search access, deep codebase investigation

---

## Pattern 2: JSON Output for Analysis

Use JSON output to programmatically process Gemini's analysis results.

```bash
gemini "Review [file] for security issues" -o json 2>&1
```

### Parsing Response
```python
import json

result = json.loads(output)
analysis = result["response"]
tokens_used = result["stats"]["models"]["gemini-3-pro"]["tokens"]["total"]
tools_used = result["stats"]["tools"]["byName"]
```

### Use Cases
- Extract specific security findings
- Track analysis costs (token usage)
- Monitor tool usage (google_web_search, codebase_investigator)
- Build automated review pipelines

---

## Pattern 3: Model Selection Strategy

Choose the appropriate Gemini model for the consultation type.

### Decision Tree

```
Is this deep architecture analysis or complex codebase review?
├── Yes → Use default (Gemini 3 Pro)
└── No → Is it a quick web search or simple review?
    ├── Yes → Use gemini-2.5-flash
    └── No → Use gemini-2.5-flash
```

### Examples
```bash
# Deep analysis: Use Pro (default)
gemini "Use codebase_investigator to analyze authentication architecture" -o text

# Quick search: Use Flash
gemini "What's the latest version of React? Use Google Search." -m gemini-2.5-flash -o text

# Code review: Use Flash for faster feedback
gemini "Quick review of this function for obvious bugs" -m gemini-2.5-flash -o text
```

---

## Pattern 4: Rate Limit Management

Strategies for working within Gemini's free tier limits (60/min, 1000/day).

### Let Auto-Retry Handle It
Default behavior - CLI retries automatically with backoff.

### Use Flash for Lower Priority
```bash
# Critical review: Use Pro
gemini "Security review of authentication system" -o text

# Less critical: Use Flash (separate quota)
gemini "Quick opinion on this variable naming" -m gemini-2.5-flash -o text
```

### Batch Related Questions
```bash
# Instead of multiple calls:
gemini "Review file A"
gemini "Review file B"
gemini "Review file C"

# Single batched call:
gemini "Review files A, B, and C. For each file, identify bugs and security issues." -o text
```

---

## Pattern 5: Context Enrichment

Provide rich context for better analysis.

### Using File References
```bash
gemini "Based on @./package.json and @./src/auth.js, review the authentication implementation for security issues." -o text
```

### Using GEMINI.md
Create `.gemini/GEMINI.md` for persistent context:
```markdown
# Project Context

This is a Python project using:
- Framework: FastAPI
- Database: SQLAlchemy with PostgreSQL
- Testing: pytest

## Review Guidelines
- Follow PEP 8 style guidelines
- Check for type hints (PEP 484)
- Verify async/await patterns
```

### Explicit Context in Prompt
```bash
gemini "Given this context:
- Python 3.11+ with FastAPI
- Using async/await patterns
- Type hints required

Review this module for type safety and Python best practices." -o text
```

---

## Pattern 6: Session Continuity for Iterative Analysis

Use sessions for multi-turn consultations.

```bash
# Initial analysis
gemini "Use codebase_investigator to analyze this project's architecture" -o text
# Session saved automatically

# List available sessions
gemini --list-sessions

# Continue analysis in same session
echo "What patterns did you find in the authentication flow?" | gemini -r 1 -o text

# Further refinement
echo "Are there any security concerns with that pattern?" | gemini -r 1 -o text
```

### Use Cases
- Iterative architecture analysis
- Multi-step security reviews
- Building on previous research findings

---

## Pattern 7: Validation of Recommendations

Always validate Gemini's recommendations before implementing.

### Validation Steps

1. **Verify Against Official Docs**
   - Gemini's web search may find outdated information
   - Cross-reference with official documentation

2. **Test Recommendations**
   - Don't blindly implement security suggestions
   - Verify they work in your specific context

3. **Review for Context**
   - Gemini may miss project-specific constraints
   - Ensure recommendations fit your architecture

4. **Get Multiple Opinions**
   - For critical changes, consult multiple sources
   - Use Claude's reasoning to evaluate Gemini's suggestions

---

## Best Practices

### Do: Use Gemini For
- ✓ Code review and security audits
- ✓ Web research for current information
- ✓ Architecture analysis with codebase_investigator
- ✓ Second opinions on design decisions
- ✓ Error diagnosis and troubleshooting
- ✓ Best practice research

### Don't: Use Gemini For
- ✗ Primary code generation (that's Claude's job)
- ✗ File operations (use Claude's tools)
- ✗ Running commands (use Claude's Bash tool)
- ✗ Direct bug fixes (Claude should fix, Gemini reviews)
- ✗ Building features (Claude builds, Gemini consults)

### Remember
- **Claude writes code, Gemini provides feedback**
- **Claude operates files, Gemini analyzes them**
- **Claude implements, Gemini validates**

---

## Anti-Patterns to Avoid

### Don't: Use Gemini as Primary Code Generator
Gemini can generate code, but that's not its role in this skill. Claude Code is better suited for following complex instructions and integrating with your workflow.

**Do**: Have Claude generate code, then get Gemini's review for a second perspective.

### Don't: Ignore Rate Limits
Hammering the API wastes time on retries.

**Do**: Use appropriate models and batch related questions.

### Don't: Trust Recommendations Blindly
Gemini can provide outdated or context-inappropriate suggestions.

**Do**: Validate recommendations against official docs and your project context.

### Don't: Over-Specify in Single Prompt
Extremely long prompts can confuse the model.

**Do**: Break complex analyses into focused questions.

### Don't: Forget Project Context
Gemini doesn't automatically know your project conventions.

**Do**: Use `.gemini/GEMINI.md` or explicit context in prompts for better analysis.
