#!/bin/bash
set -xe

for i in customer date lineorder part supplier; do
    echo "Loading table $i..."
    echo "COPY $i from '/usr/src/ssb-dbgen/tables/$i.tbl' DELIMITER '|'" | psql -d ssb;
    echo "Loaded!"
done
