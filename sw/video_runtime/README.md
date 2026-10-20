# Independent video Runtime packages

The repository default is the board-validated S1 package. Root make targets and `make -C sw` select it.
Each package freezes its video/BSP/model sources and targets an explicit hardware ABI.

- [S1 DMA streaming + private ASRAM](dma_load_streaming_asram_s1_512kib_2bank/README.md):
  live 16-stream video admission, three autonomous Gemmini lanes, six PPU Head slots.
