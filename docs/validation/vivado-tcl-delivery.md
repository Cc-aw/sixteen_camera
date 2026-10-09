# Vivado Tcl 交付验收（2026-10-09）

基线为 `08cb230`。本次将 350 个 Vivado 工程/IP 生成文件取消 Git 跟踪，使用 `git rm --cached` 保留本地文件。XPR、XCI、BD、厂商 HDL、仿真网表和生成目录加入 `.gitignore`；仓库保留 RTL、约束、生产清单和重建 Tcl。

十个 standalone IP 的 Tcl 经 Vivado 2023.2 `write_ip_tcl` 导出，保留 VLNV、模块名和用户参数。DDR BD 继续由 `hw/vivado/create_design_1.tcl` 重建，补齐与原 BD 一致的 S00 时钟关联复位和两个 AXI net 名称。

`/tmp/sixteen-camera-tcl-handoff` 只含可提交源码，不含 XPR、XCI、BD、本机配置或历史生成物。`VIVADO_PROJECT` 指向仓库和 `build/` 之外的临时目录；IP/BD 和 `.srcs`、`.gen` 等输出由 Vivado 默认规则管理。源码交付不要求输出位置在 `build/`。

| 检查 | 结果 |
| --- | --- |
| dual16 / single4 生产清单 | PASS：120 RTL/MIF、10 IP Tcl、6 XDC |
| 十个新生成 IP 配置 | PASS：459 个 component parameter 值与原 XCI 完全一致 |
| DDR BD 重建 | PASS：组件、接口/端口参数、两类连线、地址映射均一致；忽略参数来源标签的元数据差异 |
| single4 RTL elaboration | PASS：独立源码副本从 Tcl 重建 `top_wrapper` |
| dual16 RTL elaboration | PASS：另一独立工程从 Tcl 重建 `top_wrapper` |
| IP OOC run 建立与重复 setup | PASS：elaboration 后切回正常 checkpoint 模式，重用 IP 并建立 26 个综合 run |
| 两种 bitstream 构建预检查 | PASS：不要求预先存在 XPR |
| 源码依赖完整性 | PASS：86 份快照、118 份固件依赖文件 |
| Tcl 完整性、Bash/Python 语法与更新文档链接 | PASS |

最终日志在本地 `build/reports/tcl-delivery/`。本次未执行完整综合/布局布线，也未连接或下载板卡；RTL、SoC 和固件源码未改动，既有软件/功能回归记录见 [目录重构验收](structure-refactor.md)。
