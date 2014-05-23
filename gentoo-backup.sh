#!/bin/bash

set -e

CTID="${1}"
CTCONF="/etc/vz/conf/${CTID}.conf"
if [[ ! -f "${CTCONF}" ]]; then
	echo "No valid VM provided"
	exit 1
fi

source "${CTCONF}"

vzctl mount "${CTID}"

tar \
	--numeric-owner \
	--create \
	--verbose \
	--gzip \
	--exclude='./usr/portage/*' \
	--file "/vz/backup/${HOSTNAME:-unnamed}-$(date -u +%s).tar.gz" \
	--directory "/vz/root/${CTID}/" \
	.
