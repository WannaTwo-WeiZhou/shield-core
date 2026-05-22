# ui/pause — AI 指令

这里负责暂停界面和 GM 调试。

- 暂停状态只影响流程控制，不改核心玩法数据。
- GM 模式列出能力配置中的能力，并调用 `AbilityManager.select_ability()`。
- 不绕过正常能力获取流程，否则会漏掉管线重建和反馈。
