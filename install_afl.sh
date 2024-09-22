#!/bin/bash

cd ..
git clone https://github.com/AFLplusplus/AFLplusplus
cd AFLplusplus
make distrib
make install

echo "DONE"
