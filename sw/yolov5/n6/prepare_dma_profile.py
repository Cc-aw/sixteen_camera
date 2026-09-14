#!/usr/bin/env python3
"""I: original v8 software generator. P: keep v6/v7 math/tiles, add profiling revision.
O: isolated software build directory. A: 王志瑞. T: 2026-09-11.
"""
import prepare
prepare.OUT=prepare.ROOT/f'build/yolov5nu_n6_dma_profile_{prepare.VARIANT}'
original=prepare.transform
def transform(source,planner):
    return original(source,planner).replace(f'revision=n6_port_v8_ddr_{prepare.VARIANT}',
                                           f'revision=n6_port_dma_profile_{prepare.VARIANT}')
prepare.transform=transform
if __name__=='__main__': prepare.main()
