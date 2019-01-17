#! /usr/bin/env bash

# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# "---------------------------------------------------------"
# "-                                                       -"
# "-  Creates cluster and deploys demo application         -"
# "-                                                       -"
# "---------------------------------------------------------"
echo '################## CREATE SCRIPT ##################'
set -o errexit
set -o nounset
set -o pipefail
set -xv 

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
# shellcheck source=scripts/common.sh
source "$ROOT/scripts/common.sh"

# Generate the variables to be used by Terraform
# shellcheck source=scripts/generate-tfvars.sh
source "$ROOT/scripts/generate-tfvars.sh"

# Enable required GCP APIs
gcloud services enable container.googleapis.com dns.googleapis.com

# Create certificate for the DNS entry using Certificate manager
echo "1. Creating certificate for the DNS entry using Certificate Manager"
gcloud beta compute ssl-certificates create ${CLUSTER_NAME} --domains ${CLUSTER_NAME}.${DOMAIN}

echo "2. Building out environment"

# Initialize and run Terraform
(cd "$ROOT/terraform"; terraform init -input=false)
(cd "$ROOT/terraform"; terraform apply -input=false -auto-approve)

# Generate kubeconfig entry for newly generated certificate
echo "3. Generating Kubeconfig entry for the certificate"
# workaround for region issue. Region specified in your service account is not always the same for the certificate.  
certificate_region=$(gcloud container clusters list | grep $CLUSTER_NAME | awk '{print $2}')
# Get actual region for cluster entrypoint. This is where the certificate lives regardless of your region/zone settings.  
gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${certificate_region}  --project ${PROJECT}

# Verify the secrets were generated
echo "4. Checking the Configuration"
echo "4a. Verifying the secrets"
kubectl get secret

# echo "4b. Checking credentials"
# kubectl get crd
# 12/20/2018 - Throwing  error: the server doesn't have a resource type "crd"
