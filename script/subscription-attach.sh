#!/bin/bash -eux

# echo '==> Attaching Red Hat subscriptions'
# echo "RHN_USERNAME=$RHN_USERNAME" >> ~/.foo
# echo "RHN_PASSWORD=$RHN_PASSWORD" >> ~/.foo
subscription-manager register --username $RHN_USERNAME --password $RHN_PASSWORD --auto-attach
# echo '==> Subscriptions successfully attached'
# subscription-manager register --username '$RHN_USERNAME'