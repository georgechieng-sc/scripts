#!/bin/sh

# =============================================================================
# Migration Helper Script
# =============================================================================
# This script helps migrate from the monolithic my-script.sh to the modular version

echo "🔄 SafetyCulture Scripts Migration Helper"
echo "=========================================="
echo ""

# Check if zshrc exists and contains the old script
if [[ -f ~/.zshrc ]]; then
    if grep -q "my-script.sh" ~/.zshrc; then
        echo "📝 Found reference to my-script.sh in ~/.zshrc"
        echo "   Current line(s):"
        grep -n "my-script.sh" ~/.zshrc | sed 's/^/   /'
        echo ""
        echo "💡 Suggested replacement:"
        echo "   source ~/Desktop/safetyculture/my-script-modular.sh"
        echo ""
        echo "🤔 Would you like to update ~/.zshrc automatically? [y/n]"
        read -r response
        if [[ $response =~ ^[Yy]$ ]]; then
            # Backup original
            cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
            echo "✅ Created backup: ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
            
            # Replace the line
            sed -i.tmp 's|source.*my-script\.sh|source ~/Desktop/safetyculture/my-script-modular.sh|g' ~/.zshrc
            rm ~/.zshrc.tmp
            echo "✅ Updated ~/.zshrc to use modular scripts"
        else
            echo "ℹ️  Manual update needed - see suggested replacement above"
        fi
    else
        echo "ℹ️  No reference to my-script.sh found in ~/.zshrc"
        echo "💡 To use the modular scripts, add this line to ~/.zshrc:"
        echo "   source ~/Desktop/safetyculture/my-script-modular.sh"
    fi
else
    echo "ℹ️  ~/.zshrc not found"
    echo "💡 To use the modular scripts, create ~/.zshrc with:"
    echo "   source ~/Desktop/safetyculture/my-script-modular.sh"
fi

echo ""
echo "📊 Script comparison:"
echo "   Original: $(wc -l < ~/Desktop/safetyculture/my-script.sh) lines"
echo "   Modular:  $(find ~/Desktop/safetyculture/scripts -name "*.sh" -exec wc -l {} + | tail -n 1 | awk '{print $1}') lines (across $(ls ~/Desktop/safetyculture/scripts/*.sh | wc -l) files)"

echo ""
echo "🧪 Testing modular scripts..."
source ~/Desktop/safetyculture/my-script-modular.sh >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo "✅ Modular scripts load successfully"
    
    # Test a few key functions
    if type select_board >/dev/null 2>&1; then
        echo "✅ select_board function available"
    else
        echo "❌ select_board function missing"
    fi
    
    if type gacp >/dev/null 2>&1; then
        echo "✅ gacp function available"
    else
        echo "❌ gacp function missing"
    fi
    
    if type sync_board >/dev/null 2>&1; then
        echo "✅ sync_board function available"
    else
        echo "❌ sync_board function missing"
    fi
else
    echo "❌ Modular scripts failed to load"
fi

echo ""
echo "📚 Next steps:"
echo "   1. Test the modular scripts: source ~/Desktop/safetyculture/my-script-modular.sh"
echo "   2. Update your ~/.zshrc if not done automatically"
echo "   3. Reload your shell: exec zsh"
echo "   4. Review the README: cat ~/Desktop/safetyculture/README-modular.md"
echo ""
echo "🎉 Migration complete! Your original my-script.sh is preserved for reference."
