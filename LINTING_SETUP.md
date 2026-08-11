# Linting Setup Guide

This project uses professional-grade linters for both the React frontend and Rails backend to ensure code quality, best practices, security, and performance.

## Frontend Linting (React/JavaScript - ESLint)

### Installation
ESLint is already configured in the frontend. Install dependencies:
```bash
cd calrizzler-frontend
npm install
```

### Running Linter

**Check for issues:**
```bash
npm run lint
```

**Auto-fix issues:**
```bash
npm run lint:fix
```

**Generate HTML report:**
```bash
npm run lint:report
# Opens lint-report.html in your browser
```

### What It Checks
- **Code Style**: Formatting, naming conventions, quote styles
- **Best Practices**: Unused variables, const/let over var, template literals
- **Security**: No eval, no script URLs, no implied eval
- **Performance**: Unreachable loops, constant conditions
- **React**: Hook rules, refresh-only components

### Configuration
See `calrizzler-frontend/eslint.config.js`

---

## Backend Linting (Rails/Ruby - Rubocop)

### Installation
First, install Rubocop and related gems:
```bash
bundle install
```

This installs:
- **rubocop**: Core linting engine
- **rubocop-rails**: Rails-specific rules
- **rubocop-performance**: Performance optimization rules
- **rubocop-security**: Security vulnerability detection
- **rubocop-rspec**: RSpec best practices

### Running Linter

**Check for issues:**
```bash
rubocop
```

**Check specific files/directories:**
```bash
rubocop app/models/user.rb
rubocop app/controllers/
rubocop spec/
```

**Auto-fix issues:**
```bash
rubocop -a
# or for safer corrections only:
rubocop -A
```

**Generate detailed report:**
```bash
rubocop --format html --output rubocop-report.html
```

**Check only new changes (if using git):**
```bash
rubocop --staged
```

### What It Checks
- **Code Style**: Naming conventions, string literals, indentation
- **Best Practices**: Method length, class length, cyclomatic complexity
- **Security**: Open(), eval(), YAML/JSON/Marshal loads
- **Performance**: FlatMap, redundant merges, string operations
- **Rails**: ActiveRecord patterns, migrations, callbacks, HTTP methods
- **RSpec**: Test structure, doubles, expectations

### Configuration
See `.rubocop.yml`

### Ignoring Issues
To ignore a rule for a specific line:
```ruby
# rubocop:disable Rails/HasManyOrHasOneDependent
has_many :items  # Will be ignored
# rubocop:enable Rails/HasManyOrHasOneDependent
```

Or for a block:
```ruby
# rubocop:disable Style/MethodLength
def long_method
  # ...
end
# rubocop:enable Style/MethodLength
```

---

## Integration with Development Workflow

### Pre-Commit Hooks (Optional)
You can set up git hooks to lint before committing:
```bash
# Install husky (if using Node.js ecosystem)
npm install husky --save-dev
npx husky install
npx husky add .husky/pre-commit "npm run lint && rubocop"
```

### CI/CD Integration
Add linting to your CI pipeline:

**GitHub Actions example:**
```yaml
- name: Run ESLint
  run: cd calrizzler-frontend && npm run lint

- name: Run Rubocop
  run: bundle exec rubocop
```

### IDE Integration
Both ESLint and Rubocop extensions are available for VS Code:
- **ESLint**: `dbaeumer.vscode-eslint`
- **Rubocop**: `misogi.ruby-rubocop`

Install and restart VS Code to see linting errors inline.

---

## Common Issues & Solutions

### ESLint
- **Port already in use**: Change Vite dev server port in `vite.config.js`
- **Module not found**: Run `npm install`
- **Rule conflicts**: Check `.eslintignore` and `eslint.config.js`

### Rubocop
- **Gem install fails**: Try `bundle update rubocop`
- **Too many violations**: Run `rubocop -a` to auto-fix, then review changes
- **Custom rules needed**: Update `.rubocop.yml`

---

## Customizing Rules

### For Frontend (ESLint)
Edit `calrizzler-frontend/eslint.config.js` in the `rules` section.

### For Backend (Rubocop)
Edit `.rubocop.yml` to enable/disable cops or adjust parameters.

To see all available cops:
```bash
rubocop --show-cops
```

---

## Running All Linters

Create a convenient command to run all linters:

**Frontend + Backend:**
```bash
# Frontend
cd calrizzler-frontend && npm run lint

# Backend
cd .. && bundle exec rubocop

# With auto-fix:
cd calrizzler-frontend && npm run lint:fix
cd .. && bundle exec rubocop -A
```

Or create a simple shell script:
```bash
#!/bin/bash
echo "=== Linting Frontend ==="
cd calrizzler-frontend && npm run lint
cd ..

echo -e "\n=== Linting Backend ==="
bundle exec rubocop
```

Save as `lint-all.sh` and run with `bash lint-all.sh`
