#!/usr/bin/env bash

set -e

REDIS_CLI="redis-cli"

check_redis() {
    if ! command -v ${REDIS_CLI} >/dev/null 2>&1; then
        echo "redis-cli پیدا نشد."
        exit 1
    fi

    if ! ${REDIS_CLI} ping >/dev/null 2>&1; then
        echo "Redis server در حال اجرا نیست."
        echo "اول این را اجرا کن:"
        echo "redis-server --save \"\" --appendonly no"
        exit 1
    fi
}

flush_db() {
    echo "[*] Flushing Redis..."
    ${REDIS_CLI} flushall >/dev/null
}

load_l1() {
    echo "[*] Loading L1-sized dataset ..."
    flush_db

    # حدود 64KB داده خام
    # 4000 کلید * 16 بایت
    for i in $(seq 1 4000); do
        ${REDIS_CLI} set k${i} xxxxxxxxxxxxxxxx >/dev/null
    done

    echo "[+] L1 dataset loaded."
    ${REDIS_CLI} dbsize
    ${REDIS_CLI} info memory | grep used_memory_human
}

load_l2() {
    echo "[*] Loading L2-sized dataset ..."
    flush_db

    # حدود 1.2MB داده خام
    # 80000 کلید * 16 بایت
    for i in $(seq 1 80000); do
        ${REDIS_CLI} set k${i} xxxxxxxxxxxxxxxx >/dev/null
    done

    echo "[+] L2 dataset loaded."
    ${REDIS_CLI} dbsize
    ${REDIS_CLI} info memory | grep used_memory_human
}

load_l3() {
    echo "[*] Loading L3-sized dataset ..."
    flush_db

    # حدود 9.6MB داده خام
    # 150000 کلید * 64 بایت
    for i in $(seq 1 150000); do
        ${REDIS_CLI} set k${i} xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx >/dev/null
    done

    echo "[+] L3 dataset loaded."
    ${REDIS_CLI} dbsize
    ${REDIS_CLI} info memory | grep used_memory_human
}

warmup_l1() {
    echo "[*] Warming up L1 dataset..."
    ${REDIS_CLI} mget k1 k50 k100 k200 k500 k1000 >/dev/null
}

warmup_l2() {
    echo "[*] Warming up L2 dataset..."
    ${REDIS_CLI} mget k1 k500 k10000 k20000 k40000 >/dev/null
}

warmup_l3() {
    echo "[*] Warming up L3 dataset..."
    ${REDIS_CLI} mget k1 k5000 k20000 k80000 k120000 >/dev/null
}

usage() {
    echo "Usage:"
    echo "  $0 l1        # load L1-sized dataset"
    echo "  $0 l2        # load L2-sized dataset"
    echo "  $0 l3        # load L3-sized dataset"
    echo "  $0 warmup-l1 # warmup access pattern for L1"
    echo "  $0 warmup-l2 # warmup access pattern for L2"
    echo "  $0 warmup-l3 # warmup access pattern for L3"
    exit 1
}

main() {
    check_redis

    case "${1:-}" in
        l1)
            load_l1
            ;;
        l2)
            load_l2
            ;;
        l3)
            load_l3
            ;;
        warmup-l1)
            warmup_l1
            ;;
        warmup-l2)
            warmup_l2
            ;;
        warmup-l3)
            warmup_l3
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
