#!/bin/bash
. "$(dirname $0)"/../../scripts/export-director-metadata


echo $OPSMAN_KEY  | sed -e 's/\(KEY-----\)\s/\1\n/g; s/\s\(-----END\)/\n\1/g' | sed -e '2s/\s\+/\n/g' > ~/ssh_access.pem
chmod 600 ~/ssh_access.pem
ssh-agent > ~/agent
eval $(ssh-agent -s)
ssh-add ~/ssh_access.pem


#login to opsman
ssh -i ~/ssh_access.pem -o "StrictHostKeyChecking no"  "${OPSMAN_USER_EC2}"@"${OPSMAN_IP}" <<EOF
cd /var/tempest/workspaces/default/
sudo bosh2 alias-env sst-director -e ${BOSH_ADDRESS} --ca-cert root_ca_certificate
BOSH_CLIENT=${BOSH_CLIENT} BOSH_CLIENT_SECRET=${BOSH_CLIENT_SECRET} bosh2 -e sst-director --ca-cert /var/tempest/workspaces/default/root_ca_certificate login
sudo bosh2 -e sst-director vms
EOF

pwd
cd ../../../director-backup-bucket
ls -al

## extract the s3 bucket contents
cd ../../../director-backup-bucket
cp -r director-*.tar ../binary/
cd ../binary/
tar -xvf director-*.tar

## the restoration of bosh director
./bbr director --private-key-path <(echo "${BBR_PRIVATE_KEY}") --username bbr --host "${BOSH_ADDRESS}" restore --artifact-path 10.0.*


