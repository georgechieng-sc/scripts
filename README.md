# Development Scripts - Modular Structure

This directory contains a modular version of the development scripts, broken down into logical components for better maintainability and organization.

## 📁 Structure

```
/scripts/
├── my-script-modular.sh    # Main loader script
├── my-script.sh            # Original monolithic script (preserved)
├── constants.sh            # Constants and color codes
├── aliases.sh              # All shell aliases
├── installation.sh         # Installation and setup functions
├── utilities.sh            # Core utility functions
├── git.sh                  # Git workflow functions
├── jira.sh                 # JIRA integration functions
├── repository.sh           # Repository management
├── pr-review.sh            # PR review workflow
└── specialized.sh          # Specialized utility functions
```

## 🚀 Usage

### Load All Modules
```bash
source {$HOME}/scripts/my-script-modular.sh
```

### Load Individual Modules
```bash
# Load only git functions
source {$HOME}/scripts/constants.sh
source {$HOME}/scripts/utilities.sh
source {$HOME}/scripts/git.sh

# Load only JIRA functions
source {$HOME}/scripts/constants.sh
source {$HOME}/scripts/utilities.sh
source {$HOME}/scripts/jira.sh
```

## 📋 Module Descriptions

### `constants.sh`
- **Purpose**: Core constants and ANSI color codes
- **Dependencies**: None
- **Contains**: 
  - Directory paths (SAFETYCULTURE_DIR, PROMPTS_DIR)
  - Color codes for terminal output

### `aliases.sh`
- **Purpose**: All shell aliases for quick commands
- **Dependencies**: None
- **Contains**: 
  - General aliases (reload, hammer, etc.)
  - Docker aliases (docking, dkc, etc.)
  - Git aliases (gpod, gplink, etc.)

### `installation.sh`
- **Purpose**: System setup and installation functions
- **Dependencies**: None
- **Contains**: 
  - Homebrew installation
  - Oh My Zsh setup
  - Development dependencies
  - Kubernetes configuration
  - NVM functions

### `utilities.sh`
- **Purpose**: Core utility functions used across modules
- **Dependencies**: constants.sh
- **Contains**: 
  - yesno() - User input validation
  - select_board() - Board selection interface
  - tpa() - Auto-teleport function
  - cleanpipe() - Port cleanup
  - giffy() - Video to GIF conversion
  - Directory navigation helpers

### `git.sh`
- **Purpose**: Git workflow automation
- **Dependencies**: constants.sh, utilities.sh
- **Contains**: 
  - branch() - Branch creation workflow
  - pr() - Pull request creation with AI
  - gacp() - Add, commit, push with AI
  - gbdi() - Interactive branch deletion

### `jira.sh`
- **Purpose**: JIRA integration and ticket management
- **Dependencies**: constants.sh, utilities.sh
- **Contains**: 
  - sync_board() - Dynamic board syncing
  - jbr() - Branch creation from JIRA tickets
  - mvj() - Ticket status management
  - jdiff() - AI-powered ticket creation
  - Legacy wrappers (resm)

### `repository.sh`
- **Purpose**: Repository management functions
- **Dependencies**: constants.sh
- **Contains**: 
  - repo() - Repository list syncing
  - grc() - Interactive repository cloning

### `pr-review.sh`
- **Purpose**: Pull request review workflow
- **Dependencies**: constants.sh, utilities.sh
- **Contains**: 
  - stamp() - Quick PR approval
  - prd() - PR diff viewing
  - rr() - Review and approve workflow
  - review() - AI-powered PR analysis

### `specialized.sh`
- **Purpose**: Specialized utility functions
- **Dependencies**: constants.sh
- **Contains**: 
  - s12id() / ids12() - ID format conversion
  - pw() - Password generation
  - auto-sql() - SQL migration file creation

## 🔄 Migration Guide

### From Monolithic to Modular

1. **Replace your current sourcing**:
   ```bash
   # Old way
   source ${HOME}$/scripts/my-script.sh
   
   # New way
   source ${HOME}$/scripts/my-script-modular.sh
   ```

2. **Update your .zshrc**:
   ```bash
   # Add to ~/.zshrc
   source ${HOME}$/scripts/my-script-modular.sh
   ```

3. **Selective loading** (optional):
   ```bash
   # Load only what you need
   source ${HOME}$/scripts/constants.sh
   source ${HOME}$/scripts/git.sh
   source ${HOME}$/scripts/jira.sh
   ```

## 🛠 Development

### Adding New Functions

1. **Identify the appropriate module** based on function purpose
2. **Add dependencies** if the function uses other modules
3. **Update this README** with new function descriptions
4. **Test the function** in isolation and with the full loader

### Creating New Modules

1. **Create new .sh file** in the same directory
2. **Add proper header** with module description
3. **Update the loader** (`my-script-modular.sh`) to include the new module
4. **Document dependencies** and update this README

## 📝 Notes

- **Dependency Order**: The loader script loads modules in dependency order
- **Backward Compatibility**: All functions maintain the same interface as the monolithic version
- **Performance**: Modular loading allows for faster startup when loading only needed modules
- **Maintenance**: Each module can be updated independently
- **Testing**: Individual modules can be tested in isolation

## 🔍 Troubleshooting

### Module Loading Issues
```bash
# Check if a specific module loads correctly
source ${HOME}$/scripts/utilities.sh
echo $?  # Should return 0 if successful
```

### Function Not Found
```bash
# Check which modules define a function
grep -r "function_name" ${HOME}$/scripts/
```

### Dependencies Missing
```bash
# Ensure constants are loaded first
source ${HOME}$/scripts/constants.sh
# Then load the module that depends on constants
source ${HOME}$/scripts/utilities.sh
```
