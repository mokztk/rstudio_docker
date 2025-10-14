#!/bin/bash

mkdir /var/run/sshd

# 公開鍵を置くディレクトリをユーザー rstudio で作っておく
mkdir /home/rstudio/.ssh/
chown -R rstudio:rstudio /home/rstudio/.ssh/

# 作業用ディレクトリ
mkdir /workspace
chmod 777 /workspace
