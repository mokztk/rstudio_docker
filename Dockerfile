# rocker/r-ver:4.5.0 をベースにtidyverse, 日本語設定, SSH server等を追加する（amd64/arm64共通）
#   ENV CRAN="https://p3m.dev/cran/__linux__/noble/2025-06-12"

# rocker/tidyverse:4.5.0 の Dockerfile を参考にベースを構築
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/r-ver_4.5.0.Dockerfile
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/rstudio_4.5.0.Dockerfile
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/tidyverse_4.5.0.Dockerfile

FROM rocker/r-ver:4.5.0 AS tidyverse_cli

# RStudio, S6 suprevisor は入れずに rocker/tidyverse 相当のパッケージを導入（行番号は @8cd5d36 準拠）
# pandoc, quarto は rocker/rstudio:4.5.0 と同じバージョンを指定

#RUN sed -e "40,75d; 80,120d; 125,128d; 133,138d" /rocker_scripts/install_rstudio.sh | bash
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        gdebi-core \
        git \
        libclang-dev \
        libssl-dev \
        lsb-release \
        psmisc \
        pwgen \
        sudo \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/R

ENV DEFAULT_USER="rstudio" \
    PANDOC_VERSION="3.7.0.2" \
    QUARTO_VERSION="1.6.42"

RUN /rocker_scripts/default_user.sh "${DEFAULT_USER}"
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh

# 容量の大きな database backend は RSQLite 以外省略（行番号は @5d33fd1 準拠）
RUN sed -e 48d -e 52,56d /rocker_scripts/install_tidyverse.sh | bash

CMD ["R"]

# 上記の rocker/tidyverse 相当のイメージに日本語設定などを追加

FROM tidyverse_cli AS r_remote

# 日本語設定と必要なライブラリ（Rパッケージ用は別途スクリプト内で導入）
# ${R_HOME}/etc/Renviron のタイムゾーン指定（Etc/UTC）も上書きしておく
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        language-pack-ja-base \
        ssh \
        nodejs \
        npm \
    && /usr/sbin/update-locale LANG=ja_JP.UTF-8 LANGUAGE="ja_JP:ja" \
    && /bin/bash -c "source /etc/default/locale" \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "TZ=Asia/Tokyo" >> /home/rstudio/.Renviron \
    && chown rstudio:rstudio /home/rstudio/.Renviron

ENV LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    TZ=Asia/Tokyo

# setup script
# 各スクリプトは改行コード LF(UNIX) でないとエラーになる
COPY my_scripts /my_scripts
RUN chmod 775 my_scripts/*
RUN /my_scripts/install_r_packages.sh
RUN /my_scripts/install_radian.sh
RUN /my_scripts/install_notojp.sh
#RUN /my_scripts/install_coding_fonts.sh
RUN /my_scripts/install_msedit.sh
RUN /my_scripts/setup_sshd.sh

# 検証用ファイル
COPY --chown=rstudio:rstudio utils /home/rstudio/utils

# SSH server を起動
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
