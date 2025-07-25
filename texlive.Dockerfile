FROM debian:bookworm-slim

# ARG TL_MIRROR="https://texlive.info/CTAN/systems/texlive/tlnet"
ARG TL_MIRROR="https://mirror.aarnet.edu.au/pub/CTAN/systems/texlive/tlnet"

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  perl \
  curl \
  imagemagick \
  inkscape \
  librsvg2-bin \
  wget \
  ca-certificates \
  xz-utils && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir /tmp/texlive && cd /tmp/texlive && \
  wget "$TL_MIRROR/install-tl-unx.tar.gz" && \
  tar xzvf ./install-tl-unx.tar.gz && \
  ( \
  echo "selected_scheme scheme-basic" && \
  echo "instopt_adjustpath 0" && \
  echo "tlpdbopt_install_docfiles 0" && \
  echo "tlpdbopt_install_srcfiles 0" && \
  echo "TEXDIR /opt/texlive/" && \
  echo "TEXMFLOCAL /opt/texlive/texmf-local" && \
  echo "TEXMFSYSCONFIG /opt/texlive/texmf-config" && \
  echo "TEXMFSYSVAR /opt/texlive/texmf-var" && \
  echo "TEXMFHOME ~/.texmf" \
  ) > /tmp/texlive.profile && \
  ./install-tl-*/install-tl --location "$TL_MIRROR" -profile /tmp/texlive.profile && \
  rm -rf /tmp/*


ENV PATH $PATH:/opt/texlive/bin/x86_64-linux:/opt/texlive/bin/aarch64-linux:

RUN tlmgr install scheme-basic
RUN tlmgr install \
  fontawesome \
  minted \
  fvextra \
  catchfile \
  xstring \
  framed \
  lastpage \
  tcolorbox \
  environ \
  pdfcol \
  tikzfill \
  markdown \
  paralist \
  csvsimple \
  upquote \
  tagpdf \
  pdfmanagement-testphase \
  fontspec \
  luaotfload \
  luatexbase \
  metalogo \
  luacode \
  lineno \
  pdflscape \
  luatextra \
  pdfpages \
  multirow \
  newpax

# Copy in Latex build script, along with asset images
COPY ./lib/shell/latex_build.sh /texlive/shell/latex_build.sh
COPY ./public/assets/images /doubtfire/public/assets/images

RUN chmod +x /texlive/shell/latex_build.sh

CMD ["sh", "-c", "sleep infinity"]
