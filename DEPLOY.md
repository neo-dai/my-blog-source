# 🚀 Hugo + GitHub Pages 自动部署指南

本指南将帮助你设置 Hugo 博客的自动部署流程。

## 📦 仓库说明

- **源码仓库**：`neo-dai/my-blog-source`（私有仓库，存放 Hugo 源码）
- **部署仓库**：`neo-dai/neo-dai.github.io`（公开仓库，存放生成的静态页面）

## 🔑 步骤 1：生成部署密钥

### 方法一：使用自动化脚本（推荐）

运行以下命令：

```bash
./setup-deploy-key.sh
```

脚本会自动生成密钥对，并显示公钥和私钥内容。

### 方法二：手动生成

在终端运行：

```bash
ssh-keygen -t rsa -b 4096 -C "hugo-deploy@github-actions" -f ~/.ssh/hugo_deploy_key
```

按回车使用默认设置（不设置密码）。

这会生成两个文件：
- `~/.ssh/hugo_deploy_key`（私钥）
- `~/.ssh/hugo_deploy_key.pub`（公钥）

## 🔐 步骤 2：配置 GitHub 仓库

### 2.1 在 `neo-dai.github.io` 仓库添加公钥（Deploy Key）

1. 访问：https://github.com/neo-dai/neo-dai.github.io/settings/keys
2. 点击 **"Add deploy key"** 按钮
3. 填写信息：
   - **Title**：`Hugo Deploy Action`（任意名称）
   - **Key**：复制 `~/.ssh/hugo_deploy_key.pub` 文件的**全部内容**（包括 `ssh-rsa` 开头和邮箱结尾）
   - **✅ 必须勾选 "Allow write access"**（允许写入权限）
4. 点击 **"Add key"**

### 2.2 在 `my-blog-source` 仓库添加私钥（Secret）

1. 访问：https://github.com/neo-dai/my-blog-source/settings/secrets/actions
2. 点击 **"New repository secret"** 按钮
3. 填写信息：
   - **Name**：`ACTIONS_DEPLOY_KEY`（**必须完全一致**，包括大小写）
   - **Value**：复制 `~/.ssh/hugo_deploy_key` 文件的**全部内容**（包括 `-----BEGIN OPENSSH PRIVATE KEY-----` 开头和 `-----END OPENSSH PRIVATE KEY-----` 结尾）
4. 点击 **"Add secret"**

## ✅ 步骤 3：验证配置

1. 确保 `.github/workflows/deploy.yml` 文件已存在
2. 推送代码到 `my-blog-source` 仓库：
   ```bash
   git add .
   git commit -m "添加自动部署配置"
   git push origin main
   ```
3. 访问：https://github.com/neo-dai/my-blog-source/actions
4. 你应该能看到一个新的 workflow 运行
5. 等待几分钟，workflow 完成后，访问 https://neo-dai.github.io 查看你的网站

## 📝 工作流程

设置完成后，你的工作流程非常简单：

1. 在本地编写 Markdown 文章
2. `git add .`
3. `git commit -m "写了篇新文章"`
4. `git push origin main`（推送到 `my-blog-source`）
5. GitHub Actions 自动构建并部署
6. 几分钟后，网站自动更新

## 🔍 常见问题

### Q: Workflow 运行失败，提示权限错误？

A: 检查以下几点：
- 确保在 `neo-dai.github.io` 仓库的 Deploy Key 中勾选了 "Allow write access"
- 确保在 `my-blog-source` 仓库的 Secret 名称是 `ACTIONS_DEPLOY_KEY`（完全一致）
- 确保私钥内容完整（包括 BEGIN 和 END 标记）

### Q: 如何查看私钥内容？

A: 运行以下命令：
```bash
cat ~/.ssh/hugo_deploy_key
```

### Q: 如何查看公钥内容？

A: 运行以下命令：
```bash
cat ~/.ssh/hugo_deploy_key.pub
```

### Q: Workflow 运行成功但网站没有更新？

A: 检查：
- 确保 `neo-dai.github.io` 仓库的 GitHub Pages 设置已启用
- 在仓库 Settings > Pages 中，Source 应该设置为 `Deploy from a branch`，Branch 选择 `main`

## 📚 参考链接

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [peaceiris/actions-gh-pages](https://github.com/peaceiris/actions-gh-pages)
- [peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo)

