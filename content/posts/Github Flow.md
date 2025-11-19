
+++
title = "理解 GitHub Flow：我的极简 Git 工作流学习笔记"
date = 2025-11-09T22:35:00+08:00
draft = false
description = "从混乱到清晰，这是我学到的 GitHub Flow 核心思想：一个主干、N个临时分支和N个版本快照。"
tags = ["Git", "GitHub", "DevOps", "工作流", "编程"]
categories = ["技术实践"]
+++

## 为什么我需要一个新的 Git 工作流？

在开始我的 [MMO 服务器开发计划](/) (这里你可以链向你的另一篇博文) 时，我很快就遇到了一个问题：我该如何管理我的20个开发 "Lab"？

我最初的想法是：“为每个 Lab 创建一个分支，最后再合并到 `main`？”

事实证明，这个想法是完全错误的。它混淆了“过程”与“版本”。

经过一番探索，我发现了一个更简单、更强大、也是目前最主流的模式：**GitHub Flow**。这篇笔记就是为了记录我对这个工作流的理解。

## 什么是 GitHub Flow？

GitHub Flow 是一种轻量级的、基于分支的协作模式。它的哲学可以用两句话总结：

1.  `main` 分支永远是**神圣的**。它必须**在任何时刻都保持稳定、可部署**。
2.  **所有的工作**（新功能、Bug修复）都在**临时的特性分支**上进行，并通过 **Pull Request (PR)** 合并回 `main`。

没有复杂的 `develop` 分支，也没有冗长的 `release` 分支。它只有一个**永恒的主干 (`main`)** 和 **N 个用完即焚的临时分支**。

---

## 核心开发循环：我的实践

下面，我用我的 `lab1-chatroom` (聊天室) 和 `lab2-movement` (移动同步) 作为例子，来走一遍完整的流程。

### 步骤 1: 创建特性分支

永远不要、永远不要直接在 `main` 分支上写代码。

当我要开始做“Lab 1 聊天室”时，我首先要基于最新的 `main` 分支，切出一个新分支：

```bash
# 1. 确保我在 main 分支
git checkout main

# 2. 拉取最新代码，确保我的 main 和远程 GitHub 上的 main 一致
git pull origin main

# 3. 为我的新功能创建一个描述性的分支
git checkout -b feat/lab1-chatroom
````

  * **命名规范：** 我喜欢用 `feat/` (功能) 或 `fix/` (修复) 作为前缀，这样分支列表会非常清晰。

### 步骤 2: 本地开发与提交

现在，我在 `feat/lab1-chatroom` 这个“临时工作台”上，可以尽情地编写、调试、提交。

```bash
# ... (编写聊天室 V0.1 的代码) ...

# 提交我的工作
git add .
git commit -m "Feat: 实现 v0.1 基础回音服务器"

# ... (继续编写 v0.2, v0.3...) ...

git add .
git commit -m "Feat: 实现 v0.3 广播与昵称功能"
```

### 步骤 3: 发起拉取请求 (Pull Request - PR)

当我完成了 Lab 1 的所有功能，并且在本地测试通过后，我将这个分支推送到 GitHub：

```bash
git push origin feat/lab1-chatroom
```

然后，我打开 GitHub 仓库页面，点击 "Compare & pull request" 按钮。

**PR 是 GitHub Flow 的灵魂。** 它不是一个简单的“合并”请求，它是一个**沟通和评审**的中心。在这里，我可以：

  * @ 提醒我自己（或未来的同事）来审查代码。
  * 写下这个功能解决了什么问题。
  * 让 GitHub Actions 自动运行我的测试。

### 步骤 4: 评审、合并、删除

在（自己）确认 PR 里的代码没问题后，我按下了绿色的 "Merge pull request" 按钮。

**重点来了：** 一旦合并，`feat/lab1-chatroom` 分支的使命就**彻底终结**了。

1.  `main` 分支现在包含了 Lab 1 的所有代码。
2.  GitHub 会提示我删除这个**远程分支**，我应该立即点击 "Delete branch"。
3.  我还需要在本地清理这个**本地分支**：

<!-- end list -->

```bash
# 1. 切回 main
git checkout main

# 2. 拉取刚刚合并的最新代码
git pull origin main

# 3. 删除已经没用的本地分支（-d 会安全检查，确保已合并）
git branch -d feat/lab1-chatroom
```

### 步骤 5: 如此循环

当我开始做 Lab 2 时，我只需要重复**步骤 1**：

```bash
git checkout main
git pull origin main
git checkout -b feat/lab2-movement
```

我的 `main` 分支就像一个不断成长的树干，通过一次次 PR，不断吸收新的功能，永远保持健壮。

-----

## 进阶场景：开发 Lab 2 时发现 Lab 1 有 Bug 怎么办？

这是我当时最困惑的问题，而 GitHub Flow 给了我一个极其优雅的答案。

假设我正在 `feat/lab2-movement` 分支上写代码（可能写了一半，还没 `commit`），突然发现 Lab 1 的聊天室有 Bug。

**黄金法则：** 永远不要在 `lab2` 的分支上修复 `lab1` 的 Bug！PR 必须保持纯净。

正确的流程（中断 -\> 修复 -\> 恢复）：

1.  **"暂停" Lab 2 的工作：**

    ```bash
    # (在 feat/lab2-movement 分支上)
    # 将我所有写了一半的、未提交的改动“藏”起来
    git stash
    ```

2.  **"切换" 到 `main` 并创建修复分支：**

    ```bash
    git checkout main
    git pull origin main
    git checkout -b fix/lab1-chat-bug
    ```

3.  **"修复" Bug 并合并：**

      * 在 `fix/lab1-chat-bug` 上修复 Bug。
      * `git commit -m "Fix: 修复聊天消息重复的Bug"`
      * `git push origin fix/lab1-chat-bug`
      * 去 GitHub 提 PR -\> 立即 Merge -\> 删除 `fix/` 分支。
      * **现在，`main` 分支是健康的了。**

4.  **"返回" Lab 2 并 "恢复" 工作：**

    ```bash
    # 1. 切换回我的 Lab 2 分支
    git checkout feat/lab2-movement

    # 2. [关键] 把 main 上的最新修复同步到我当前分支
    git pull origin main

    # 3. [关键] 把我之前“藏”起来的工作“取”回来
    git stash pop
    ```

5.  **完成！** 我现在又回到了 `lab2` 的开发中，代码没丢，而且 `lab1` 的 Bug 也被同步过来了。我可以继续安心开发 Lab 2。

-----

## 纠正我最大的误解：分支 (Branch) vs 标签 (Tag)

我终于搞懂了！

> **分支 (Branch)** 是一个**临时的、可变的“工作台”**。它用来承载**未来**的开发。
>
> **标签 (Tag)** 是一个**永久的、不可变的“版本快照”**。它用来标记**过去**的某个特定时刻。

当我的 Lab 1 合并到 `main` 之后，我应该在 `main` 上打一个 **Tag** 来标记这个“版本”。

```bash
# 确保在 main 上，并且是刚合并 Lab 1 的最新代码
git checkout main
git pull origin main

# 打一个 v0.1 的标签
git tag v0.1-lab1-chatroom

# 把这个标签推送到 GitHub
git push origin v0.1-lab1-chatroom
```

当我后来修复了 `lab1` 的 Bug 并合并回 `main` 后，`v0.1` 这个标签**依然指向那个有 Bug 的旧 Commit**。它是一张**历史照片**，无法被修改。

我应该做的是，在修复 Bug 后的新 Commit 上，打一个**新标签**：

```bash
git tag v0.1.1-lab1-hotfix
git push origin v0.1.1-lab1-hotfix
```

这就是为什么软件版本号是 `1.0.1`, `1.0.2`...

## 我的结论

GitHub Flow 真的非常简洁。它帮我厘清了混乱的思路。

  * **`main` 是唯一的真相。**
  * **`Branch` 是临时的过程。**
  * **`Pull Request` 是沟通的桥梁。**
  * **`Tag` 是永恒的里程碑。**

对于我的 MMO 项目，乃至未来所有的个人项目，这都将是我的标准工作流。

```