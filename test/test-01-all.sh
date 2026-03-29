#!/bin/bash
set -Ceuo pipefail

sh ./script/step1-create-key.sh a1
sh ./script/step1-create-key.sh a2
sh ./script/step1-create-key.sh a3
sh ./script/step1-create-key.sh a4

sh ./script/step2-create-req.sh --no-san a1 'a1 root CA'
sh ./script/step2-create-req.sh --no-san a2 'a2 intermediate CA'
sh ./script/step2-create-req.sh a3 'example.com' a@example.com 192.168.0.1 ::1 git+ssh://host/path foo-bar.baz://something
sh ./script/step2-create-req.sh a4 a@example.com

sh ./script/step3-create-cert.sh --extfile cert-extfile/openssl-conf-ca.txt --self a1
sh ./script/step3-create-cert.sh --extfile cert-extfile/openssl-conf-ca.txt --ca a1 a2
sh ./script/step3-create-cert.sh --extfile cert-extfile/openssl-conf-serverAuth.txt --ca a2 a3
sh ./script/step3-create-cert.sh --extfile cert-extfile/openssl-conf-clientAuth.txt --ca a2 a4
