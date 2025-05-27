#!/bin/bash

# 清空或创建new.txt文件
> new.txt

# 定义临时目录用于下载文件
TMP_DIR="./tmp_downloads"
mkdir -p "$TMP_DIR"

# 初始化变量
version=""
url_count=0
urls=()

# 逐行读取data.txt文件
while IFS= read -r line || [ -n "$line" ]; do
    # 跳过空行
    if [ -z "$line" ]; then
        continue
    fi
    
    # 检查是否是版本行
    if [[ $line == \#\#* ]]; then
        # 如果已经收集了一个完整的块，则处理它
        if [ ! -z "$version" ] && [ ${#urls[@]} -eq 3 ]; then
            echo "处理版本: $version"
            echo "## $version" >> new.txt
            
            # 处理每个URL
            for url in "${urls[@]}"; do
                # 从URL中提取文件名
                filename=$(basename "$url")
                filename=${filename//%20/ }  # 替换URL编码的空格
                
                echo "下载: $filename"
                # 下载文件
                if curl -L "$url" -o "$TMP_DIR/$filename" 2>/dev/null; then
                    # 计算SHA512校验和
                    sha512=$(sha512sum "$TMP_DIR/$filename" | cut -d' ' -f1)
                    
                    # 写入结果到new.txt
                    echo "$url" >> new.txt
                    echo "sha512:$sha512" >> new.txt
                else
                    echo "$url" >> new.txt
                    echo "sha512:下载失败 - 无法获取文件" >> new.txt
                fi
                
                # 删除下载的文件以节省空间
                rm -f "$TMP_DIR/$filename"
            done
            
            # 添加一个空行分隔不同版本
            echo "" >> new.txt
        fi
        
        # 开始新的块
        version=$(echo "$line" | sed 's/^## //')
        url_count=0
        urls=()
    elif [[ $line == http* ]]; then
        # 收集URL
        if [ $url_count -lt 3 ]; then
            urls[$url_count]="$line"
            ((url_count++))
        fi
    fi
done < "data.txt"

# 处理最后一个块
if [ ! -z "$version" ] && [ ${#urls[@]} -eq 3 ]; then
    echo "处理版本: $version"
    echo "## $version" >> new.txt
    
    for url in "${urls[@]}"; do
        filename=$(basename "$url")
        filename=${filename//%20/ }  # 替换URL编码的空格
        
        echo "下载: $filename"
        if curl -L "$url" -o "$TMP_DIR/$filename" 2>/dev/null; then
            sha512=$(sha512sum "$TMP_DIR/$filename" | cut -d' ' -f1)
            
            echo "$url" >> new.txt
            echo "sha512:$sha512" >> new.txt
        else
            echo "$url" >> new.txt
            echo "sha512:下载失败 - 无法获取文件" >> new.txt
        fi
        
        rm -f "$TMP_DIR/$filename"
    done
fi

# 清理临时目录
rmdir "$TMP_DIR"

echo "处理完成，结果已保存到new.txt"