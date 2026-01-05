# DevBox Factory - Temporary Files

This folder is used for temporary files during DevBox Factory operations.

## What Gets Stored Here

- `*.vhdx` - Temporary VHDX files during template creation
- `*.iso` - Mounted ISO working files
- `*.tmp` - General temporary files
- `downloads/` - Temporary download staging area

## Automatic Cleanup

DevBox Factory offers to clean this folder on startup if files are detected.
This helps prevent issues with stale files from previous failed operations.

To manually clean:

```powershell
# Clean all temp files
.\devbox cleanup -Temp

# Or manually
Remove-Item .\temp\* -Recurse -Force -ErrorAction SilentlyContinue
```

## Important Notes

- Files here are **not persistent** - they may be deleted at any time
- Do not store important files in this folder
- If template creation fails, temp VHDX files may remain here
- Running cleanup before retrying a failed operation is recommended

## Git Ignored

All files in this folder (except README.md) are excluded from version control.
