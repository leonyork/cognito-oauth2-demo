#!/bin/bash
terraform init -input=false
terraform destroy -auto-approve -input=false

cd user-store-api-secured
npm run destroy