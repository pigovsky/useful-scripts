#!/bin/bash

MY_IP_ADDRESS="$(hostname -I)"
PLATFORM_BIN_DISTRIB="seqam-bin-v0.30.0-20250515.tgz"
PLATFROM_FOLDER="seqam"

cd "$PLATFROM_FOLDER" || exit $?
tar zxvf "$PLATFORM_BIN_DISTRIB" || exit $?
./scripts/install-docker.sh || exit $?

cd || exit $?
git clone https://github.com/SigNoz/signoz.git || exit $?
cd signoz || exit $?
git apply ../"$PLATFROM_FOLDER"/apply-me-on-new-signoz.diff || exit $?
cd deploy/docker || exit $?
docker compose up -d || exit $?

cd || exit $?
cd "$PLATFROM_FOLDER" || exit $?
./api/bin/install.sh || exit $?
sed -i -e "s/PLEASE_CHANGE_ME/${MY_IP_ADDRESS}/g" ~/.seqam_fh_dortmund_project_emulate/env || exit $?
cd bare-composes || exit $?
./generate-docker-composes.sh || exit $?
cd seqam-central || exit $?
docker compose up -d || exit $?
