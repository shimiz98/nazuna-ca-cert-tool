#!/bin/bash
set -Ceuo pipefail

funcMain() {
    funcParseArgs "$@"

    echo "[INFO] 公開鍵暗号方式の鍵を生成します。出力ファイル=${gPrivateKeyFile}"
    # openssl genpkey https://docs.openssl.org/3.3/man1/openssl-genpkey/
    # -algorithm
    # -pkeyopt
    # -quiet Do not output "status dots" while generating keys.
    openssl genpkey -out "$gPrivateKeyFile" -algorithm "$gPkeyAlgorithm" -pkeyopt "$gPkeyOpt" -quiet

    if [ -v gOptInsecure ]; then
        echo "[INFO] 生成した秘密鍵と公開鍵をテキスト形式に変換して出力します。出力ファイル=${gPrivateKeyTextFile}"
        openssl pkey -text -out "$gPrivateKeyTextFile" -in "$gPrivateKeyFile"
    fi
}
funcUsage() {
    echo "Usage: ${0##*/} [OPTION]... <certPrefix>"
    exit 0
}

funcParseArgs() {
    while [ $# -ne 0 ]; do
        case "$1" in
        --insecure)
            gOptInsecure='';;
        --help)
            funcUsage;;
        --) # オプション引数の末尾
            shift # この引数`--`をshiftで捨ててからbreakする
            break;;
        -*) # 不明なオプション引数
            echo "[ERROR] Unkown Option: ${1}" 1>&2
            exit 1;;
        *)  # その他の引数
            break;;
        esac
        shift
    done

    local -r expectedArgCount=1
    if [ $# -ne "$expectedArgCount" ]; then
        echo "[ERROR] 引数の個数が異なります。期待値=${expectedArgCount} 実際の個数=$#"
        exit 1
    fi

    : "${gPkeyAlgorithm:=RSA}"
    : "${gPkeyOpt:=rsa_keygen_bits:2048}"
    gPrivateKeyFile=${1}.key.pem
    gPrivateKeyTextFile=${gPrivateKeyFile%.pem}.txt
}

funcMain "$@"
