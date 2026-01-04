# ISO Files

Place your Windows ISO files in this folder for use with DevBox Factory VM templates.

## Supported ISOs

| OS | Filename Example | Download |
|----|------------------|----------|
| **Windows 11 23H2/24H2** | `Win11_24H2_English_x64.iso` | [Microsoft](https://www.microsoft.com/software-download/windows11) |
| **Windows Server 2025** | `SERVER_EVAL_x64FRE_en-us.iso` | [Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025) |

## Usage

After placing your ISO here, create a template:

```powershell
.\devbox template -ISOPath ".\iso\Win11_24H2_English_x64.iso"
```

Or use the interactive menu which will detect ISOs in this folder:

```powershell
.\devbox template
```

## Notes

- ISO files are excluded from git (see `.gitignore`)
- Minimum 5GB free space required for each ISO
- Only 64-bit (x64) ISOs are supported
