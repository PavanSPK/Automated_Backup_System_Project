
#  Bash Scripting Project: Automated Backup System

## A. Project Overview

**What does this script do?**  
This is an automated backup system written in **Bash**. It creates compressed backups of any folder, generates SHA256 checksums for data integrity, and verifies them automatically.  
It also supports rotation (deleting old backups), dry-run mode, simulated email notifications, and a restore function.

**Why is it useful?**  
Manual backups are time-consuming and error-prone. This script automates the process safely, ensuring old backups are cleaned and new ones are verified.

--------------------------------------------------------------------------------

## B. How to Use It

### 🔧 Installation Steps

1. Clone or copy the `backup.sh` script to your system.
2. Make it executable:
   ```bash
   chmod +x backup.sh
   ```
3. (Optional) Edit the destination folder in the script:
   ```bash
   BACKUP_DESTINATION="/mnt/c/Users/hp/Documents/bash_projects/backups"
   ```


### ▶️ Basic Usage

Backup a folder:
```bash
./backup.sh /path/to/source/folder
```

Dry-run mode (test without creating files):
```bash
./backup.sh --dry-run /path/to/source/folder
```

List existing backups:
```bash
./backup.sh --list
```

Restore a backup:
```bash
./backup.sh --restore backup-2025-11-06-0441.tar --to /path/to/restore
```

### ⚙️ All Command Options

| Option | Description |
|--------|--------------|
| `--dry-run` | Shows what the script *would* do without making changes |
| `--list` | Lists all backups in the destination folder |
| `--restore` | Restores a given backup to a specified folder |

--------------------------------------------------------------------------------

## C. How It Works

### 🔁 Rotation Algorithm
The script keeps a limited number of **daily, weekly, and monthly** backups based on configurable values.  
Example:
- Keep last **7 daily**, **4 weekly**, and **3 monthly** backups.  
Older backups are deleted automatically.

### 🔐 Checksums
Each backup file gets a SHA256 checksum file (e.g. `backup.tar.gz.sha256`) to verify data integrity using:

```bash
sha256sum -c backup.tar.gz.sha256
```

## 📂 Folder Structure Example

```
Bash_Scripting_Project:Automated_Backup_System/
│
├── backup-system/
│   ├──backup.sh               # Main backup automation script
│   ├──backup.config           # Configuration file
│   ├── backup.log             # Log file recording all backup activities
│   ├──README.md               # Markdown file with detailed project explanation
│
├── backups/                   # Stores all generated backup files
│   ├── backup-2025-11-06-0441.tar
│   ├── backup-2025-11-07-0441.tar
│   └── email.txt              # Simulated email notification
│
├── testdata/                  # Folder with test files to back up
│   ├── file1.txt
│   ├── file2.txt
│
├── restored_data/             # Folder where restored backups are extracted
│
├── testfolder/                # Additional folder for testing multi-sourcebackups
│   ├──test.md                 # Markdown file with detailed testing examples

```

-------------------------------------------------------------------------------

## D. Design Decisions

- **Locking**: Prevents multiple script runs at once using `/tmp/backup.lock`.
- **Dry-Run Mode**: Helps safely test the process.
- **Logging**: All actions are logged to `backup.log`.
- **Error Handling**: Handles folder missing, low space, permission errors, and interruptions.
- **Simulated Email**: Writes a summary email to `email.txt` after backup.

**Challenges Faced:**
- Handling edge cases like interrupted backups.
- Managing safe cleanup and old backup deletion.

**Solutions:**
- Used Bash error handling (`set -euo pipefail`).
- Added cleanup and verification after backup creation.

---------------------------------------------------------------------------------

## E. Testing

### Steps Performed:
1. Created test folders and sample files.
2. Executed backup normally.
3. Verified checksum manually.
4. Tested restore and dry-run.
5. Simulated low disk space and missing folders for error handling.

### Example Output:
```
[2025-11-03 11:27:29] Creating backup: backup-2025-11-04-1127.tar.gz
[2025-11-03 11:27:29] SUCCESS Backup created: backup-2025-11-04-1127.tar.gz
[2025-11-03 11:27:29] Checksum created: backup-2025-11-04-1127.tar.gz.sha256
[2025-11-03 11:27:29] Verification SUCCESS: backup-2025-11-04-1127.tar.gz
[2025-11-03 11:27:29] Cleaning old backups...
[2025-11-03 11:27:29] Deleted old backup: backup-2025-11-04-1032.tar.gz
[2025-11-03 11:27:29] Simulated email written to: /mnt/c/Users/hp/Documents/bash_projects/backups/email.txt
[2025-11-04 11:27:29] INFO Script finished
```

-------------------------------------------------------------------------------

## F. Known Limitations

- No real email sending — only simulated.
- Works best on Linux/WSL (Windows CMD/PowerShell may behave differently).
- Rotation is time-based, not size-based.
- Does not support incremental or differential backups (only full).

### Improvements:

- Add real email alerts.
- Support incremental backups.
- Add encryption and cloud upload.
- Improve logs and CLI options.

---------------------------------------------------------------------------

## 👨‍💻 Author

**PavanSPK**  
🔗 GitHub: [@PavanSPK](https://github.com/PavanSPK) 

