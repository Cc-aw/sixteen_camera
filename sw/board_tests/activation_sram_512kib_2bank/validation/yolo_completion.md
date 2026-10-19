# 本次硬件上的 CPU／RVV 完成边界

本移植绑定 `activation_memory_commit()` 的平台回调，使用 `fence rw,rw`。该绑定仅针对
硬件 ID `e684b3d0484a9424`，不是以通用 RISC-V 规则推测独立向量路径的实现。

已沿本次生成上下文核对以下来源及冻结 RTL，SHA 清单为 `yolo_completion.json`：

1. RocketCore.scala:427–430 在 FENCE 译码处等待 Saturn `backend_busy` 与
   `trap_check_busy`；scalar memory 顺序还由 `io.dmem.ordered` 保证。
2. Saturn rocket/Integration.scala:59 将后端、向量 LSU、独立 TL 和 HellaCache
   的未完成状态合并进 `backend_busy`。
3. mem/TLInterface.scala:33–37 从 A 接受到 D 返回维护 inflight，reader／writer
   两路都计入 `TLSplitInterface.mem_busy`。
4. rocket/HellaInterface.scala:85–93 从进入请求队列到完成响应维护 inflight，因此
   等待也覆盖尚在 HellaCache 队列中的访问。
5. mem/Mem.scala:193–205,399–408 在 store_ack 经 ROB／SIFQ 完成最后一段后才清除
   对应 SIQ valid；尚未发出的 store 请求不会在 TL inflight=0 的间隙丢失 busy。
6. ActivationSramTL.scala:94–99 经两级管线及响应队列返回 D。非法请求不启动物理
   操作，合法写在返回 AccessAck 之前提交到共享物理存储。

冻结 Rocket.sv、SaturnRocketUnit.sv、TLSplitInterface.sv、TLInterface.sv、
HellaCacheInterface.sv、VectorMemUnit.sv、DCache.sv 和三路 ActivationSramPort 的
SHA 与 bitstream 的 `build_input_sha256.json` 相符；上述 Scala SHA 与生成上下文
的 `effective_scala` 相符。

回调在初始化、六次原生 PAD/copy HOST 完成后使用。依赖这些写入的 frontend resume
只在回调成功后执行。HOST 本身沿用原生 Gemmini 完成边界；不以 CPU fence 替代
自主引擎的 HOST／DONE。其他 lane 仍按原来的自主调度执行。

`asram_02` 已对该比特流实际执行 RVV→本地→DMA 和 DMA→本地→RVV 搬运并通过；
本次完整 YOLO 推理尚未下板。来源／RTL 连接和定向搬运支持这份平台绑定，不能替代
完整模型和长期压力条件下的板测结果。
