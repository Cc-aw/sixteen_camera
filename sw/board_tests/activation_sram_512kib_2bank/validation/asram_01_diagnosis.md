# asram_01 空洞判据定位

硬件 ID `e684b3d0484a9424`，原软件 ID
`35d0888c851198765aaf0b6b2db6f3d2b44f82a7bd813863eb40b2bff673c974`。
原日志、manifest、ELF 与反汇编保存在 `logs/asram_01/`，没有覆盖原始串口数据。

板上已观测：三块 SRAM 的两轮全容量标量测试（6 项）通过，lane 0 部分写和真实 RVV
全容量往返（2 项）通过；第一次读取 `0x20240000` 后软件报告
`hole_did_not_trap,expected=5,actual=0`。这表示没有触发预期异常，不是 mcause=0。
原日志没有记录此访问的 denied 计数，不能仅凭它判断硬件错误响应是否丢失。

冻结构建关联：`bitstream_e684b3d0484a9424_physical_04/state.json` 指向
`candidate_03/gen-collateral`。已将 DCache、三路 ActivationSramPort 及其请求／响应
队列的 SHA-256 与同次 `build_input_sha256.json` 核对。参考 DCache.scala 也与
`GENERATION_CONTEXT.json` 的 effective Scala SHA 相符。

根因是原测试把总线拒绝当成同步 CPU 异常：

- `DCache.scala:931` 的 `io.cpu.s2_xcpt` 来自 TLB／PMA／PMP 检查。
- `DCache.scala:946–961` 在 uncached AccessAckData 返回后回放读数据，没有将
  D.denied／D.corrupt 加到同步 access-fault 信号。
- `DCache.scala:1127` 将 denied／corrupt 送到总线错误报告；当前配置没有实例化
  BusErrorUnit。冻结 `DCache.sv:1402–1407` 的异常及回放赋值也证实这一点。
- `ActivationSramTL.scala:67–75,92–99` 对窗口尾部判非法，禁止物理操作，产生
  denied，错误 Get 同时返回 corrupt 和零数据。

对冻结的三路端口运行定向 RTL 仿真：每路检查最后合法 8 字节地址的读写，以及
首个空洞／窗口末尾的读写。18 项通过，其中 12 项非法请求全部 denied；检查了
Get 的 corrupt、零数据、D 背压保持、accepted=retired=1、outstanding=0 和零物理
读写。使用真实生成端口和队列，但未执行 CPU 或物理 URAM；不能替代板上拒绝计数。
详细 SHA 和仿真输出在 `build/hole_rtl/`。

schema 2 修复将每次 CPU 空洞访问前清零统计，访问后快照服务与 DMA 端口。要求服务
端口恰好一项请求完成，Get／Put 类型正确，denied=1、物理读写=0、无输入 corrupt；
DMA 端口无该请求，错误读返回零。总计必须有 12 条完整 HOLE 记录和 denied=12。
任何意外 trap、正常应答、物理别名访问或缺失计数都继续判失败。

结论：已确认同步异常判据不适用于本次 CPU，并修复板测软件。原板测仍为失败／未完成；
修订软件尚待重新下板，当前硬件不能据此标记为全部通过。没有重建或下载比特流。
