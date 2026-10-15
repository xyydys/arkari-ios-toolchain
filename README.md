# arkari-ios-toolchain

公开的**工具链构建器**：从 [Arkari](https://github.com/komimoe/Arkari)（OLLVM 的现代分支）
源码编译 `clang` + `lld`，打成 Docker 镜像推到 GHCR，供 iOS 交叉编译时做代码混淆。

**本仓库不含任何业务代码**——只有一个 `Dockerfile`，它在构建时去 Arkari 官方仓库拉源码。
公开的唯一目的：用 GitHub 公开仓库的**免费无限构建分钟** + GHCR **公开镜像的免费存储/下载**。

## 用法
- **构建**：push 到 `main` 或在 Actions 页手动 Run `build-image`（约 1.5~3 小时，一次性）。
- **产物**：`ghcr.io/<owner>/arkari-ios-toolchain:latest`
- **首次成功后**：到 GitHub → 你的头像 → Packages → `arkari-ios-toolchain` →
  Package settings → 把可见性设为 **Public**。这样下游私库免凭证拉取，且不占私有存储额度。

## 升级 Arkari
手动 Run，`arkari_ref` 填新分支（如 `llvm-21.x`）即可。
