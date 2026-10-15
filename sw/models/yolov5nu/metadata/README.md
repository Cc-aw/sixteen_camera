# 模型来源记录

`import_manifest.json` 与 `import_v26_manifest.json` 保存原始导入来源、原 SHA、适配 SHA 和当时构建信息。
其 donor/source 字段是历史证据，不是构建依赖；目录迁移后的当前内容以模型根 `sources.lock.json` 为准。
两份当前模型锁已合并，之前的内容可从阶段提交和基线 tag 查询。`make check-deps` 校验保留的当前源码。
