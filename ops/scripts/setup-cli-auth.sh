#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up CLI Authentication for LLM Services"
echo "================================================"
echo ""

# Check if Doppler is configured
if ! command -v doppler &> /dev/null; then
    echo "❌ Error: Doppler CLI not found"
    exit 1
fi

echo "📋 Exporting subscription credentials from Doppler..."
echo ""

# Prioritize user/password (subscription-based access)
export OPENAI_USER=$(doppler secrets get OPENAI_USER --plain 2>/dev/null || doppler secrets get CODEX_USER --plain 2>/dev/null || echo "")
export OPENAI_PASSWORD=$(doppler secrets get OPENAI_PASSWORD --plain 2>/dev/null || doppler secrets get CODEX_PASSWORD --plain 2>/dev/null || echo "")
export ANTHROPIC_USER=$(doppler secrets get ANTHROPIC_USER --plain 2>/dev/null || doppler secrets get CLAUDE_USER --plain 2>/dev/null || echo "")
export ANTHROPIC_PASSWORD=$(doppler secrets get ANTHROPIC_PASSWORD --plain 2>/dev/null || doppler secrets get CLAUDE_PASSWORD --plain 2>/dev/null || echo "")
export GEMINI_USER=$(doppler secrets get GEMINI_USER --plain 2>/dev/null || doppler secrets get GOOGLE_USER --plain 2>/dev/null || echo "")
export GEMINI_PASSWORD=$(doppler secrets get GEMINI_PASSWORD --plain 2>/dev/null || doppler secrets get GOOGLE_PASSWORD --plain 2>/dev/null || echo "")

# Fallback to tokens if user/password not available
if [ -z "$OPENAI_USER" ] || [ -z "$OPENAI_PASSWORD" ]; then
    export OPENAI_TOKEN=$(doppler secrets get OPENAI_TOKEN --plain 2>/dev/null || doppler secrets get CODEX_TOKEN --plain 2>/dev/null || echo "")
fi

if [ -z "$ANTHROPIC_USER" ] || [ -z "$ANTHROPIC_PASSWORD" ]; then
    export ANTHROPIC_TOKEN=$(doppler secrets get ANTHROPIC_TOKEN --plain 2>/dev/null || doppler secrets get CLAUDE_TOKEN --plain 2>/dev/null || echo "")
fi

if [ -z "$GEMINI_USER" ] || [ -z "$GEMINI_PASSWORD" ]; then
    export GEMINI_TOKEN=$(doppler secrets get GEMINI_TOKEN --plain 2>/dev/null || doppler secrets get GOOGLE_TOKEN --plain 2>/dev/null || echo "")
fi

echo "✅ Subscription credentials exported to current shell"
echo ""
echo "📝 Available environment variables:"
echo ""

# Check what's available (prioritize user/password)
if [ -n "$OPENAI_USER" ] && [ -n "$OPENAI_PASSWORD" ]; then
    echo "  ✓ OPENAI_USER + OPENAI_PASSWORD (Codex/OpenAI) - Subscription access"
elif [ -n "$OPENAI_TOKEN" ]; then
    echo "  ✓ OPENAI_TOKEN (Codex/OpenAI) - Token-based (fallback)"
else
    echo "  ✗ Codex/OpenAI - Not configured"
fi

if [ -n "$ANTHROPIC_USER" ] && [ -n "$ANTHROPIC_PASSWORD" ]; then
    echo "  ✓ ANTHROPIC_USER + ANTHROPIC_PASSWORD (Claude) - Subscription access"
elif [ -n "$ANTHROPIC_TOKEN" ]; then
    echo "  ✓ ANTHROPIC_TOKEN (Claude) - Token-based (fallback)"
else
    echo "  ✗ Claude - Not configured"
fi

if [ -n "$GEMINI_USER" ] && [ -n "$GEMINI_PASSWORD" ]; then
    echo "  ✓ GEMINI_USER + GEMINI_PASSWORD (Gemini) - Subscription access"
elif [ -n "$GEMINI_TOKEN" ]; then
    echo "  ✓ GEMINI_TOKEN (Gemini) - Token-based (fallback)"
else
    echo "  ✗ Gemini - Not configured"
fi

echo ""
echo "💡 Usage:"
echo ""
echo "  For OpenAI/Codex (headless systems):"
echo "    # Option 1: Use API key (recommended for headless)"
echo "    export OPENAI_API_KEY=\$(doppler secrets get OPENAI_API_KEY --plain)"
echo ""
echo "    # Option 2: Codex CLI requires browser OAuth (not headless-friendly)"
echo "    # See: https://github.com/openai/codex/issues/3820"
echo "    # Workaround: Authenticate once on GUI machine, copy session token"
echo ""
echo "  For Anthropic/Claude CLI (subscription access):"
echo "    # Use ANTHROPIC_USER + ANTHROPIC_PASSWORD (already exported)"
echo "    # Or fallback: export ANTHROPIC_API_KEY=\$ANTHROPIC_TOKEN"
echo ""
echo "  For Google/Gemini CLI (subscription access):"
echo "    # Use GEMINI_USER + GEMINI_PASSWORD (already exported)"
echo "    # Or fallback: export GOOGLE_API_KEY=\$GEMINI_TOKEN"
echo ""
echo "⚠️  Note: This script exports variables to the current shell."
echo "   To make them permanent, add to your ~/.bashrc or ~/.zshrc:"
echo "   source ./ops/scripts/setup-cli-auth.sh"
echo ""
echo "   Or use 'doppler run --' prefix for one-time commands:"
echo "   doppler run -- python your_script.py"

