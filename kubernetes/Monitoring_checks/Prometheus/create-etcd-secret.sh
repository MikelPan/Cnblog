cat > create-etcd-secret.sh <<EOF
kubectl -n monitoring create secret generic etcd-certs \
    --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
    --from-file=/etc/kubernetes/pki/etcd/healthcheck-client.key \
    --from-file=/etc/kubernetes/pki/etcd/ca.crt
EOF
