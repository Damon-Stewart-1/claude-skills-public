#!/bin/bash
# Figma Logo QC Hook (PostToolUse on use_figma)
# Detects when Claude creates a fake "EI" text mark instead of cloning the real logo.
# The real logo is a component instance, NOT a rectangle + text combo.

# Only check use_figma tool calls
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [ "$TOOL_NAME" != "mcp__claude_ai_Figma__use_figma" ]; then
  exit 0
fi

# Check the code that was executed for fake logo patterns
CODE="${CLAUDE_TOOL_INPUT:-}"

# Pattern 1: Creating a rectangle + "EI" text (fake logo)
if echo "$CODE" | grep -q "characters.*=.*['\"]EI['\"]" 2>/dev/null; then
  if echo "$CODE" | grep -q "createRectangle\|createText" 2>/dev/null; then
    if echo "$CODE" | grep -q "Mark\|Logo\|logo\|mark\|EIMark" 2>/dev/null; then
      echo "BLOCKED: Detected fake logo creation (rectangle + 'EI' text)." >&2
      echo "" >&2
      echo "The EI logo must be CLONED from an existing instance, never recreated." >&2
      echo "Use this pattern instead:" >&2
      echo "" >&2
      echo "  // Navigate to source page first" >&2
      echo "  const coverPage = figma.root.children.find(p => p.name === 'Cover');" >&2
      echo "  await figma.setCurrentPageAsync(coverPage);" >&2
      echo "  const logoInstance = coverPage.findOne(n => n.name === 'Logo - Dark' && n.type === 'INSTANCE');" >&2
      echo "  const logoClone = logoInstance.clone();" >&2
      echo "  // Then switch to target page and append" >&2
      echo "  await figma.setCurrentPageAsync(targetPage);" >&2
      echo "  targetFrame.appendChild(logoClone);" >&2
      echo "  logoClone.resize(44, 14);" >&2
      echo "  logoClone.x = 1080 - 44 - 56;" >&2
      echo "  logoClone.y = 1080 - 14 - 56;" >&2
      echo "" >&2
      echo "Logo instances exist on: Cover page (103:4689), and can be cloned from there." >&2
      exit 2
    fi
  fi
fi

exit 0
