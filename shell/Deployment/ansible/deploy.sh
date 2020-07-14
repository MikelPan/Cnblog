#！/bin/bash

workdir=$(cd $(dirname $0); pwd)
case $3 in
    plan)
    ansible-playbook -i $workdir/inventory/$2.yml $workdir/playbook/deploy.yml --tags=$1 -vvvv --syntax-check
    ;;
    apply)
    ansible-playbook -i $workdir/inventory/$2.yml $workdir/playbook/deploy.yml --tags=$1
    ;;
    *)
    exit 0
esac