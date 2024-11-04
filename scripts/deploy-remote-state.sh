if [ $# -lt 1 ]; then
  echo "At least one argument needs to be passed, to specify project name"
  exit 1
fi

export region = 'us-east-1'
if [ $# -ge 2 ]; then
  export region = $2

terraform -chdir=remote-state init
terraform -chdir=remote-state apply -var 'project=$1' -var 'region=$2'