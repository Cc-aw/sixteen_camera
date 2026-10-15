# 模型接口

当前模型的 yolo32、independent、PPU、诊断、memory kernels 和平台 shim 头集中在此。
`runtime/` 保留原冻结轨迹接口默认值；原生生成输入的相邻头仍位于 `../frozen/native/`。
生产编译显式锁定三个 DIM32 worker，不能通过某份冻结头的默认值判断交付配置。
接口由视频/基准共享，Host 与原生测试分别在 `tests/host`、`tests/model/yolov5nu`。
