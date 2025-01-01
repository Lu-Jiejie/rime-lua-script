# Rime Lua Script

一些 [Rime](https://rime.im/) 的 Lua 脚本。

## Cloud Pinyin

Rime 云输入方案。

基于 [hchunhui/librime-cloud](https://github.com/hchunhui/librime-cloud).

云输入选词自动加入用户词库。

### 安装

1. 使用最新的 [`rime.dll`](https://github.com/hchunhui/librime-lua/actions) 替换 Rime 安装目录的下的 `rime.dll`。

2. 从 [librime-cloud/releases](https://github.com/hchunhui/librime-cloud/releases) 获取对应平台的 `simplehttp.dll` ，并放入 Rime 安装目录下。

3. 将 [lua/cloud_pinyin](lua/cloud_pinyin) 目录下的文件复制到 Rime 用户目录下的 `lua` 目录中。

4. 在对应的 `xxx.schema.yaml` 文件中添加如下配置：

```yaml
# 输入引擎
engine:
  processors:
    - lua_processor@*cloud_pinyin*processor

  translators:
    - lua_translator@*cloud_pinyin*translator
```
