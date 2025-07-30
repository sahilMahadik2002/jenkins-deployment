#!/bin/bash
REMOTE_DIR=$1
BACKUP_DIR="${REMOTE_DIR}_backup"

echo "Rolling back..."
rm -rf $REMOTE_DIR
mv $BACKUP_DIR $REMOTE_DIR
