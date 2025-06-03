#!/usr/bin/env python3

import os
import re
import hashlib
import requests
from urllib.parse import unquote
from pathlib import Path

# 清空或创建 new.txt 文件
with open('new.txt', 'w', encoding='utf-8') as f:
    pass

# 创建临时目录
tmp_dir = Path('./tmp_downloads')
tmp_dir.mkdir(exist_ok=True)

# 读取 data.txt 文件
with open('data.txt', 'r', encoding='utf-8') as f:
    content = f.read()

# 分割成版本块
version_blocks = re.split(r'\n\s*\n', content)

for block in version_blocks:
    if not block.strip():
        continue

    lines = block.strip().split('\n')
    if not lines or not lines[0].startswith('##'):
        continue

    # 提取版本号
    version = lines[0].replace('##', '').strip()
    print(f"处理版本：{version}")

    # 提取 URL
    urls = [line.strip() for line in lines[1:] if line.strip().startswith('http')]
    if not urls:
        print(f"警告：版本 {version} 没有找到任何 URL")
        continue

    # 写入版本号到 new.txt
    with open('new.txt', 'a', encoding='utf-8') as f:
        f.write(f"## {version}\n")

    # 处理每个 URL
    for url in urls:
        # 从 URL 中提取文件名
        filename = unquote(os.path.basename(url))
        print(f"下载：{filename}")

        file_path = tmp_dir / filename

        try:
            # 下载文件
            response = requests.get(url, stream=True, timeout=60)
            response.raise_for_status()  # 如果请求失败则抛出异常

            # 保存文件
            with open(file_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            # 获取文件大小并在终端显示
            file_size = os.path.getsize(file_path)
            file_size_mb = round(file_size / (1024 * 1024), 2)

            # 检查文件大小是否太小，只在终端显示警告
            if file_size_mb < 1:
                print(f"警告：文件 {filename} 大小只有 {file_size_mb} MB，可能不是安装程序")
            else:
                print(f"文件大小：{file_size_mb} MB")

            # 计算 SHA512 校验和
            sha512 = hashlib.sha512()
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    sha512.update(chunk)

            # 写入结果到 new.txt（不包含文件大小和警告信息）
            with open('new.txt', 'a', encoding='utf-8') as f:
                f.write(f"{url}\n")
                f.write(f"sha512:{sha512.hexdigest()}\n")

        except Exception as e:
            # 下载失败
            print(f"下载失败：{str(e)}")
            with open('new.txt', 'a', encoding='utf-8') as f:
                f.write(f"{url}\n")
                f.write(f"sha512:下载失败 - {str(e)}\n")

        # 删除下载的文件以节省空间
        if file_path.exists():
            file_path.unlink()

    # 添加一个空行分隔不同版本
    with open('new.txt', 'a', encoding='utf-8') as f:
        f.write("\n")

# 清理临时目录
if tmp_dir.exists():
    try:
        tmp_dir.rmdir()
    except OSError:
        pass

print("处理完成，结果已保存到 new.txt")
