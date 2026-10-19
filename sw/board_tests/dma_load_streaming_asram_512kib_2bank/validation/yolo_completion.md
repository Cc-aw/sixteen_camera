# 合并候选的 HOST 与 CPU/RVV 完成边界

`activation_memory_commit()` 沿用 ASRAM 包的 `fence rw,rw`。本候选的 RocketCore、
DCache、Saturn Integration/HellaInterface/TLInterface/Mem 源码 SHA 与父 ASRAM
版本逐一相同，并已核对本候选生成上下文。实际 RTL SHA 见 yolo_completion.json。

Rocket 的 FENCE 等待 `backend_busy`、`trap_check_busy` 及 scalar memory ordered；
Saturn busy 包含向量 LSU、TL 和 HellaCache 在途状态，尚未提交的 store 仍由队列/ROB
保持 busy。ASRAM 写只有实际物理提交后才经两级流水和返回队列发布 AccessAck。

A1 的 Group 最终信用还要求物理事务排空、行重放完成、输出最终 token 可提交且无
fault；上下文、同步读 pending、输出队列及 fault 均计入 Group busy。实际 SPAD 写
队列继续计入 Gemmini busy，HOST/DRAIN/DONE 继续使用既有自主引擎边界。
CPU fence 只负责本 CPU/RVV 的存储完成，不能代替 Gemmini 排空。

软件只在全部引擎空闲时切换 arena，在 HOST PAD/copy 写入和完成回调后 resume。
没有为了每个 HOST 而全局排空三个 lane。当前仿真验证真实 Gemmini/ASRAM 与 HOST
隔离，但没有启动 Rocket/Saturn 执行该回调；此候选 CPU/RVV 实机证据仍为 NOT_RUN。
