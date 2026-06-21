#!/usr/bin/env python3
"""处理 sprite-resource SMB1 NES Overworld panel 1 PNG。

作用：
  原图 y=0..32 是"地平线紫横条 + 过渡天空"，拉伸到桌面 widget 全屏后会变成
  屏幕顶部一条突兀的实色蓝紫色横条。本脚本把这 32 像素替换为下方的主棋盘格
  天空纹理，让 panel 1 拉伸到全屏后视觉连贯。

使用：
  python3 tools/process_panel1.py <input.png> <output.png>
  默认处理 assets/backgrounds/smb_background_overworld.png
"""

import sys
from pathlib import Path

from PIL import Image

DEFAULT_IN = "assets/backgrounds/smb_background_overworld.png"
TOP_STRIP_HEIGHT = 32  # 替换 y=0..32
SOURCE_OFFSET = 32  # 从 y=32..64 复制纹理到顶部


def process(input_path: Path, output_path: Path) -> None:
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    print(f"原图: {w}x{h}")

    # 把 y=0..TOP_STRIP_HEIGHT 替换为 y=SOURCE_OFFSET..SOURCE_OFFSET+TOP_STRIP_HEIGHT
    for y in range(TOP_STRIP_HEIGHT):
        for x in range(w):
            src = img.getpixel((x, y + SOURCE_OFFSET))
            img.putpixel((x, y), src)

    img.save(output_path)
    print(f"已保存到: {output_path}")


def main() -> None:
    args = sys.argv[1:]
    if len(args) == 0:
        in_path = Path(DEFAULT_IN)
        out_path = in_path
    elif len(args) == 1:
        in_path = Path(args[0])
        out_path = in_path
    elif len(args) == 2:
        in_path = Path(args[0])
        out_path = Path(args[1])
    else:
        print(__doc__)
        sys.exit(1)

    if not in_path.exists():
        print(f"错误: 找不到 {in_path}", file=sys.stderr)
        sys.exit(1)

    process(in_path, out_path)


if __name__ == "__main__":
    main()