#!/usr/bin/env bash
set -euo pipefail

#############################################
# Utility helpers
#############################################

normalize_arch() {
  case "$(uname -m)" in
    x86_64)  echo "amd64" ;;
    aarch64) echo "arm64" ;;
    arm64)   echo "arm64" ;;
    *)       echo "unknown" ;;
  esac
}

ARCH="$(normalize_arch)"

if [[ "$ARCH" == "unknown" ]]; then
  echo "Unsupported architecture: $(uname -m)" >&2
  exit 1
fi

get_latest_release() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -Po '"tag_name":\s*"\K[^"]+'
}

dl() {
  wget -q --show-progress --https-only --secure-protocol=TLSv1_2 "$@"
}

#############################################
# Existing Tools
#############################################

download_ctop() {
  local version
  version="$(get_latest_release bcicen/ctop | sed 's/^v//')"
  local url="https://github.com/bcicen/ctop/releases/download/v${version}/ctop-${version}-linux-${ARCH}"

  dl -O /tmp/ctop "$url"
  chmod +x /tmp/ctop
}

download_calicoctl() {
  local version
  version="$(get_latest_release projectcalico/calico)"
  local url="https://github.com/projectcalico/calico/releases/download/${version}/calicoctl-linux-${ARCH}"

  dl -O /tmp/calicoctl "$url"
  chmod +x /tmp/calicoctl
}

download_termshark() {
  local version term_arch tmpdir
  version="$(get_latest_release gcla/termshark | sed 's/^v//')"

  case "$ARCH" in
    amd64) term_arch="x64" ;;
    *)     term_arch="$ARCH" ;;
  esac

  tmpdir="$(mktemp -d)"
  local url="https://github.com/gcla/termshark/releases/download/v${version}/termshark_${version}_linux_${term_arch}.tar.gz"

  dl -O "${tmpdir}/ts.tgz" "$url"
  tar -xzf "${tmpdir}/ts.tgz" -C "${tmpdir}"
  mv "${tmpdir}/termshark_${version}_linux_${term_arch}/termshark" /tmp/termshark

  chmod +x /tmp/termshark
  rm -rf "$tmpdir"
}

download_grpcurl() {
  local version tar_arch tmpdir
  version="$(get_latest_release fullstorydev/grpcurl | sed 's/^v//')"

  case "$ARCH" in
    amd64) tar_arch="x86_64" ;;
    *)     tar_arch="$ARCH" ;;
  esac

  tmpdir="$(mktemp -d)"
  local url="https://github.com/fullstorydev/grpcurl/releases/download/v${version}/grpcurl_${version}_linux_${tar_arch}.tar.gz"

  dl -O "${tmpdir}/grpcurl.tgz" "$url"
  tar -xzf "${tmpdir}/grpcurl.tgz" -C "${tmpdir}"

  mv "${tmpdir}/grpcurl" /tmp/grpcurl
  chmod +x /tmp/grpcurl
  rm -rf "$tmpdir"
}

download_fortio() {
  local version tmpdir
  version="$(get_latest_release fortio/fortio | sed 's/^v//')"

  tmpdir="$(mktemp -d)"
  local url="https://github.com/fortio/fortio/releases/download/v${version}/fortio-linux_${ARCH}-${version}.tgz"

  dl -O "${tmpdir}/fortio.tgz" "$url"
  tar -xzf "${tmpdir}/fortio.tgz" -C "${tmpdir}"

  mv "${tmpdir}/usr/bin/fortio" /tmp/fortio
  chmod +x /tmp/fortio
  rm -rf "$tmpdir"
}

#############################################
# NEW TOOLS ADDED ✨
#############################################

download_kubectl() {
  local version
  version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  local url="https://dl.k8s.io/release/${version}/bin/linux/${ARCH}/kubectl"

  dl -O /tmp/kubectl "$url"
  chmod +x /tmp/kubectl
}

download_k9s() {
  local version tmpdir
  version="$(get_latest_release derailed/k9s | sed 's/^v//')"

  tmpdir="$(mktemp -d)"
  local url="https://github.com/derailed/k9s/releases/download/v${version}/k9s_Linux_${ARCH}.tar.gz"

  dl -O "${tmpdir}/k9s.tgz" "$url"
  tar -xzf "${tmpdir}/k9s.tgz" -C "$tmpdir"

  mv "${tmpdir}/k9s" /tmp/k9s
  chmod +x /tmp/k9s
  rm -rf "$tmpdir"
}

download_stern() {
  local version
  version="$(get_latest_release stern/stern)"
  local url="https://github.com/stern/stern/releases/download/${version}/stern_${ARCH}"

  dl -O /tmp/stern "$url"
  chmod +x /tmp/stern
}

download_helm() {
  local version tmpdir
  version="$(get_latest_release helm/helm)"

  tmpdir="$(mktemp -d)"
  local url="https://get.helm.sh/helm-${version}-linux-${ARCH}.tar.gz"

  dl -O "${tmpdir}/helm.tgz" "$url"
  tar -xzf "${tmpdir}/helm.tgz" -C "$tmpdir"

  mv "${tmpdir}/linux-${ARCH}/helm" /tmp/helm
  chmod +x /tmp/helm
  rm -rf "$tmpdir"
}

download_hurl() {
  local version
  version="$(get_latest_release Orange-OpenSource/hurl | sed 's/^v//')"
  local url="https://github.com/Orange-OpenSource/hurl/releases/download/v${version}/hurl-${version}-x86_64-linux.tar.gz"

  tmpdir="$(mktemp -d)"
  dl -O "${tmpdir}/hurl.tgz" "$url"
  tar -xzf "${tmpdir}/hurl.tgz" -C "$tmpdir"

  mv "${tmpdir}/hurl-${version}/bin/hurl" /tmp/hurl
  chmod +x /tmp/hurl
  rm -rf "$tmpdir"
}

download_oha() {
  local version
  version="$(get_latest_release hatoo/oha | sed 's/^v//')"
  local url="https://github.com/hatoo/oha/releases/download/v${version}/oha-v${version}-x86_64-linux"

  dl -O /tmp/oha "$url"
  chmod +x /tmp/oha
}

download_step_cli() {
  local version tmpdir
  version="$(get_latest_release smallstep/cli | sed 's/^v//')"

  tmpdir="$(mktemp -d)"
  local url="https://github.com/smallstep/cli/releases/download/v${version}/step_linux_${ARCH}-${version}.tar.gz"

  dl -O "${tmpdir}/step.tgz" "$url"
  tar -xzf "${tmpdir}/step.tgz" -C "$tmpdir"

  mv "${tmpdir}/step_${version}/bin/step" /tmp/step
  chmod +x /tmp/step
  rm -rf "$tmpdir"
}

download_yq() {
  local url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH}"
  dl -O /tmp/yq "$url"
  chmod +x /tmp/yq
}

download_ripgrep() {
  local version tmpdir
  version="$(get_latest_release BurntSushi/ripgrep | sed 's/^v//')"

  tmpdir="$(mktemp -d)"
  local url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-x86_64-unknown-linux-musl.tar.gz"

  dl -O "${tmpdir}/rg.tgz" "$url"
  tar -xzf "${tmpdir}/rg.tgz" -C "$tmpdir"

  mv "${tmpdir}/ripgrep-${version}-x86_64-unknown-linux-musl/rg" /tmp/rg
  chmod +x /tmp/rg
  rm -rf "$tmpdir"
}

download_fzf() {
  local version
  version="$(get_latest_release junegunn/fzf | sed 's/^v//')"  
  local url="https://github.com/junegunn/fzf/releases/download/v${version}/fzf-${version}-linux_${ARCH}.tar.gz"

  tmpdir="$(mktemp -d)"
  dl -O "${tmpdir}/fzf.tgz" "$url"
  tar -xzf "${tmpdir}/fzf.tgz" -C "$tmpdir"

  mv "${tmpdir}/fzf" /tmp/fzf
  chmod +x /tmp/fzf
  rm -rf "$tmpdir"
}

download_bat() {
  local version tmpdir
  version="$(get_latest_release sharkdp/bat | sed 's/^v//')"

  tmpdir="$(mktemp -d)"
  local url="https://github.com/sharkdp/bat/releases/download/v${version}/bat-v${version}-x86_64-unknown-linux-musl.tar.gz"

  dl -O "${tmpdir}/bat.tgz" "$url"
  tar -xzf "${tmpdir}/bat.tgz" -C "$tmpdir"

  mv "${tmpdir}/bat-v${version}-x86_64-unknown-linux-musl/bat" /tmp/bat
  chmod +x /tmp/bat
  rm -rf "$tmpdir"
}

#############################################
# Install everything
#############################################

download_ctop
download_calicoctl
download_termshark
download_grpcurl
download_fortio

# New tools
download_kubectl
# download_k9s
# download_stern
# download_helm
# download_hurl
# download_oha
# download_step_cli
# download_yq
# download_ripgrep
# download_fzf
# download_bat
