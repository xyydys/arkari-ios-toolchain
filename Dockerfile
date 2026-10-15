# syntax=docker/dockerfile:1
# Arkari（OLLVM 的现代分支）工具链镜像：从源码编 clang + lld，供插件混淆编译用。
# 一次性构建、推 GHCR；之后每次混淆出包直接拉这个镜像，几分钟出 deb。
#
# Arkari 的混淆 flag 是 -irobf-* 系（不是经典 OLLVM 的 -sobf/-fla/-sub）：
#   -irobf            启用混淆框架（单独开不跑任何 pass）
#   -irobf-cse        C 字符串加密   ← 藏 endpoint / 公钥，最高性价比
#   -irobf-fla        控制流平坦化
#   -irobf-indbr      间接跳转（加密跳转目标）
#   -irobf-icall      间接调用（加密目标地址）
#   -irobf-indgv      间接全局变量引用（加密地址）
#   -irobf-cie        整数常量加密
#   -irobf-cfe        浮点常量加密
# 强度 0-3 可用 -level-icall=3 之类调。

FROM ubuntu:24.04 AS build
ARG ARKARI_REPO=https://github.com/komimoe/Arkari
# 默认钉在有 Release 的 LLVM 20 obf 标签（稳）；要升级改成 llvm-21.x / llvm-22.x。
ARG ARKARI_REF=llvm-20-obf1.9.1
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      git cmake ninja-build python3 build-essential \
      zlib1g-dev libzstd-dev libxml2-dev ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch "${ARKARI_REF}" "${ARKARI_REPO}" arkari
# 只编 clang + lld，只出 AArch64/X86 后端，Release：把 LLVM 全量构建压到可控范围。
RUN cmake -S arkari/llvm -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_PROJECTS="clang;lld" \
      -DLLVM_TARGETS_TO_BUILD="AArch64;X86" \
      -DLLVM_ENABLE_ASSERTIONS=OFF \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_BENCHMARKS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DCMAKE_INSTALL_PREFIX=/opt/arkari \
    && ninja -C build install-clang install-clang-resource-headers install-lld \
    && rm -rf /src build

# ---- 运行镜像：只带工具链 + 出 deb 需要的东西（SDK/ldid 在 CI 里现拉）----
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates dpkg-dev binutils xz-utils \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/arkari /opt/arkari
ENV PATH=/opt/arkari/bin:$PATH
RUN clang --version && (ld64.lld --version || true)
