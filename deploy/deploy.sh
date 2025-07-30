#!/bin/bash
REMOTE_DIR=$1
BACKUP_DIR="${REMOTE_DIR}_backup"

echo "Backing up old version..."
rm -rf $BACKUP_DIR
mv $REMOTE_DIR $BACKUP_DIR 2>/dev/null || true

echo "Deploying new version..."
mv /tmp/build $REMOTE_DIR
