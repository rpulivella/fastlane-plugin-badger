# Contributing to fastlane-plugin-badger

## Commit Message Format

- Single line only — multi-line commit messages are not permitted
- Maximum 72 characters total
- Use conventional commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`

Examples:
```
feat: add stamp_corner_banner size parameter
fix: correct font path resolution on CI
docs: update README with icon_glob examples
```

## Pull Request Process

### PR Title Format

- Standard PRs: `feat: Brief description` or `fix: Brief description`
- Use conventional commit prefix in title

### PR Body

Include:
- **Summary**: What changed and why
- **Test plan**: How to verify it works (include a local `bundle exec ruby` test run if visual output is affected)

## Code Style

### File Header Format

All new Ruby files must include a standard header comment:

```ruby
# badger — fastlane-plugin-badger
# <FileName>.rb
#
# Created by Author Name on DD Mon YYYY.
# Copyright © YYYY Author Name. All rights reserved.
```

**Requirements:**
- **Author Name**: Use full name
- **Date Format**: "DD Mon YYYY" (e.g., "09 Mar 2026")
- **Copyright Year**: Current year

### General Guidelines

- Follow existing patterns in the codebase
- All ImageMagick operations go through `BadgerHelper` — actions are thin wrappers only
- Avoid shelling out with string interpolation; always pass args as an array to `system()`
- Temp files must use `SecureRandom.hex(8)` suffixes and be cleaned up in an `ensure` block
- Never require network access — the whole point of this gem is local, offline operation

## Building & Testing

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake spec

# Run a visual smoke test (requires ImageMagick 7+)
bundle exec ruby spec/smoke_test.rb
```

## Architecture

- **`helper/badger_helper.rb`**: All ImageMagick logic — `stamp_text`, `stamp_corner_banner`
- **`actions/`**: Thin Fastlane action wrappers that discover icons and delegate to the helper
- **`assets/fonts/`**: Bundled OFL-licensed fonts — do not replace without verifying license compatibility
