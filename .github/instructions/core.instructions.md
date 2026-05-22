---
applyTo: "core/**"
---

# Core Instructions

- `core/` 只放跨场景基础设施，当前主要是 `EventBus` 和 `AbilityManager` Autoload。
- Autoload 不随场景重载清空；重开局状态必须通过 `AbilityManager.reset_for_new_run()` 处理。
- 新增跨模块通信优先使用 `EventBus` 信号，避免 feature 之间互相硬查节点。
- 不在 Autoload 中长期持有场景节点强依赖；场景重建后由节点重新注册。
