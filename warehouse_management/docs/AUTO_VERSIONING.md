# Auto-Versioning System

This project uses **automatic version bumping** via git pre-commit hooks. You never need to manually update the version in `pubspec.yaml` - it happens automatically on every commit!

## How It Works

Every time you commit changes to the `warehouse_management` directory:

1. **Git pre-commit hook runs** (`.git/hooks/pre-commit`)
2. **Version is automatically incremented**:
   - Patch version: `+0.0.1` (e.g., 1.1.2 → 1.1.3)
   - Build number: `+1` (e.g., +2 → +3)
3. **Updated `pubspec.yaml` is automatically staged**
4. **Commit proceeds with new version**

## Example

```bash
# Before commit
version: 1.1.2+2

# You make changes and commit
git add .
git commit -m "Add new feature"

# Hook automatically runs:
📦 Auto-bumping version in warehouse_management/pubspec.yaml...
  Current: 1.1.2+2
  New:     1.1.3+3
✅ Version bumped to 1.1.3+3

# After commit
version: 1.1.3+3
```

## Version Format

**Format**: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR** (1.x.x): Breaking changes, major releases
- **MINOR** (x.1.x): New features, backwards compatible
- **PATCH** (x.x.1): Bug fixes, small improvements *(auto-incremented)*
- **BUILD** (+1): Build/release number *(auto-incremented)*

## When Version is NOT Bumped

The hook only increments version when:
- Changes are in the `warehouse_management/` directory
- Changes are being committed (not just staged)

If you commit changes OUTSIDE `warehouse_management/`, the version stays the same.

## Manual Version Control

If you need to manually bump MAJOR or MINOR versions:

1. Edit `pubspec.yaml` directly:
   ```yaml
   version: 2.0.0+1  # Major release
   # or
   version: 1.2.0+1  # Minor release (new features)
   ```

2. Commit the change:
   ```bash
   git add pubspec.yaml
   git commit -m "Release v2.0.0: Major update"
   # Hook will bump to 2.0.1+2
   ```

## Disable Auto-Versioning (if needed)

To temporarily disable:
```bash
git commit --no-verify -m "Your message"
```

To permanently disable:
```bash
# Remove or rename the hook
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
```

## Hook Location

- **Hook file**: `C:\Users\Jahan\Downloads\wavezly\.git\hooks\pre-commit`
- **Project file**: `warehouse_management/pubspec.yaml`

## Benefits

✅ Never forget to bump version
✅ Consistent version increments
✅ Automatic build number tracking
✅ Clean commit history
✅ No manual version management

## Technical Details

The hook uses:
- Bash scripting for portability
- `sed` for version string replacement
- Git staged files detection
- Automatic staging of modified `pubspec.yaml`

---

**Note**: This hook is already set up and working. You don't need to do anything - just commit normally and the version will auto-increment!
