kubectl delete secret traefik-secret -n kube-system
kubectl create secret generic traefik-secret --from-file=/root/.ssl/aliyun_access_key --from-file=/root/.ssl/aliyun_secret_key -n kube-system
