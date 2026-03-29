#!/bin/bash
set -Ceuo pipefail

funcMain() {
    funcParseArgs "$@"

    echo "[INFO] 証明書への署名要求(CSR)を生成します。出力ファイル=${gReqFile}"
    # openssl req https://docs.openssl.org/3.3/man1/openssl-req/
    # -new CSRを作成する
    # -out CSRファイル
    # -key 秘密鍵ファイル
    # -subj subject名
    # -addext subjectAltName=... subjectの別名
    export MSYS_NO_PATHCONV=1 # `/CN=` が `C:/Program Files/Git/CN=`に誤変換されるのを防止するために設定する。
    openssl req -new -out "$gReqFile" -key "$gPrivateKeyFile" -subj "$gReqSubject" "${gSubjectAltNameArgs[@]}"

    echo "[INFO] 生成した証明書署名要求(CSR)をテキスト形式に変換して出力します。出力ファイル=${gReqTextFile}"
    openssl req -text -out "$gReqTextFile" -in "$gReqFile"
}

funcUsage() {
    echo "Usage: ${0##*/} [OPTION]... <certPrefix> <commonName> [subjectAltName]..."
    exit 0
}

funcParseArgs() {
    local withoutSubjectAltName=0
    while [ $# -ne 0 ]; do
        case "$1" in
        --no-san)
            withoutSubjectAltName=1;;
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

    local -r expectedArgCount=2
    if [ $# -lt "$expectedArgCount" ]; then
        echo "[ERROR] 引数の個数が異なります。期待値=${expectedArgCount}以上 実際の個数=$#"
        exit 1
    elif [ $# -ne "$expectedArgCount" ] && [ "$withoutSubjectAltName" != 0 ]; then
        echo "[ERROR] --no-san が指定されたため、引数の個数は${expectedArgCount}個です。実際の個数=$#"
        exit 1
    fi
    local -r certPrefix=$1
    local -r commonName=$2
    gPrivateKeyFile=${certPrefix}.key.pem
    gReqFile=${certPrefix}.csr.pem
    gReqTextFile=${gReqFile%.pem}.txt
    gReqSubject="/CN=${commonName}"

    if [ "$withoutSubjectAltName" != 0 ]; then
        gSubjectAltNameArgs=()
        return
    fi

    # subjectAltName の指定を生成
    local subjectAltNameIndex=1
    local subjectAltNameList=''
    shift
    while [ $# -ne 0 ]; do
        local subjectAltName=$1
        if [[ "$subjectAltName" =~ .*@.* ]]; then
            local subjectAltNameType=email
        elif [[ "$subjectAltName" =~ [0-9]*\.[0-9]*\.[0-9]*\.[0-9]* ]]; then
            # IPv4アドレス。この正規表現は緩いので、IPv4以外がヒットする場合ある。
            local subjectAltNameType=IP
        elif [[ "$subjectAltName" =~ [0-9A-Fa-f]*:[0-9A-Fa-f:]*:[0-9A-Fa-f:]* ]]; then
            # IPv6アドレス。この正規表現は緩いので、IPv6以外がヒットする場合ある。
            local subjectAltNameType=IP
        elif [[ "$subjectAltName" =~ [A-Za-z][-0-9A-Za-z+.]:.* ]]; then
            # URI。この正規表現は緩いので、URI以外がヒットする場合ある。
            local subjectAltNameType=URI
        else
            # DNS。DNS以外もヒットするが、とりあえずDNSに設定する。
            local subjectAltNameType=DNS
        fi
        subjectAltNameList="${subjectAltNameList},${subjectAltNameType}.$((subjectAltNameIndex++)):${subjectAltName}"
        shift
    done
    # MEMO 先頭の余計なカンマは削除する
    gSubjectAltNameArgs=(-addext "subjectAltName=${subjectAltNameList#,}")
}

funcMain "$@"
