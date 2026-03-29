#!/bin/bash
set -Ceuo pipefail

funcMain() {
    funcParseArgs "$@"

    # openssl x509 https://docs.openssl.org/3.3/man1/openssl-x509/
    # -req CSRから証明書を作成する
    # -out 証明書ファイル
    # -in CSRファイル
    # -signkey 秘密鍵ファイル
    # -CA -CAkey 親CAの証明書と秘密鍵ファイル
    # -days 証明書の有効期間
    # -copy_extensions copyall -ext subjectAltName CSRファイルのsubjectAltNameを証明書へコピーする
    # -extfile 証明書の拡張属性のファイル。引数`-extensions`が無いので、デフォルトセクションを設定する。
    # https://docs.openssl.org/3.3/man1/openssl-x509/
    if [ "$gSelfSigned" != 0 ]; then
        echo "[INFO] 自己署名の証明書を生成します。出力ファイル=${gCertFile}"
        local x509ParentCaArgs=(-signkey "$gPrivateKeyFile")
    else
        echo "[INFO] CAで証明書を生成します。出力ファイル=${gCertFile}"
        local x509ParentCaArgs=(-CA "$gParentCaCertFile" -CAkey "$gParentCaPrivateKeyFile")
    fi
    openssl x509 -req -out "$gCertFile" -in "$gReqFile" "${x509ParentCaArgs[@]}" -days "$gCertValidDays" -copy_extensions copyall -ext subjectAltName -extfile "$gExtFile"

    echo "[INFO] 生成した証明書をテキスト形式に変換して出力します。出力ファイル=${gCertTextFile}"
    openssl x509 -text -out "$gCertTextFile" -in "$gCertFile"
}

funcUsage() {
    echo "Usage: ${0##*/} [OPTION]... <certPrefix>"
    exit 0
}

funcParseArgs() {
    gExtFile=/dev/null
    gSelfSigned=0
    while [ $# -ne 0 ]; do
        case "$1" in
        --ca)
            shift
            parentCaPrefix=$1;;
        --self)
            # TODO 入力チェックする
            gSelfSigned=1;;
        --extfile)
            shift
            gExtFile=$1;;
        --help)
            funcUsage;;
        --) # オプション引数の末尾
            shift
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

    local -r certPrefix=$1
    : "${gCertValidDays:=100}"
    gReqFile=${certPrefix}.csr.pem
    gCertFile=${certPrefix}.cert.pem
    gCertTextFile=${gCertFile%.pem}.txt

    if [ -v parentCaPrefix ]; then
        gParentCaPrivateKeyFile=${parentCaPrefix}.key.pem
        gParentCaCertFile=${parentCaPrefix}.cert.pem
    else
        gPrivateKeyFile=${certPrefix}.key.pem
    fi
}

funcMain "$@"
