#!/bin/bash
set -x

# Install coding fonts (for RStudio Server)

## UDEV Gothic LG (BIZ UD Gothic + JetBrains Mono)
##   https://github.com/yuru7/udev-gothic
mkdir -p /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/400/italic
mkdir -p /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/700/italic
wget -q https://github.com/yuru7/udev-gothic/releases/download/v2.1.0/UDEVGothic_v2.1.0.zip -O UDEVGothic.zip
unzip -j -d UDEVGothic UDEVGothic.zip
cp UDEVGothic/UDEVGothicLG-Regular.ttf /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/400
cp UDEVGothic/UDEVGothicLG-Italic.ttf /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/400/italic
cp UDEVGothic/UDEVGothicLG-Bold.ttf /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/700
cp UDEVGothic/UDEVGothicLG-BoldItalic.ttf /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/700/italic
mv /home/rstudio/.config/rstudio/fonts/UDEVGothicLG/ /home/rstudio/.config/rstudio/fonts/UDEV\ Gothic\ LG/
rm -rf UDEVGothic*

## Mint Mono (Intel One Gothic + Circle M+, etc.)
##   https://github.com/yuru7/mint-mono
mkdir -p /home/rstudio/.config/rstudio/fonts/MintMono/400/italic
mkdir -p /home/rstudio/.config/rstudio/fonts/MintMono/700/italic
wget -q https://github.com/yuru7/mint-mono/releases/download/v0.0.1/MintMono_v0.0.1.zip -O MintMono.zip
unzip -j -d MintMono MintMono.zip
cp MintMono/MintMono-Regular.ttf /home/rstudio/.config/rstudio/fonts/MintMono/400
cp MintMono/MintMono-Italic.ttf /home/rstudio/.config/rstudio/fonts/MintMono/400/italic
cp MintMono/MintMono-Bold.ttf /home/rstudio/.config/rstudio/fonts/MintMono/700
cp MintMono/MintMono-BoldItalic.ttf /home/rstudio/.config/rstudio/fonts/MintMono/700/italic
rm -rf MintMono*

chown -R rstudio:rstudio /home/rstudio/.config/rstudio
