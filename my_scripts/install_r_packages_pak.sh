#!/bin/bash

# R パッケージのインストール

apt-get update

# base の tcltk パッケージのために Tcl/Tk を入れておく
apt-get install -y --no-install-recommends \
    libtcl8.6 \
    libtk8.6

# まず最新の状態まで更新する
Rscript -e "update.packages(ask = FALSE)"

# pak::pak() で依存ライブラリもインストールしてくれるので apt install は省略
# (4.5.0) pak で RccpEigen がうまくインストールできないので、ここで入れておく
install2.r --error --ncpus -1 --skipinstalled \
    pak \
    RcppEigen

# インストール補助の関数
# 引数を１つずつ '' で囲んで , で繋いだものを pak::pak() に渡す
function pak_pak() {
    local pkgs=""
    local first=true
    for item in "$@"; do
        if ! $first; then
            pkgs="${pkgs},"
        fi
        pkgs="${pkgs}'${item}'"
        first=false
    done
    Rscript -e "pak::pak(c(${pkgs}))"
}

# rocker/tidyverse 相当のパッケージ
# 容量の大きな database backend は RSQLite 以外省略（行番号は @5d33fd1 準拠）
#RUN sed -e 48d -e 52,56d /rocker_scripts/install_tidyverse.sh | bash

pak_pak \
    tidyverse \
    devtools \
    rmarkdown \
    BiocManager \
    vroom \
    gert \
    dbplyr \
    DBI \
    dtplyr \
    RSQLite \
    fst

# 繁用パッケージ
pak_pak \
    here \
    pacman \
    knitr \
    quarto \
    tidylog \
    furrr \
    glmnetUtils \
    glmmTMB \
    ggeffects \
    pROC \
    cmprsk \
    car \
    mice \
    ggmice \
    survminer \
    ggsurvfit \
    GGally \
    ggfortify \
    gghighlight \
    ggsci \
    ggrepel \
    patchwork \
    gt \
    gtsummary \
    flextable \
    formattable \
    ftExtra \
    minidown \
    DiagrammeR \
    palmerpenguins \
    basepenguins \
    styler \
    svglite \
    export \
    tidyplots \
    tinytable

# R.cache (imported by styler) で使用するキャッシュディレクトリを準備
mkdir -p /home/rstudio/.cache/R/R.cache
chown -R rstudio:rstudio /home/rstudio/.cache

# Clean up
Rscript -e "pak::pak_cleanup(force = TRUE)"
rm -rf /tmp/downloaded_packages
rm -rf /tmp/Rtmp*
strip /usr/local/lib/R/site-library/*/libs/*.so

apt-get clean
rm -rf /var/lib/apt/lists/*
