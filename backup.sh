#!/usr/bin/env bash
# backup.sh - Automated Backup System
# Requires: bash, tar, sha256sum (or shasum), df, find, date
# Features: create backups, checksum, verification, rotate, dry-run, locking, logging, list, restore, space check, simulated email

set -euo pipefail

LOCK_FILE="/tmp/backup.lock"
BACKUP_DESTINATION="/mnt/c/Users/hp/Documents/bash_projects/backups"
TMPDIR="/tmp"
LOG_FILE="$BACKUP_DESTINATION/backup.log"
DAILY_KEEP=7
WEEKLY_KEEP=4
MONTHLY_KEEP=3
EMAIL_NOTIFY="spk@gmail.com"
DRY_RUN=0

# ------------- Utility Functions -------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR $*"; rm -f "$LOCK_FILE"; exit 1; }
dry() { [ "$DRY_RUN" -eq 1 ] && { echo "DRY-RUN: $*"; return 0; } || return 1; }
mkdir_p() { [ -d "$1" ] || { dry "Would create $1" && return 0; mkdir -p "$1"; }; }

ensure_lock() {
  if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      die "Another backup is running (pid=$pid)"
    fi
    log "WARN Removing stale lock file"
    rm -f "$LOCK_FILE"
  fi
  echo $$ > "$LOCK_FILE"
}
release_lock() { rm -f "$LOCK_FILE"; }


timestamp() { date +"%Y-%m-%d-%H%M"; }

extract_date_from_name() { echo "$(basename "$1" | sed 's/backup-\(.*\)\.tar\.gz/\1/')"; }

# ------------- Core Backup Logic -------------
create_backup() {
  local src="$1"
  mkdir_p "$BACKUP_DESTINATION"

  # --- Error Handling: Folder not found ---
  if [ ! -d "$src" ]; then
    log "ERROR Source folder not found: $src"
    echo "Error: Source folder not found" >&2
    return 1
  fi

  # --- Error Handling: Permission issue ---
  if [ ! -r "$src" ]; then
    log "ERROR Cannot read folder (permission denied): $src"
    echo "Error: Cannot read folder, permission denied" >&2
    return 1
  fi

  # --- Error Handling: Config file missing (optional) ---
  if [ ! -f "./backup.config" ]; then
    log "WARN Config file missing: Using default settings"
  fi

  # --- Disk Space Check ---
  local avail need src_size
  src_size=$(du -sb "$src" | awk '{print $1}')
  avail=$(df --output=avail -B1 "$BACKUP_DESTINATION" | tail -1)
  need=$((src_size + src_size/5 + 1048576)) # add 20% + 1MB buffer

  if [ "$avail" -lt "$need" ]; then
    log "ERROR Not enough disk space: required=$need available=$avail"
    echo "Error: Not enough disk space for backup" >&2
    return 1
  fi

  # --- Backup Creation ---
  local TS fname fpath chksum_file tmpfile
  TS=$(timestamp)
  fname="backup-${TS}.tar.gz"
  fpath="$BACKUP_DESTINATION/$fname"
  chksum_file="$fpath.sha256"
  tmpfile="${TMPDIR}/${fname}.$$"

  log "Creating backup: $fname"
  dry "Would create backup from $src to $fpath" && return 0

  # --- Trap for Cleanup on Interrupt (Ctrl+C, kill, etc.) ---
  trap 'log "WARN Backup interrupted. Cleaning partial files..."; rm -f "$tmpfile"; release_lock; exit 1' INT TERM

  # --- Perform the backup ---
  if ! tar -czf "$tmpfile" -C "$src" .; then
    log "ERROR Backup failed for $src"
    echo "Error: Backup process failed" >&2
    rm -f "$tmpfile"
    return 1
  fi

  mv "$tmpfile" "$fpath"
  log "SUCCESS Backup created: $fname"

  # --- Checksum creation ---
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$fpath" >"$chksum_file"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$fpath" >"$chksum_file"
  else
    log "ERROR sha256sum or shasum not found"
    echo "Error: No checksum tool found" >&2
    return 1
  fi

  log "Checksum created: $(basename "$chksum_file")"

  # --- Verify backup ---
  if verify_backup "$fpath" "$chksum_file"; then
    log "Verification SUCCESS: $fname"
  else
    log "Verification FAILED: $fname"
  fi

  # --- Rotate old backups ---
  rotate_backups

  # --- Simulated Email Notification ---
  if [ -n "$EMAIL_NOTIFY" ]; then
      local email_file="$BACKUP_DESTINATION/email.txt"
      local status subject message

      if verify_backup "$fpath" "$chksum_file"; then
          status="SUCCESS"
          subject="Backup SUCCESS: $fname"
          message="Backup $fname created successfully and verified."
      else
          status="FAILED"
          subject="Backup FAILED: $fname"
          message="Backup verification failed for $fname."
      fi

      {
          echo "To: $EMAIL_NOTIFY"
          echo "Subject: $subject"
          echo ""
          echo "$message"
          echo "Time: $(date)"
          echo "--------------------------------------------------"
      } >>"$email_file"

      log "Simulated email written to: $email_file"
  fi
}


verify_backup() {
  local archive="$1" chksum="$2"
  dry "Would verify $archive" && return 0
  (cd "$BACKUP_DESTINATION" && sha256sum -c "$(basename "$chksum")" --status) || return 1
}

rotate_backups() {
  log "Cleaning old backups..."

  local dir="$BACKUP_DESTINATION"
  local DAILY_KEEP="${DAILY_KEEP:-7}"
  local WEEKLY_KEEP="${WEEKLY_KEEP:-4}"
  local MONTHLY_KEEP="${MONTHLY_KEEP:-3}"

  # Collect all backups
  mapfile -t backups < <(ls -1 "$dir"/backup-*.tar.gz 2>/dev/null | sort)
  [ ${#backups[@]} -eq 0 ] && { log "No backups found."; return; }

  declare -A keep_daily keep_weekly keep_monthly

  for f in "${backups[@]}"; do
    local base date day week month year
    base=$(basename "$f")
    date=$(echo "$base" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
    [ -z "$date" ] && continue

    year=${date:0:4}
    month=${date:5:2}
    day=${date:8:2}
    week=$(date -d "$date" +%Y-%W 2>/dev/null || date -j -f "%Y-%m-%d" "$date" +%Y-%W)

    keep_daily["$date"]="$f"
    keep_weekly["$week"]="$f"
    keep_monthly["$year-$month"]="$f"
  done

  # Extract sorted keys (reverse chronological)
  mapfile -t daily_keys < <(printf "%s\n" "${!keep_daily[@]}" | sort -r)
  mapfile -t weekly_keys < <(printf "%s\n" "${!keep_weekly[@]}" | sort -r)
  mapfile -t monthly_keys < <(printf "%s\n" "${!keep_monthly[@]}" | sort -r)

  declare -A keep_files

  #  Safely iterate with bounds check
  for ((i=0; i<${#daily_keys[@]} && i<DAILY_KEEP; i++)); do
    keep_files["${keep_daily[${daily_keys[$i]}]}"]=1
  done
  for ((i=0; i<${#weekly_keys[@]} && i<WEEKLY_KEEP; i++)); do
    keep_files["${keep_weekly[${weekly_keys[$i]}]}"]=1
  done
  for ((i=0; i<${#monthly_keys[@]} && i<MONTHLY_KEEP; i++)); do
    keep_files["${keep_monthly[${monthly_keys[$i]}]}"]=1
  done

  # Delete backups not in keep list
  for f in "${backups[@]}"; do
    if [ -z "${keep_files[$f]+exists}" ]; then
      log "Deleted old backup: $(basename "$f")"
      rm -f "$f" "$f.sha256"
    fi
  done

  log "Rotation complete. Kept: ${#keep_files[@]} backups."
}


list_backups() {
  mkdir_p "$BACKUP_DESTINATION"
  echo "Available backups in $BACKUP_DESTINATION:"
  find "$BACKUP_DESTINATION" -maxdepth 1 -type f -name 'backup-*.tar.gz' -printf '%f\t%k KB\n' | sort
}

restore_backup() {
  local file="$1" dest="$2"
  [ -f "$BACKUP_DESTINATION/$file" ] || die "Backup not found: $file"
  mkdir_p "$dest"
  dry "Would restore $file to $dest" && return 0
  tar -xzf "$BACKUP_DESTINATION/$file" -C "$dest"
  log "SUCCESS Restored $file to $dest"
}

# ------------- CLI Handling -------------
if [ $# -lt 1 ]; then
  echo "Usage: $0 [--dry-run|--list|--restore <file> --to <dir>] <source>"
  exit 1
fi

case "$1" in
  --dry-run) DRY_RUN=1; shift; SOURCE="$1";;
  --list) list_backups; exit 0;;
  --restore)
    RESTORE_FILE="$2"; shift 2
    [ "$1" == "--to" ] || die "Use: --restore FILE --to DEST"
    RESTORE_DEST="$2"; ensure_lock; restore_backup "$RESTORE_FILE" "$RESTORE_DEST"; release_lock; exit 0;;
  *) SOURCE="$1";;
esac

ensure_lock
create_backup "$SOURCE"
release_lock
log "INFO Script finished"
