## SwiftNBT

SwiftNBT 是一个纯 Swift Package，用于读取和写入 NBT（Named Binary Tag）数据：

- 使用类型安全的 `NBTValue` 表示 NBT 标量、列表、Compound 和数组
- 支持无压缩和 gzip 压缩的 NBT 文档
- 提供独立的 `NBTDecoder` / `NBTEncoder` API
- 可用于 `level.dat`、`servers.dat`、Litematica 等 NBT 文件

## Usage

```swift
import Foundation
import SwiftNBT

let document = try NBTDecoder().decode(data)

let levelName = document["Data"]?.compoundValue?["LevelName"]?.stringValue

let encoded = try NBTEncoder().encode(document, compression: .gzip)
```

## Architecture

- `NBTValue` / `NBTDocument` — NBT 数据模型(类型安全)
- `NBTDecoder` — 将二进制 NBT 解码为 Swift 值
- `NBTEncoder` — 将 Swift 值编码为二进制 NBT
- `NBTCompression` — 管理无压缩、自动识别和 gzip 数据
- `NBTError` — 独立于宿主应用的解析和编码错误

## Build

```bash
swift build
swift test
```

### License

MIT License. 具体条款请见仓库中的 [LICENSE](./LICENSE) 文件。
