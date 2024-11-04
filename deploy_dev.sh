terraform -chdir=infrastructure workspace select -or-create dev
if [ 1 -eq 1 ] && [ dev == "-ci" ]; then
  terraform -chdir=infrastructure apply -auto-approve
else
  terraform -chdir=infrastructure apply -var-file=environments/dev.tfvars
fi
