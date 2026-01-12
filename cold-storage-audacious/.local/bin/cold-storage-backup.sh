#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIRS=(
	"/home/alchemist/personal"
	"/home/alchemist/projects"
	"/home/alchemist/Documents"
	"/home/alchemist/Pictures"
	"/home/alchemist/Music"
	"/home/alchemist/Videos"
	"/home/alchemist/dotfiles"
)

COLD_STORAGE_MOUNT="${COLD_STORAGE_MOUNT:-/mnt/cold-storage}"
BASE="${COLD_STORAGE_MOUNT}/backups/audacious"
SNAPSHOT_DATE="$(date +%Y-%m)"
LATEST_DIR="${BASE}/latest"
SNAPSHOT_DIR="${BASE}/snapshots/${SNAPSHOT_DATE}"
KEEP_SNAPSHOTS=12

if [[ ! -d "${COLD_STORAGE_MOUNT}" ]]; then
	echo "cold-storage-backup: ${COLD_STORAGE_MOUNT} is not mounted." >&2
	exit 1
fi

mkdir -p "${LATEST_DIR}" "${SNAPSHOT_DIR}"

existing_sources=()
for path in "${SOURCE_DIRS[@]}"; do
	if [[ -d "${path}" ]]; then
		existing_sources+=("${path}")
	else
		echo "cold-storage-backup: skipping missing directory ${path}" >&2
	fi
done

if ((${#existing_sources[@]} == 0)); then
	echo "cold-storage-backup: no source directories found." >&2
	exit 1
fi

rsync -a --delete --link-dest="${LATEST_DIR}" \
	--exclude 'Downloads/' \
	--exclude '.cache/' \
	--exclude '.local/share/Trash/' \
	--exclude '**/node_modules/' \
	--exclude '**/.venv/' \
	--exclude '**/target/' \
	--exclude '**/__pycache__/' \
	--exclude '**/.mypy_cache/' \
	--exclude '**/.pytest_cache/' \
	"${existing_sources[@]}" \
	"${SNAPSHOT_DIR}/"

rsync -a --delete "${SNAPSHOT_DIR}/" "${LATEST_DIR}/"

mapfile -t snapshots < <(ls -1d "${BASE}/snapshots/"* 2>/dev/null | sort)
snapshot_count="${#snapshots[@]}"
if ((snapshot_count > KEEP_SNAPSHOTS)); then
	remove_count=$((snapshot_count - KEEP_SNAPSHOTS))
	for ((i = 0; i < remove_count; i++)); do
		rm -rf "${snapshots[$i]}"
	done
fi
