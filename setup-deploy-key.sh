#!/bin/bash

# Hugo + GitHub Pages 部署密钥生成脚本
# 这个脚本会帮你生成 SSH 密钥对，用于 GitHub Actions 自动部署

echo "🚀 开始生成部署密钥..."
echo ""

# 检查是否已存在密钥
if [ -f ~/.ssh/hugo_deploy_key ]; then
    echo "⚠️  警告：~/.ssh/hugo_deploy_key 已存在"
    read -p "是否覆盖？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消操作"
        exit 1
    fi
fi

# 生成 SSH 密钥对
echo "📝 正在生成 SSH 密钥对..."
ssh-keygen -t rsa -b 4096 -C "hugo-deploy@github-actions" -f ~/.ssh/hugo_deploy_key -N ""

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 密钥生成成功！"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 接下来的步骤："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1️⃣  在 neo-dai.github.io 仓库添加公钥（Deploy Key）："
    echo "   - 访问：https://github.com/neo-dai/neo-dai.github.io/settings/keys"
    echo "   - 点击 'Add deploy key'"
    echo "   - Title: Hugo Deploy Action"
    echo "   - Key: 复制下面的公钥内容（从 -----BEGIN 到 -----END）"
    echo "   - ✅ 勾选 'Allow write access'"
    echo "   - 点击 'Add key'"
    echo ""
    echo "   公钥内容："
    echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat ~/.ssh/hugo_deploy_key.pub
    echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "2️⃣  在 my-blog-source 仓库添加私钥（Secret）："
    echo "   - 访问：https://github.com/neo-dai/my-blog-source/settings/secrets/actions"
    echo "   - 点击 'New repository secret'"
    echo "   - Name: ACTIONS_DEPLOY_KEY（必须完全一致）"
    echo "   - Value: 复制下面的私钥内容（从 -----BEGIN 到 -----END）"
    echo "   - 点击 'Add secret'"
    echo ""
    echo "   私钥内容："
    echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat ~/.ssh/hugo_deploy_key
    echo "   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "3️⃣  完成！现在你可以："
    echo "   - 推送代码到 my-blog-source 仓库"
    echo "   - GitHub Actions 会自动构建并部署到 neo-dai.github.io"
    echo ""
else
    echo "❌ 密钥生成失败"
    exit 1
fi

