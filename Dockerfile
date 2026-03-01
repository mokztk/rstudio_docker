# rocker/r-ver:4.5.1 をベースに共通部分を作ってから RStudio server, SSH server に分岐
#  ENV CRAN="https://p3m.dev/cran/__linux__/noble/2025-10-30"
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/r-ver_4.5.1.Dockerfile
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/rstudio_4.5.1.Dockerfile
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/tidyverse_4.5.1.Dockerfile

# RStudio Server, S6 surpervisor, SSH server を入れる前の両者に共通の部分

FROM rocker/r-ver:4.5.1 AS tidyverse_base

# 日本語設定と必要なライブラリ（Rパッケージ用は別途スクリプト内で導入）
# ${R_HOME}/etc/Renviron のタイムゾーン指定（Etc/UTC）も上書きしておく
# 以降も何度か apt-get を使うので BuildKit のキャッシュマウント機能を使う
RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        sudo \
        wget \
        zstd \
        language-pack-ja-base \
        ssh \
        unison \
        fswatch \
    && /usr/sbin/update-locale LANG=ja_JP.UTF-8 LANGUAGE="ja_JP:ja" \
    && /bin/bash -c "source /etc/default/locale" \
    && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apt-get clean \
    && mkdir -p /etc/R

# pandoc, quarto は rocker/rstudio:4.5.1 と同じバージョンを指定
# wget, ca-certicifates は導入済みのため apt の処理はスキップ（行番号は @07c155e 準拠）

ENV DEFAULT_USER="rstudio" \
    PANDOC_VERSION="3.8.2.1" \
    QUARTO_VERSION="1.7.32"

RUN /rocker_scripts/default_user.sh "${DEFAULT_USER}" \
    && echo "${DEFAULT_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${DEFAULT_USER} \
    && chmod 0440 /etc/sudoers.d/${DEFAULT_USER}

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    sed -e "16,26d" -e "85d" /rocker_scripts/install_pandoc.sh | bash \
    && sed -e "21,31d" -e "74d" /rocker_scripts/install_quarto.sh | bash

# install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.6 /uv /uvx /opt/uv/bin/

# setup script
# 各スクリプトは改行コード LF(UNIX) でないとエラーになる
COPY my_scripts /my_scripts

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/R,sharing=locked \
    --mount=type=cache,target=/tmp,sharing=locked \
    chmod 775 my_scripts/* \
    && bash /my_scripts/install_r_packages_pak.sh \
    && bash /my_scripts/install_python_uv.sh \
    && bash /my_scripts/install_nodejs.sh \
    && bash /my_scripts/install_notojp.sh \
    && bash /my_scripts/install_msedit.sh

# 検証用ファイル
COPY --chown=rstudio:rstudio utils /home/rstudio/utils

CMD ["R"]


# 共通部分をベースにRStudio server等を追加する

FROM tidyverse_base AS rstudio

# rocker/rstudio:4.5.1 の Dockerfile より流用
#  https://github.com/rocker-org/rocker-versioned2/blob/master/dockerfiles/r-ver_4.5.1.Dockerfile

ENV S6_VERSION="v2.1.0.2" \
    RSTUDIO_VERSION="2025.09.2+418" \
    DEFAULT_USER="rstudio"

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    sed -e "131d" /rocker_scripts/install_rstudio.sh | bash

RUN /my_scripts/install_coding_fonts.sh

# pak でのインストールエラー対策
# R_LIBS_USER に指定されているディレクトリを .libPaths() の先頭にする
USER rstudio
RUN Rscript -e 'dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)' \
    && echo '.libPaths(c(Sys.getenv("R_LIBS_USER"), .Library.site, .Library))' >> /home/rstudio/.Rprofile

USER root
ENV LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    TZ=Asia/Tokyo \
    PASSWORD=password \
    DISABLE_AUTH=true \
    RUNROOTLESS=false

WORKDIR /workspace
EXPOSE 8787
CMD ["/init"]


# 共通部分をベースに、SSH server を追加する

FROM tidyverse_base AS ssh

RUN /my_scripts/setup_sshd.sh

# pak でのインストールエラー対策
# R_LIBS_USER に指定されているディレクトリを .libPaths() の先頭にする
USER rstudio
RUN Rscript -e 'dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE)' \
    && echo '.libPaths(c(Sys.getenv("R_LIBS_USER"), .Library.site, .Library))' >> /home/rstudio/.Rprofile

USER root
ENV LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    TZ=Asia/Tokyo

# SSH server を起動
WORKDIR /workspace
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
