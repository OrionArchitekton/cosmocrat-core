#!/usr/bin/env bash
set -euo pipefail

echo "🤖 Deploying LLM Models (Codex, Claude, Gemini)"
echo "================================================"
echo ""

# Check if Ollama is running
if ! docker ps | grep -q ollama; then
    echo "❌ Error: Ollama container is not running"
    echo "   Start it with: doppler run -- docker compose up -d ollama"
    exit 1
fi

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
for i in {1..60}; do
    if curl -fsS http://localhost:11434/api/tags &> /dev/null; then
        echo "✓ Ollama is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "❌ Ollama timeout"
        exit 1
    fi
    sleep 2
    echo -n "."
done
echo ""

# Function to check for subscription/user credentials
check_auth_credentials() {
    local service=$1
    local user_var=$2
    local pass_var=$3
    local token_var=$4
    
    echo -n "Checking ${service} authentication... "
    
    # Prioritize user/password (subscription-based access)
    if doppler secrets get "${user_var}" --plain &> /dev/null && \
       doppler secrets get "${pass_var}" --plain &> /dev/null; then
        echo "✓ User credentials configured (${user_var}/${pass_var}) - Subscription access"
        return 0
    fi
    
    # Fallback to token if no user/password
    if doppler secrets get "${token_var}" --plain &> /dev/null; then
        echo "✓ Token configured (${token_var})"
        return 0
    fi
    
    echo "✗ Not configured"
    return 1
}

echo "🔑 Checking authentication tokens/credentials..."
echo ""

OPENAI_AUTH_SET=false
ANTHROPIC_AUTH_SET=false
GEMINI_AUTH_SET=false

# OpenAI/Codex - prioritize user/password (subscription access)
if check_auth_credentials "OpenAI/Codex" "OPENAI_USER" "OPENAI_PASSWORD" "OPENAI_TOKEN"; then
    OPENAI_AUTH_SET=true
elif check_auth_credentials "OpenAI/Codex" "CODEX_USER" "CODEX_PASSWORD" "CODEX_TOKEN"; then
    OPENAI_AUTH_SET=true
elif check_auth_credentials "OpenAI/Codex" "OPENAI_USERNAME" "OPENAI_PASSWORD" "OPENAI_ACCESS_TOKEN"; then
    OPENAI_AUTH_SET=true
fi

# Anthropic/Claude - prioritize user/password (subscription access)
if check_auth_credentials "Anthropic/Claude" "ANTHROPIC_USER" "ANTHROPIC_PASSWORD" "ANTHROPIC_TOKEN"; then
    ANTHROPIC_AUTH_SET=true
elif check_auth_credentials "Anthropic/Claude" "CLAUDE_USER" "CLAUDE_PASSWORD" "CLAUDE_TOKEN"; then
    ANTHROPIC_AUTH_SET=true
elif check_auth_credentials "Anthropic/Claude" "ANTHROPIC_USERNAME" "ANTHROPIC_PASSWORD" "ANTHROPIC_ACCESS_TOKEN"; then
    ANTHROPIC_AUTH_SET=true
fi

# Google/Gemini - prioritize user/password (subscription access)
if check_auth_credentials "Google/Gemini" "GEMINI_USER" "GEMINI_PASSWORD" "GEMINI_TOKEN"; then
    GEMINI_AUTH_SET=true
elif check_auth_credentials "Google/Gemini" "GOOGLE_USER" "GOOGLE_PASSWORD" "GOOGLE_TOKEN"; then
    GEMINI_AUTH_SET=true
elif check_auth_credentials "Google/Gemini" "GEMINI_USERNAME" "GEMINI_PASSWORD" "GEMINI_ACCESS_TOKEN"; then
    GEMINI_AUTH_SET=true
fi

echo ""
echo "📥 Model authentication status:"
echo ""

# Codex (OpenAI) - subscription-based user credentials
if [ "$OPENAI_AUTH_SET" = true ]; then
    echo "✓ Codex/OpenAI: Authentication configured - ready to use"
else
    echo "⚠ Codex/OpenAI: No authentication found"
    echo "   Configure subscription credentials in Doppler:"
    echo "   - OPENAI_USER + OPENAI_PASSWORD (subscription login - recommended)"
    echo "   - CODEX_USER + CODEX_PASSWORD (alternative)"
    echo "   - OPENAI_TOKEN (fallback token-based)"
fi

# Claude (Anthropic) - subscription-based user credentials
if [ "$ANTHROPIC_AUTH_SET" = true ]; then
    echo "✓ Claude: Authentication configured - ready to use"
else
    echo "⚠ Claude: No authentication found"
    echo "   Configure subscription credentials in Doppler:"
    echo "   - ANTHROPIC_USER + ANTHROPIC_PASSWORD (subscription login - recommended)"
    echo "   - CLAUDE_USER + CLAUDE_PASSWORD (alternative)"
    echo "   - ANTHROPIC_TOKEN (fallback token-based)"
fi

# Gemini (Google) - subscription-based user credentials
if [ "$GEMINI_AUTH_SET" = true ]; then
    echo "✓ Gemini: Authentication configured - ready to use"
else
    echo "⚠ Gemini: No authentication found"
    echo "   Configure subscription credentials in Doppler:"
    echo "   - GEMINI_USER + GEMINI_PASSWORD (subscription login - recommended)"
    echo "   - GOOGLE_USER + GOOGLE_PASSWORD (alternative)"
    echo "   - GEMINI_TOKEN (fallback token-based)"
fi

echo ""
echo "📋 Available Ollama models (local fallback):"
docker exec ollama ollama list 2>/dev/null || echo "  (none yet - pull models manually)"

echo ""
echo "✅ Model deployment check complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Configure subscription credentials in Doppler (Ultra/Pro subscriptions):"
echo ""
echo "      For Subscription Access (recommended):"
echo "      - OPENAI_USER + OPENAI_PASSWORD (Codex/OpenAI)"
echo "      - ANTHROPIC_USER + ANTHROPIC_PASSWORD (Claude)"
echo "      - GEMINI_USER + GEMINI_PASSWORD (Gemini)"
echo ""
echo "      Alternative names:"
echo "      - CODEX_USER + CODEX_PASSWORD"
echo "      - CLAUDE_USER + CLAUDE_PASSWORD"
echo "      - GOOGLE_USER + GOOGLE_PASSWORD"
echo ""
echo "   2. Your services will automatically use these credentials"
echo "   3. Verify models are accessible by your services"
