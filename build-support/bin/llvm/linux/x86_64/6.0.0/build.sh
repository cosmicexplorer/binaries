#!/bin/bash

yum -y install xz

readonly result="$(./build-llvm.sh linux 6.0.0)"

cp "$result" ./llvm.tar.xz
