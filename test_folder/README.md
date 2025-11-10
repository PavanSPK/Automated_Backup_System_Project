# Backup System Testing Guide

This document demonstrates how to test all major features of **backup.sh** script.

--------------------------------------------------------------------------------

##  1. Creating a Backup

Run the backup script:
```bash
./backup.sh /mnt/c/Users/hp/Documents/bash_projects/testdata
```

Expected output:

![backup](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/backup.png)


-----------------------------------------------------------------------------------

##  2. Creating Multiple Backups Over “Days”

To simulate multiple days:

![multie_backup](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/multie_backup.png)

List backups:

![list_backup](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/list_backup.png)

----------------------------------------------------------------------------------

##  3. Automatic Deletion of Old Backups

Edit `.backup.conf`:
```bash
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
```

Then run again:
```bash
./backup.sh /mnt/c/Users/hp/Documents/bash_projects/testdata
```

Expected output:

![autodelete_old_backup](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/autodelete_old_backup.png)

--------------------------------------------------------------------------------
##  4. Restoring From a Backup

Expected:

![restore_backup](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/restore_backup.png)

![restored_data](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/restored_data.png)

##  5. Dry Run Mode

```bash
./backup.sh --dry-run /mnt/c/Users/hp/Documents/bash_projects/testdata
```

Expected:

![dry_run](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/dry_run.png)

-----------------------------------------------------------------------------------------
##  6. Email

Expected:

![email](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/b6d19ead1541d86128d56d98c9d3d261225f21db/test_folder/email.png)

-------------------------------------------------------------------------------------------

##  7. Error Handling Test

Try backing up a non-existing folder:
```bash
./backup.sh /mnt/c/Users/hp/Documents/bash_projects/folder1
```

Expected:

![folder_not_found](https://github.com/PavanSPK/Automated_Backup_System_Project/blob/main/test_folder/folder_not_found.png)

-------------------------------------------------------------------------------

##  Folder Structure Example

```
bash_Project/
├── backup.sh                  # Main backup automation script
├── backup.config              # Configuration file (optional, for retention settings)
├── backup.log                 # Log file recording all backup activities
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
├── testfolder/                # Additional folder for testing multi-source backups
│   ├──test.md                 # Markdown file with detailed testing examples

```
-----------------------------------------------------------------------------------

##  Summary of Tests

| Feature | Verified | Screenshot Added |
|----------|-----------|------------------|
| Backup Creation | Done | Done |
| Multiple Backups | Done | Done |
| Deletion of Old | Done | Done |
| Restore | Done | Done |
| Dry Run | Done | Done |
| Email | Done | Done |
| Error Handling | Done | Done |

------------------------------------------------------------------------------

##  Author

**PavanSPK**  
 GitHub: [@PavanSPK](https://github.com/PavanSPK)
