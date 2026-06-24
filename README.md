# Skills

个人的 [Agent Skills](https://agentskills.io/home) 集合 —— 基于 Markdown 的可复用指令，用于教会 AI 代理执行特定任务。

## 安装

```bash
pnpx skills add lvjiaxuan/skills --skill='*'
```

或全局安装所有技能：

```bash
pnpx skills add lvjiaxuan/skills --skill='*' -g
```

了解更多 CLI 用法，请访问 [skills](https://github.com/vercel-labs/skills)。

## 技能列表

| 技能 | 描述 | 安装命令 |
|------|------|----------|
| [git-history-cleanup](skills/git-history-cleanup) | 清理混乱的 Git 提交历史 —— 合并无意义的提交（WIP、chaos、update），通过非交互式 rebase 重新组织和修改提交信息 | `pnpx skills add lvjiaxuan/skills --skill=git-history-cleanup` |
