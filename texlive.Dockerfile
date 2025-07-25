FROM debian:bookworm-slim AS texlive-builder

ARG TL_MIRROR="https://mirror.aarnet.edu.au/pub/CTAN/systems/texlive/tlnet"

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  perl \
  curl \
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
  catchfile \
  csvsimple \
  environ \
  fontawesome \
  fontspec \
  framed \
  fvextra \
  lastpage \
  lineno \
  luacode \
  luaotfload \
  luatexbase \
  luatextra \
  markdown \
  metalogo \
  minted \
  multirow \
  newpax \
  paralist \
  pdfcol \
  pdflscape \
  pdfmanagement-testphase \
  pdfpages \
  tagpdf \
  tcolorbox \
  tikzfill \
  upquote \
  xstring

# Copy in Latex build script, along with asset images
COPY ./lib/shell/latex_build.sh /texlive/shell/latex_build.sh
COPY ./public/assets/images /doubtfire/public/assets/images

# Final image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
  imagemagick \
  # inkscape \
  python3-pygments \
  librsvg2-bin && \
  rm -rf /var/lib/apt/lists/*

COPY --from=texlive-builder /opt/texlive /opt/texlive
COPY --from=texlive-builder /texlive /texlive
COPY --from=texlive-builder /doubtfire/public/assets/images /doubtfire/public/assets/images

ENV PATH $PATH:/opt/texlive/bin/x86_64-linux:/opt/texlive/bin/aarch64-linux:
RUN chmod +x /texlive/shell/latex_build.sh

CMD ["sh", "-c", "sleep infinity"]
