if [ $# -lt 1 ]; then
  echo "At least one argument needs to be passed, to specify workspace name"
  exit 1
fi

printf "terraform -chdir=infrastructure workspace select -or-create $1\n" >> deploy_$1.sh
printf "if [ $# -eq 1 ] && [ $1 == \"-ci\" ]; then\n" >> deploy_$1.sh
printf "  terraform -chdir=infrastructure apply -auto-approve\n" >> deploy_$1.sh
printf "else\n" >> deploy_$1.sh
printf "  terraform -chdir=infrastructure apply -var-file=environments/$1.tfvars\n" >> deploy-$1.sh
printf "fi\n" >> deploy_$1.sh

cat infrastructure/environments/example.tfvars >> infrastructure/environments/$1.tfvars