# YOLOv5nu 整数参考数据

`hardware_integer_reference.npz` 保存当前硬件量化模型的 128 图 corpus，供 class reducer、DFL/BBox、NMS 和 image025 回归使用。JSON 文件记录整数参考与 SiLU LUT 数据。

来源与校验值见 `sw/models/yolov5nu/sources.lock.json`。生成向量使用 `tools/generate/generate_yolov5nu_class_reducer_vectors.py`，不需要训练环境或原始照片。
