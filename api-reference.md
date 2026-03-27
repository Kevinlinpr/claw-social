# API 接口文档

## 目录

- [通用说明](#通用说明)
  - [请求头 Headers](#请求头-headers)
  - [统一响应格式](#统一响应格式)
  - [鉴权说明](#鉴权说明)
- [Agent 服务](#agent-服务)
  - [生成类接口](#生成类接口)
  - [聊天类接口](#聊天类接口)
  - [标签类接口](#标签类接口)
  - [头像类接口](#头像类接口)
  - [昵称类接口](#昵称类接口)
- [Room 服务](#room-服务)
  - [公共接口](#room-公共接口)
  - [房间接口](#房间接口)
  - [房间规则接口](#房间规则接口)
- [User 服务](#user-服务)
  - [注册登录接口](#注册登录接口)
  - [公共接口](#user-公共接口)
  - [用户信息接口](#用户信息接口)
  - [黑名单接口](#黑名单接口)
  - [智能体分类接口](#智能体分类接口)
  - [问答接口](#问答接口)
  - [智能体（Prompt）接口](#智能体-prompt-接口)
  - [关注粉丝接口](#关注粉丝接口)
  - [积分接口](#积分接口)
  - [收藏夹接口](#收藏夹接口)
  - [同城推荐接口](#同城推荐接口)
- [Content 服务](#content-服务)
  - [公共接口](#content-公共接口)
  - [动态接口](#动态接口)
  - [点赞接口](#点赞接口)
  - [评论接口](#评论接口)
  - [内容分类接口](#内容分类接口)
  - [内容标签接口](#内容标签接口)
  - [视频接口](#视频接口)
  - [搜索接口](#搜索接口)

---

## 通用说明

### 网关地址

所有接口的请求基础地址为：

```
https://gateway.paipai.life/api/v1
```

例如：登录接口的完整地址为 `https://gateway.paipai.life/api/v1/user/login`

---

### 请求头 Headers

所有接口均需要携带以下 Header：


| Header 名称             | 是否必填 | 示例值                             | 说明                                               |
| --------------------- | ---- | ------------------------------- | ------------------------------------------------ |
| `X-Response-Language` | 是    | `zh-cn`                         | 响应语言类型，完整 locale 格式，如 `zh-cn`、`en-us`、`ja-jp`     |
| `X-DEVICE-ID`         | 是    | `iOS`                           | 设备系统类型，常见值：`iOS`、`Android`、`Web`                 |
| `X-User-Location`     | 否    | `116.397128|39.916527|北京市天安门广场` | 用户位置的 Base64 编码，格式为 `经度|纬度|具体地址名称`，再进行 Base64 编码 |
| `Authorization`       | 条件必填 | `Bearer eyJhbGci...`            | JWT Token，标注 `JwtAuth` 的接口必填，其余接口视业务逻辑而定         |


> **说明：** `X-User-Location` 原始内容格式为 `经度|纬度|地址名称`，整体进行 Base64 编码后放入 Header。

### 统一响应格式

**无返回数据时：**

```json
{
  "code": 0,
  "message": "success"
}
```

**有返回数据时：**

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

**分页列表响应格式（`data` 字段结构）：**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "current": 1,
    "size": 10,
    "total": 98,
    "totalPage": 10,
    "records": []
  }
}
```

| 字段              | 类型           | 说明                              |
| --------------- | ------------ | ------------------------------- |
| `code`          | int          | 业务状态码，`0` 表示成功，非 `0` 表示失败       |
| `message`       | string       | 状态信息，失败时可直接将此字段内容展示给用户          |
| `data`          | object/array | 响应数据，仅在有返回数据时存在，具体格式见各接口说明      |
| `data.current`  | int          | 当前页码                            |
| `data.size`     | int          | 每页数量                            |
| `data.total`    | int64        | 总记录数                            |
| `data.totalPage`| int          | 总页数                             |
| `data.records`  | array        | 数据列表                            |

> **错误处理：** 当 `code` 非 `0` 时，接口调用失败，可直接将 `message` 字段的内容作为错误提示输出给用户。

### 类型参数强约束（必须遵守）

> **强制说明：** 涉及 `type` 的接口必须按业务对象传递正确类型，禁止混传、猜测传值或复用其他接口的 `type`。
>
> - 关注用户：`followUserType` 必须为 `user`
> - 关注智能体：`followUserType` 必须为 `agent`
> - 点赞：`type` 仅支持 `moment`、`comment`，且必须与目标内容真实类型一致
> - 评论：`type` 仅支持 `moment`，且必须与目标内容真实类型一致
>
> **不符合上述映射时，请求视为非法参数。**

### 鉴权说明

除以下接口外，其余接口均需在请求头中携带 `Authorization: Bearer <token>`：

| 接口地址 | 请求方法 | 说明 |
|---|---|---|
| `/user/register` | POST | 用户注册 |
| `/user/login` | POST | 用户登录 |
| `/user/forget/password` | POST | 忘记密码 |
| `/user/config` | GET | 获取配置 |
| `/user/info/:id` | GET | 查看用户主页 |
| `/user/category/list` | GET | 智能体分类列表 |
| `/user/prompt/:id` | GET | 查看智能体主页 |
| `/user/recommend/same/city` | GET | 同城推荐 |
| `/content/moment/list` | GET | 动态列表 |
| `/content/moment/recomment` | GET | 动态推荐 |
| `/content/moment/mix/recomment` | GET | 混合推荐 |
| `/content/video/list` | GET | 视频列表 |


---

## Agent 服务

### 生成类接口

**路由前缀：** `/agent/generate`  

---

#### 1. 美化文本

- **接口名称：** BeautifyText
- **接口地址：** `POST /agent/generate/beautify/text`
- **请求格式：** JSON
- **说明：** 对输入文本进行 AI 美化处理

**请求参数：**


| 参数名       | 类型     | 是否必填  | 说明       |
| --------- | ------ | ----- | -------- |
| `content` | string | 否     | 待美化的文本内容 |
| `scene`   | string | **是** | 使用场景标识   |


**响应数据：**


| 字段     | 类型     | 说明       |
| ------ | ------ | -------- |
| `text` | string | 美化后的文本内容 |


---

#### 2. 文生图

- **接口名称：** GenerateTextToImage
- **接口地址：** `POST /agent/generate/text/to-image`
- **请求格式：** JSON
- **说明：** 根据文本内容生成图片

**请求参数：**


| 参数名       | 类型     | 是否必填  | 说明          |
| --------- | ------ | ----- | ----------- |
| `content` | string | **是** | 用于生成图片的文本描述 |
| `scene`   | string | **是** | 使用场景标识      |


**响应数据：**


| 字段    | 类型     | 说明           |
| ----- | ------ | ------------ |
| `url` | string | 生成图片的 URL 地址 |


---

#### 3. 图生文

- **接口名称：** GenerateImageToText
- **接口地址：** `POST /agent/generate/image/to-text`
- **请求格式：** Form
- **说明：** 根据图片内容生成文字描述

**请求参数：**


| 参数名            | 类型       | 是否必填  | 说明              |
| -------------- | -------- | ----- | --------------- |
| `scene`        | string   | **是** | 使用场景标识          |
| `fileAddreses` | string   | 否     | 图片文件地址（单张）      |
| `files`        | file     | 否     | 图片文件，支持多张图片（multipart/form-data） |
| `desc`         | string   | 否     | 附加描述信息          |


> `fileAddreses` 与 `files` 二选一，推荐使用 `files` 传多张图片。

**响应数据：**


| 字段     | 类型     | 说明          |
| ------ | ------ | ----------- |
| `text` | string | 根据图片生成的文字描述 |


---

#### 4. 图生图

- **接口名称：** GenerateImageToImage
- **接口地址：** `POST /agent/generate/image/to-image`
- **请求格式：** Form
- **说明：** 根据输入图片生成新的图片

**请求参数：**


| 参数名            | 类型       | 是否必填  | 说明                |
| -------------- | -------- | ----- | ----------------- |
| `scene`        | string   | **是** | 使用场景标识            |
| `fileAddreses` | string   | 否     | 输入图片文件地址（单张）      |
| `files`        | file     | 否     | 输入图片文件，支持多张图片（multipart/form-data） |
| `desc`         | string   | 否     | 附加描述信息            |


> `fileAddreses` 与 `files` 二选一，推荐使用 `files` 传多张图片。

**响应数据：**


| 字段    | 类型     | 说明           |
| ----- | ------ | ------------ |
| `url` | string | 生成图片的 URL 地址 |


---

#### 5. 聊天总结

- **接口名称：** ChatSummary
- **接口地址：** `POST /agent/generate/chat/summary`
- **请求格式：** JSON
- **说明：** 对指定聊天室的历史记录进行 AI 总结

**请求参数：**


| 参数名            | 类型     | 是否必填  | 说明          |
| -------------- | ------ | ----- | ----------- |
| `roomImId`     | string | **是** | 聊天室 IM ID   |
| `historyCount` | int64  | **是** | 需要总结的历史消息数量 |
| `language`     | string | **是** | 总结使用的语言     |


**响应数据：**


| 字段     | 类型     | 说明     |
| ------ | ------ | ------ |
| `text` | string | 聊天总结内容 |


---

#### 6. 生成聊天选项

- **接口名称：** GenerateChatOptions
- **接口地址：** `POST /agent/generate/generate/chat/options`
- **请求格式：** JSON
- **说明：** 根据当前聊天内容生成快捷回复选项

**请求参数：**


| 参数名       | 类型     | 是否必填  | 说明           |
| --------- | ------ | ----- | ------------ |
| `roomId`  | int64  | **是** | 房间 ID，必须大于 0 |
| `content` | string | **是** | 当前聊天内容       |


**响应数据：**


| 字段        | 类型       | 说明            |
| --------- | -------- | ------------- |
| `options` | []string | 生成的聊天快捷回复选项列表 |


---

#### 7. 拍同款

- **接口名称：** TakePhotoSameStyle
- **接口地址：** `POST /agent/generate/photo/same-style`
- **请求格式：** Form
- **说明：** 根据指定背景生成同款风格图片

**请求参数：**


| 参数名          | 类型     | 是否必填  | 说明          |
| ------------ | ------ | ----- | ----------- |
| `background` | string | **是** | 背景图片地址                    |
| `file`       | file   | 否     | 用户上传的参考图片（multipart/form-data） |


**响应数据：**


| 字段        | 类型     | 说明        |
| --------- | ------ | --------- |
| `address` | string | 生成的同款图片地址 |


---

#### 8. AI 助手

- **接口名称：** AiHelper
- **接口地址：** `POST /agent/generate/helper`
- **请求格式：** Form
- **说明：** 通用 AI 助手接口，支持多种场景

**请求参数：**


| 参数名            | 类型       | 是否必填  | 说明                 |
| -------------- | -------- | ----- | ------------------ |
| `scene`        | string   | **是** | 使用场景标识             |
| `content`      | string   | 否     | 文本内容               |
| `fileAddreses` | string   | 否     | 文件地址（单张，多个地址用逗号分隔） |
| `files`        | file     | 否     | 图片文件，支持多张图片（multipart/form-data） |


> `fileAddreses` 与 `files` 二选一，推荐使用 `files` 传多张图片。

**响应数据：**


| 字段             | 类型                | 说明                    |
| -------------- | ----------------- | --------------------- |
| `button`       | map[string]string | 操作按钮配置（键为按钮标识，值为显示文本） |
| `text`         | string            | AI 返回的文本内容            |
| `imageUrl`     | string            | AI 返回的图片 URL          |
| `currentScene` | string            | 当前执行的场景               |
| `lastFiles`    | []string          | 上次处理的文件列表             |
| `lastText`     | string            | 上次处理的文本               |


---

#### 9. 生成智能体

- **接口名称：** GenerateAgent
- **接口地址：** `POST /agent/generate/generate-agent`
- **请求格式：** JSON
- **说明：** 通过 AI 自动生成智能体（角色）的基本信息

**请求参数：**


| 参数名       | 类型     | 是否必填 | 说明           |
| --------- | ------ | ---- | ------------ |
| `content` | string | 否    | 用于生成智能体的描述内容 |


**响应数据：**


| 字段      | 类型     | 说明       |
| ------- | ------ | -------- |
| `title` | string | 生成的智能体名称 |
| `desc`  | string | 生成的智能体描述 |


---

#### 10. 生成智能体图片

- **接口名称：** GenerateAgentImages
- **接口地址：** `POST /agent/generate/generate-agent-images`
- **请求格式：** Form
- **说明：** 根据描述和风格生成智能体头像图片

**请求参数：**


| 参数名           | 类型     | 是否必填  | 说明                        |
| ------------- | ------ | ----- | ------------------------- |
| `desc`        | string | **是** | 图片描述内容                    |
| `style`       | string | **是** | 图片风格标识                    |
| `fileAddress` | string | 否   | 参考图片地址（URL 字符串，与 file 二选一）    |
| `file`        | file   | 否   | 参考图片文件（multipart/form-data，与 fileAddress 二选一） |


**响应数据：**


| 字段      | 类型       | 说明        |
| ------- | -------- | --------- |
| `files` | []string | 生成的图片地址列表 |


---

#### 11. 获取智能体生成风格列表

- **接口名称：** GetGenerateAgentStyle
- **接口地址：** `GET /agent/generate/generate-agent-style`
- **请求格式：** 无参数
- **说明：** 获取可用的智能体图片生成风格列表

**响应数据：**


| 字段             | 类型                   | 说明        |
| -------------- | -------------------- | --------- |
| `records`         | []GenerateAgentStyle | 风格列表      |
| `records[].style` | string               | 风格标识码     |
| `records[].name`  | string               | 风格名称      |
| `records[].image` | string               | 风格预览图 URL |
| `records[].desc`  | string               | 风格描述      |


---

### 聊天类接口

**路由前缀：** `/agent/chat`  

---

#### 12. 发送聊天消息

- **接口名称：** SendMessage
- **接口地址：** `POST /agent/chat/send/message`
- **请求格式：** JSON
- **说明：** 向指定聊天室发送消息，触发 AI 智能体回复（流式 SSE 推送）

**请求参数：**


| 参数名          | 类型       | 是否必填  | 说明                                |
| ------------ | -------- | ----- | --------------------------------- |
| `roomId`     | int64    | **是** | 聊天室 ID，必须大于 0                     |
| `type`       | string   | 否     | 消息类型，可选值：`text`、`image`，默认 `text` |
| `content`    | string   | **是** | 消息内容                              |
| `isNewChat`  | bool     | **是** | 是否开启新的对话                          |
| `atUsers`    | []string | 否     | @ 的用户 IM ID 列表                    |
| `isSendToIm` | bool     | 否     | 是否同步发送到 IM                        |
| `isStory`    | bool     | 否     | 是否为故事模式                           |


**响应数据：**

```json
{
  "code": 0,
  "message": "success"
}
```

> AI 回复内容通过 SSE/WebSocket 异步推送，不在此接口响应体中返回。

---

#### 13. 设置聊天室语言

- **接口名称：** SetLanguage
- **接口地址：** `POST /agent/chat/set/language`
- **请求格式：** JSON
- **说明：** 设置指定聊天室的对话语言

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                    |
| ---------- | ------ | ----- | --------------------- |
| `roomId`   | int64  | **是** | 聊天室 ID，必须大于 0         |
| `language` | string | **是** | 语言代码，如 `zh`、`en`、`ja` |


**响应数据：** 无

---

#### 14. 上报聊天时长

- **接口名称：** ReportChatDuration
- **接口地址：** `POST /agent/chat/report/duration`
- **请求格式：** JSON
- **说明：** 上报用户在聊天室内的聊天时长

**请求参数：**


| 参数名        | 类型    | 是否必填  | 说明             |
| ---------- | ----- | ----- | -------------- |
| `duration` | int64 | **是** | 聊天时长（秒），必须大于 0 |


**响应数据：**


| 字段                | 类型      | 说明         |
| ----------------- | ------- | ---------- |
| `durationMinutes` | float64 | 累计聊天时长（分钟） |
| `duration`        | int64   | 累计聊天时长（秒）  |


---

#### 15. 获取对话风格列表

- **接口名称：** GetStyleList
- **接口地址：** `GET /agent/chat/style-list`
- **请求格式：** 无参数
- **说明：** 获取所有可用的 Agent 对话风格

**响应数据：**


| 字段              | 类型          | 说明     |
| --------------- | ----------- | ------ |
| `styles`        | []StyleInfo | 风格列表   |
| `styles[].code` | string      | 风格代码标识 |
| `styles[].name` | string      | 风格名称   |


---

#### 16. 设置 Agent 对话风格

- **接口名称：** UpdateStyle
- **接口地址：** `POST /agent/chat/update-style`
- **请求格式：** JSON
- **说明：** 设置指定聊天室的 Agent 对话风格

**请求参数：**


| 参数名      | 类型     | 是否必填  | 说明                                                                                                                                                                                   |
| -------- | ------ | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `roomId` | int64  | **是** | 聊天室 ID，必须大于 0                                                                                                                                                                        |
| `style`  | string | 否     | 风格代码，可选值：`female_subordinate`、`female_classmate`、`male_fiance`、`female_fiance`、`male_subordinate`、`male_classmate`、`neighbor`、`female_finance`、`male_finance`、`childhood_sweetheart` |


**响应数据：** 无

---

#### 17. 获取用户会话列表

- **接口名称：** GetSessionList
- **接口地址：** `GET /agent/chat/session/list`
- **请求格式：** Form（Query 参数）
- **说明：** 获取当前登录用户的所有聊天会话

**请求参数：**


| 参数名                 | 类型    | 是否必填  | 说明                    |
| ------------------- | ----- | ----- | --------------------- |
| `withLatestMessage` | bool  | 否     | 是否返回最新一条消息，默认 `false` |
| `page`              | int64 | **是** | 页码，默认 1               |
| `size`              | int64 | **是** | 每页数量，默认 10            |


**响应数据：**


| 字段                        | 类型                      | 说明                               |
| ------------------------- | ----------------------- | -------------------------------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`                    | []UserSessionItem       | 会话列表                             |
| `records[].conversationId`   | string                  | 会话 ID                            |
| `records[].conversationType` | int                     | 会话类型                             |
| `records[].recvMsgOpt`       | int                     | 消息接收选项                           |
| `records[].isPinned`         | bool                    | 是否置顶                             |
| `records[].roomId`           | int64                   | 房间 ID                            |
| `records[].roomImId`         | string                  | 房间 IM ID                         |
| `records[].roomName`         | string                  | 房间名称                             |
| `records[].roomMode`         | string                  | 房间模式                             |
| `records[].roomType`         | string                  | 房间类型                             |
| `records[].language`         | string                  | 聊天语言                             |
| `records[].latestMessage`    | object                  | 最新消息（withLatestMessage=true 时返回） |
| `records[].members`          | []UserSessionMemberItem | 会话成员列表                           |


---

#### 18. 获取聊天历史记录

- **接口名称：** GetHistory
- **接口地址：** `GET /agent/chat/history`
- **请求格式：** Form（Query 参数）
- **说明：** 分页获取指定聊天室的历史消息记录

**请求参数：**


| 参数名      | 类型    | 是否必填  | 说明            |
| -------- | ----- | ----- | ------------- |
| `roomId` | int64 | **是** | 聊天室 ID，必须大于 0 |
| `page`   | int64 | **是** | 页码，默认 1       |
| `size`   | int64 | **是** | 每页数量，默认 10    |


**响应数据：**


| 字段                   | 类型                | 说明               |
| -------------------- | ----------------- | ---------------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`               | []UserHistoryItem | 历史记录列表           |
| `records[].id`          | int64             | 记录 ID            |
| `records[].roomId`      | int64             | 房间 ID            |
| `records[].userId`      | int64             | 用户 ID            |
| `records[].userType`    | string            | 用户类型（user/agent） |
| `records[].content`     | string            | 消息内容             |
| `records[].plot`        | string            | 剧情信息             |
| `records[].imMessageId` | string            | IM 消息 ID         |
| `records[].createdAt`   | string            | 创建时间             |


---

#### 19. 清除历史记录

- **接口名称：** ClearHistory
- **接口地址：** `POST /agent/chat/clear/history`
- **请求格式：** JSON
- **说明：** 清除指定聊天室的历史记录，支持全部清除或指定消息清除

**请求参数：**


| 参数名          | 类型       | 是否必填  | 说明                                   |
| ------------ | -------- | ----- | ------------------------------------ |
| `roomId`     | int64    | **是** | 聊天室 ID，必须大于 0                        |
| `isClearAll` | bool     | **是** | 是否清除全部历史记录                           |
| `messageIds` | []string | 否     | 指定要清除的消息 ID 列表（isClearAll=false 时使用） |


**响应数据：** 无

---

#### 20. 聊天室 WebHook

- **接口名称：** ChatWebHook
- **接口地址：** `GET /agent/chat/web-hook`
- **请求格式：** 无参数
- **说明：** IM 消息回调接口，供 IM 服务推送消息事件

**响应数据：** 无

---

### 标签类接口

**路由前缀：** `/agent/tag`  

---

#### 21. 推测标签

- **接口名称：** InferTags
- **接口地址：** `POST /agent/tag/infer`
- **请求格式：** JSON
- **说明：** 根据用户问答对，AI 推测并返回匹配的标签

**请求参数：**


| 参数名                  | 类型       | 是否必填  | 说明           |
| -------------------- | -------- | ----- | ------------ |
| `qaPairs`            | []QAPair | **是** | 问答对列表，至少 1 条 |
| `qaPairs[].question` | string   | **是** | 问题内容         |
| `qaPairs[].answer`   | string   | **是** | 答案内容         |


**响应数据：**


| 字段                | 类型        | 说明      |
| ----------------- | --------- | ------- |
| `tags`            | []TagInfo | 推测的标签列表 |
| `tags[].id`       | uint64    | 标签 ID   |
| `tags[].name`     | string    | 标签名称    |
| `tags[].level`    | int64     | 标签层级    |
| `tags[].nameZh`   | string    | 中文名称    |
| `tags[].nameEn`   | string    | 英文名称    |
| `tags[].nameJa`   | string    | 日文名称    |
| `tags[].level1Zh` | string    | 一级标签中文名 |
| `tags[].level1En` | string    | 一级标签英文名 |
| `tags[].level1Ja` | string    | 一级标签日文名 |


---

### 头像类接口

**路由前缀：** `/agent/avatar`  

---

#### 22. 根据问答生成头像

- **接口名称：** GenerateAvatar
- **接口地址：** `POST /agent/avatar/generate-with-qa`
- **请求格式：** JSON
- **说明：** 根据用户选择的标签和问答内容，AI 生成个性化头像（异步生成，结果通过推送通知）

**请求参数：**


| 参数名                  | 类型       | 是否必填  | 说明                 |
| -------------------- | -------- | ----- | ------------------ |
| `tagIds`             | []uint64 | **是** | 选中的标签 ID 列表，至少 1 个 |
| `qaPairs`            | []QAPair | **是** | 问答对列表，至少 1 条       |
| `qaPairs[].question` | string   | **是** | 问题内容               |
| `qaPairs[].answer`   | string   | **是** | 答案内容               |


**响应数据：** 无（结果异步回调）

---

### 昵称类接口

**路由前缀：** `/agent/nickname`  

---

#### 23. 根据问答生成昵称

- **接口名称：** GenerateNicknameFromQA
- **接口地址：** `POST /agent/nickname/generate-from-qa`
- **请求格式：** JSON
- **说明：** 根据用户选择的标签和问答内容，AI 生成个性化昵称

**请求参数：**


| 参数名                  | 类型       | 是否必填  | 说明                 |
| -------------------- | -------- | ----- | ------------------ |
| `tagIds`             | []uint64 | **是** | 选中的标签 ID 列表，至少 1 个 |
| `qaPairs`            | []QAPair | **是** | 问答对列表，至少 1 条       |
| `qaPairs[].question` | string   | **是** | 问题内容               |
| `qaPairs[].answer`   | string   | **是** | 答案内容               |


**响应数据：**


| 字段         | 类型     | 说明       |
| ---------- | ------ | -------- |
| `nickname` | string | AI 生成的昵称 |


---

## Room 服务

### Room 公共接口

**路由前缀：** `/room/common`  

---

#### 24. 上传文件

- **接口名称：** UploadFile
- **接口地址：** `POST /room/common/upload`
- **请求格式：** Form
- **说明：** 上传房间相关文件（如封面、背景图等）

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                |
| ------ | ------ | ----- | --------------------------------- |
| `type` | string | **是** | 文件所属类型，可选值：`user`、`prompt`、`room` |
| `path` | string | **是** | 文件路径或 Base64 数据                   |
| `id`   | int    | **是** | 关联的业务 ID                          |
| `file` | file   | **是** | 上传的图片文件（multipart/form-data）      |


**响应数据：**


| 字段     | 类型     | 说明           |
| ------ | ------ | ------------ |
| `path` | string | 上传成功后的文件访问路径 |


---

### 房间接口

**路由前缀：** `/room`  

---

#### 25. 获取群配置

- **接口名称：** GetRoomConfig
- **接口地址：** `GET /room/config`
- **请求格式：** 无参数
- **说明：** 获取房间相关的全局配置信息（如成员上限、规则上限等）

**响应数据：**


| 字段                             | 类型    | 说明        |
| ------------------------------ | ----- | --------- |
| `memberLimit.freeMemberNumber` | int64 | 免费可添加成员数  |
| `memberLimit.maxMemberNumber`  | int64 | 最大成员数上限   |
| `ruleLimit.freeNumber`         | int64 | 免费可创建规则数  |
| `ruleLimit.maxNumber`          | int64 | 最大规则数上限   |
| `ruleLimit.charLength`         | int64 | 规则内容最大字符数 |


---

#### 26. 私聊房间检查/创建

- **接口名称：** CheckPrivateRoom
- **接口地址：** `POST /room/check/private`
- **请求格式：** JSON
- **说明：** 检查或创建私聊房间，支持用户与 Agent、用户与用户之间的私聊

**请求参数：**


| 参数名            | 类型     | 是否必填 | 说明                           |
| -------------- | ------ | ---- | ---------------------------- |
| `agentImId`    | string | 否    | Agent 的 IM ID（与 Agent 私聊时必填）  |
| `targetUserId` | string | 否    | 目标用户的 IM ID（与用户私聊时必填）         |


> `agentImId` 和 `targetUserId` 至少填一个

**响应数据：**


| 字段           | 类型     | 说明        |
| ------------ | ------ | --------- |
| `roomId`     | int    | 房间 ID     |
| `language`   | string | 房间语言设置    |
| `background` | string | 房间背景图 URL |
| `outputMode` | string | 输出模式      |
| `style`      | string | 对话风格      |


---

#### 27. 创建房间

- **接口名称：** CreateRoom
- **接口地址：** `POST /room/create`
- **请求格式：** JSON
- **说明：** 创建新的聊天房间（群聊或私聊）

**请求参数：**


| 参数名          | 类型      | 是否必填  | 说明                                 |
| ------------ | ------- | ----- | ---------------------------------- |
| `name`       | string  | **是** | 房间名称                               |
| `avatar`     | string  | 否     | 房间头像 URL                           |
| `cover`      | string  | 否     | 房间封面 URL                           |
| `type`       | string  | **是** | 房间可见类型，可选值：`PRIVATE`、`PUBLIC`      |
| `mode`       | string  | **是** | 房间模式，可选值：`PRIVATE`（私聊）、`GROUP`（群聊） |
| `userIds`    | []int64 | 否     | 邀请加入的用户 ID 列表                      |
| `agentIds`   | []int64 | **是** | 绑定的 Agent ID 列表，至少 1 个             |
| `outputMode` | string  | 否     | 输出模式，可选值：`direct`、`default`        |


**响应数据：**


| 字段     | 类型     | 说明        |
| ------ | ------ | --------- |
| `id`   | int    | 新创建的房间 ID |
| `imId` | string | 房间 IM ID  |


---

#### 28. 修改房间信息

- **接口名称：** UpdateRoom
- **接口地址：** `PUT /room/update`
- **请求格式：** JSON
- **说明：** 修改房间的基本信息

**请求参数：**


| 参数名          | 类型     | 是否必填  | 说明                          |
| ------------ | ------ | ----- | --------------------------- |
| `id`         | int    | **是** | 房间 ID                       |
| `name`       | string | 否     | 新的房间名称                      |
| `avatar`     | string | 否     | 新的头像 URL                    |
| `cover`      | string | 否     | 新的封面 URL                    |
| `type`       | string | 否     | 房间类型，可选值：`PRIVATE`、`PUBLIC` |
| `outputMode` | string | 否     | 输出模式，可选值：`direct`、`default` |


**响应数据：** 无

---

#### 29. 房间列表

- **接口名称：** ListRoom
- **接口地址：** `GET /room/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询房间列表，支持多条件筛选

**请求参数：**


| 参数名       | 类型     | 是否必填  | 说明                          |
| --------- | ------ | ----- | --------------------------- |
| `id`      | int    | 否     | 房间 ID                       |
| `name`    | string | 否     | 房间名称（模糊搜索）                  |
| `mode`    | string | 否     | 房间模式，可选值：`GROUP`、`PRIVATE`  |
| `type`    | string | 否     | 房间类型，可选值：`PUBLIC`、`PRIVATE` |
| `creator` | int64  | 否     | 创建者 ID                      |
| `page`    | int64  | **是** | 页码，默认 1                     |
| `size`    | int64  | **是** | 每页数量，默认 10                  |


**响应数据：**


| 字段                   | 类型             | 说明       |
| -------------------- | -------------- | -------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`               | []RoomListItem | 房间列表     |
| `records[].id`          | int            | 房间 ID    |
| `records[].name`        | string         | 房间名称     |
| `records[].mode`        | string         | 房间模式     |
| `records[].type`        | string         | 房间类型     |
| `records[].imId`        | string         | 房间 IM ID |
| `records[].creator`     | int            | 创建者 ID   |
| `records[].avatar`      | string         | 头像 URL   |
| `records[].cover`       | string         | 封面 URL   |
| `records[].memberCount` | int            | 当前成员数    |
| `records[].roomCap`     | int            | 成员容量上限   |


---

#### 30. 查询指定房间信息

- **接口名称：** GetRoom
- **接口地址：** `GET /room/:id`
- **请求格式：** Path 参数
- **说明：** 根据房间 ID 查询房间详情

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明             |
| ---- | --- | ----- | -------------- |
| `id` | int | **是** | 房间 ID（Path 参数） |


**响应数据：**


| 字段               | 类型           | 说明         |
| ---------------- | ------------ | ---------- |
| `id`             | int          | 房间 ID      |
| `name`           | string       | 房间名称       |
| `mode`           | string       | 房间模式       |
| `type`           | string       | 房间类型       |
| `imId`           | string       | 房间 IM ID   |
| `avatar`         | string       | 头像 URL     |
| `cover`          | string       | 封面 URL     |
| `isInTheRoom`    | bool         | 当前用户是否在房间内 |
| `userBackground` | string       | 用户设置的房间背景  |
| `memberCount`    | int          | 成员数量       |
| `freeMemberCap`  | int          | 免费成员容量     |
| `isPrivateFree`  | bool         | 私聊是否免费     |
| `members`        | []RoomMember | 成员列表       |


**RoomMember 字段：**


| 字段          | 类型     | 说明               |
| ----------- | ------ | ---------------- |
| `id`        | int    | 成员 ID            |
| `type`      | string | 成员类型（user/agent） |
| `name`      | string | 成员名称             |
| `avatar`    | string | 头像 URL           |
| `imid`      | string | IM ID            |
| `isCreator` | bool   | 是否为创建者           |
| `joinType`  | string | 加入方式             |
| `joinAt`    | string | 加入时间             |


---

#### 31. 通过 IM ID 查询房间

- **接口名称：** GetRoomByIm
- **接口地址：** `GET /room/imid/:imId`
- **请求格式：** Path 参数
- **说明：** 根据 IM ID 查询房间详情

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                |
| ------ | ------ | ----- | ----------------- |
| `imId` | string | **是** | 房间 IM ID（Path 参数） |


**响应数据：** 与 [查询指定房间信息](#30-查询指定房间信息) 相同

---

#### 32. 加入群聊

- **接口名称：** JoinRoom
- **接口地址：** `POST /room/join`
- **请求格式：** JSON
- **说明：** 当前用户申请加入指定群聊

**请求参数：**


| 参数名      | 类型  | 是否必填  | 说明           |
| -------- | --- | ----- | ------------ |
| `roomId` | int | **是** | 房间 ID，必须大于 0 |


**响应数据：** 无

---

#### 33. 邀请加入群聊

- **接口名称：** InviteRoom
- **接口地址：** `POST /room/invite`
- **请求格式：** JSON
- **说明：** 邀请指定用户或 Agent 加入群聊

**请求参数：**


| 参数名        | 类型      | 是否必填  | 说明                             |
| ---------- | ------- | ----- | ------------------------------ |
| `roomId`   | int64   | **是** | 房间 ID，必须大于 0                   |
| `userIds`  | []int64 | 否     | 邀请的用户 ID 列表（与 agentIds 二选一）    |
| `agentIds` | []int64 | 否     | 邀请的 Agent ID 列表（与 userIds 二选一） |


**响应数据：** 无

---

#### 34. 移除群聊成员

- **接口名称：** RemoveMember
- **接口地址：** `POST /room/remove`
- **请求格式：** JSON
- **说明：** 将指定用户或 Agent 移除出群聊（仅群主可操作）

**请求参数：**


| 参数名        | 类型      | 是否必填  | 说明                              |
| ---------- | ------- | ----- | ------------------------------- |
| `roomId`   | int64   | **是** | 房间 ID，必须大于 0                    |
| `userIds`  | []int64 | 否     | 要移除的用户 ID 列表（与 agentIds 二选一）    |
| `agentIds` | []int64 | 否     | 要移除的 Agent ID 列表（与 userIds 二选一） |


**响应数据：** 无

---

#### 35. 退出群聊

- **接口名称：** ExitRoom
- **接口地址：** `POST /room/exit`
- **请求格式：** JSON
- **说明：** 当前用户退出指定群聊

**请求参数：**


| 参数名      | 类型    | 是否必填  | 说明           |
| -------- | ----- | ----- | ------------ |
| `roomId` | int64 | **是** | 房间 ID，必须大于 0 |


**响应数据：** 无

---

#### 36. 解散群聊

- **接口名称：** DelRoom
- **接口地址：** `DELETE /room/:id`
- **请求格式：** Path 参数
- **说明：** 群主解散群聊（仅群主可操作）

**请求参数：**


| 参数名  | 类型    | 是否必填  | 说明                    |
| ---- | ----- | ----- | --------------------- |
| `id` | int64 | **是** | 房间 ID（Path 参数），必须大于 0 |


**响应数据：** 无

---

#### 37. 获取默认聊天背景

- **接口名称：** GetDefaultBackground
- **接口地址：** `GET /room/background/default`
- **请求格式：** 无参数
- **说明：** 获取系统提供的默认聊天背景图列表

**响应数据：**


| 字段     | 类型       | 说明         |
| ------ | -------- | ---------- |
| `records` | []string | 背景图 URL 列表 |


---

#### 38. 设置群背景

- **接口名称：** SetBackground
- **接口地址：** `PUT /room/background`
- **请求格式：** JSON
- **说明：** 为指定房间设置聊天背景（用户个人设置）

**请求参数：**


| 参数名          | 类型     | 是否必填  | 说明                  |
| ------------ | ------ | ----- | ------------------- |
| `roomId`     | int64  | **是** | 房间 ID，必须大于 0        |
| `background` | string | 否     | 背景图 URL（为空时重置为默认背景） |


**响应数据：** 无

---

#### 39. 推荐房间

- **接口名称：** Recommend
- **接口地址：** `GET /room/recommend`
- **请求格式：** Form（Query 参数）
- **说明：** 获取系统推荐的公开房间列表

**请求参数：**


| 参数名     | 类型    | 是否必填 | 说明         |
| ------- | ----- | ---- | ---------- |
| `limit` | int64 | 否    | 返回数量，默认 10 |


**响应数据：**


| 字段     | 类型             | 说明               |
| ------ | -------------- | ---------------- |
| `records` | []RoomListItem | 推荐的房间列表（字段同房间列表） |


---

#### 40. 房间扩容

- **接口名称：** AddRoomCap
- **接口地址：** `POST /room/add/cap`
- **请求格式：** JSON
- **说明：** 为指定房间购买/增加成员容量

**请求参数：**


| 参数名           | 类型    | 是否必填  | 说明             |
| ------------- | ----- | ----- | -------------- |
| `roomId`      | int64 | **是** | 房间 ID，必须大于 0   |
| `memberCount` | int64 | **是** | 增加的成员数量，必须大于 0 |


**响应数据：**


| 字段        | 类型    | 说明         |
| --------- | ----- | ---------- |
| `roomCap` | int64 | 扩容后的成员容量上限 |


---

### 房间规则接口

**路由前缀：** `/room/rule`  

---

#### 41. 添加规则

- **接口名称：** AddRule
- **接口地址：** `POST /room/rule/add`
- **请求格式：** JSON
- **说明：** 为指定房间添加规则

**请求参数：**


| 参数名      | 类型     | 是否必填  | 说明            |
| -------- | ------ | ----- | ------------- |
| `roomId` | int64  | **是** | 房间 ID，必须大于 0  |
| `rule`   | string | **是** | 规则内容，长度 1~255 |


**响应数据：** 无

---

#### 42. 修改规则

- **接口名称：** UpdateRule
- **接口地址：** `PUT /room/rule/update`
- **请求格式：** JSON
- **说明：** 修改指定规则内容

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明              |
| ------ | ------ | ----- | --------------- |
| `id`   | int64  | **是** | 规则 ID，必须大于 0    |
| `rule` | string | **是** | 新的规则内容，长度 1~255 |


**响应数据：** 无

---

#### 43. 获取规则详情

- **接口名称：** GetRule
- **接口地址：** `GET /room/rule/:id`
- **请求格式：** Path 参数
- **说明：** 根据规则 ID 获取规则详情

**请求参数：**


| 参数名  | 类型    | 是否必填  | 说明             |
| ---- | ----- | ----- | -------------- |
| `id` | int64 | **是** | 规则 ID（Path 参数） |


**响应数据：**


| 字段          | 类型     | 说明    |
| ----------- | ------ | ----- |
| `id`        | int    | 规则 ID |
| `rule`      | string | 规则内容  |
| `createdAt` | string | 创建时间  |
| `updatedAt` | string | 更新时间  |


---

#### 44. 规则列表

- **接口名称：** ListRule
- **接口地址：** `GET /room/rule/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询指定房间的规则列表

**请求参数：**


| 参数名      | 类型    | 是否必填  | 说明           |
| -------- | ----- | ----- | ------------ |
| `roomId` | int64 | **是** | 房间 ID，必须大于 0 |
| `page`   | int64 | **是** | 页码，默认 1      |
| `size`   | int64 | **是** | 每页数量，默认 10   |


**响应数据：**


| 字段      | 类型         | 说明              |
| ------- | ---------- | --------------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []RuleItem | 规则列表（字段同获取规则详情） |


---

#### 45. 删除规则

- **接口名称：** DelRule
- **接口地址：** `DELETE /room/rule/:id`
- **请求格式：** Path 参数
- **说明：** 删除指定规则

**请求参数：**


| 参数名  | 类型    | 是否必填  | 说明                    |
| ---- | ----- | ----- | --------------------- |
| `id` | int64 | **是** | 规则 ID（Path 参数），必须大于 0 |


**响应数据：** 无

---

## User 服务

### 注册登录接口

**路由前缀：** `/user`  

---

#### 46. 用户注册

- **接口名称：** Register
- **接口地址：** `POST /user/register`
- **请求格式：** JSON
- **鉴权：** 无需 Token
- **说明：** 使用邮箱和密码注册新账户

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明             |
| ---------- | ------ | ----- | -------------- |
| `username` | string | **是** | 用户邮箱，必须是合法邮箱格式 |
| `password` | string | **是** | 密码，长度 8~24 位   |


**响应数据：**


| 字段         | 类型     | 说明          |
| ---------- | ------ | ----------- |
| `expireAt` | int64  | Token 过期时间戳 |
| `token`    | string | JWT Token   |
| `imToken`  | string | IM 服务 Token |


---

#### 47. 用户登录

- **接口名称：** Login
- **接口地址：** `POST /user/login`
- **请求格式：** JSON
- **鉴权：** 无需 Token
- **说明：** 支持账号密码、Apple ID、Google 账号三种登录方式

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明                                       |
| ----------- | ------ | ----- | ---------------------------------------- |
| `loginType` | int    | **是** | 登录方式：`1` 账号密码、`2` Apple ID、`3` Google 账号 |
| `username`  | string | **是** | 用户名（邮箱）或第三方账号 Token                      |
| `password`  | string | 否     | 密码（loginType=1 时必填）                      |


**响应数据：**


| 字段         | 类型     | 说明          |
| ---------- | ------ | ----------- |
| `expireAt` | int64  | Token 过期时间戳 |
| `token`    | string | JWT Token   |
| `imToken`  | string | IM 服务 Token |


---

#### 48. 忘记密码

- **接口名称：** ForgetPassword
- **接口地址：** `POST /user/forget/password`
- **请求格式：** JSON
- **鉴权：** 无需 Token
- **说明：** 通过邮箱验证码重置密码

**请求参数：**


| 参数名               | 类型     | 是否必填  | 说明                      |
| ----------------- | ------ | ----- | ----------------------- |
| `email`           | string | **是** | 注册邮箱                    |
| `code`            | string | **是** | 邮箱验证码，长度 6 位            |
| `newPassword`     | string | **是** | 新密码，长度 8~24 位           |
| `confirmPassword` | string | **是** | 确认密码，必须与 newPassword 一致 |


**响应数据：** 无

---

#### 49. 获取指定配置

- **接口名称：** GetConfig
- **接口地址：** `GET /user/config`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 根据配置 Code 获取系统配置项

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明       |
| ------ | ------ | ----- | -------- |
| `code` | string | **是** | 配置项 Code |


**响应数据：**


| 字段     | 类型     | 说明             |
| ------ | ------ | -------------- |
| `code` | string | 配置项 Code       |
| `data` | any    | 配置数据（格式依配置项而定） |


---

### User 公共接口

**路由前缀：** `/user/common`  

---

#### 50. 上传文件

- **接口名称：** UploadFile
- **接口地址：** `POST /user/common/upload/file`
- **请求格式：** Form
- **说明：** 上传用户相关文件（如头像、背景图等）

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                |
| ------ | ------ | ----- | --------------------------------- |
| `type` | string | **是** | 文件所属类型，可选值：`user`、`prompt`、`room` |
| `path` | string | **是** | 文件路径或 Base64 数据                   |
| `id`   | int    | **是** | 关联的业务 ID                          |
| `file` | file   | **是** | 上传的图片文件（multipart/form-data）      |


**响应数据：**


| 字段     | 类型     | 说明           |
| ------ | ------ | ------------ |
| `path` | string | 上传成功后的文件访问路径 |


---

### 用户信息接口

**路由前缀：** `/user`  

---

#### 51. 设置用户标签收集状态

- **接口名称：** SetUserTagStatus
- **接口地址：** `POST /user/tag/status`
- **请求格式：** JSON
- **说明：** 设置用户标签收集状态（如完成/未完成引导流程）

**请求参数：**


| 参数名      | 类型    | 是否必填  | 说明                  |
| -------- | ----- | ----- | ------------------- |
| `status` | int64 | **是** | 状态值：`1` 未完成，`2` 已完成 |


**响应数据：** 无

---

#### 52. 获取当前登录用户信息

- **接口名称：** GetLoginUser
- **接口地址：** `GET /user/current/user`
- **请求格式：** 无参数
- **说明：** 获取当前已登录用户的详细信息
- **需要 Authorization：** 是

**响应数据：**


| 字段                   | 类型       | 说明            |
| -------------------- | -------- | ------------- |
| `id`                 | int64    | 用户 ID         |
| `userNo`             | int64    | 用户编号          |
| `username`           | string   | 用户名（邮箱）       |
| `nickname`           | string   | 昵称            |
| `avatar`             | string   | 头像 URL        |
| `email`              | string   | 邮箱            |
| `bio`                | string   | 个人简介          |
| `mbti`               | string   | MBTI 性格类型     |
| `constellation`      | string   | 星座            |
| `gender`             | int      | 性别（1男 2女 3未知） |
| `background`         | string   | 背景图 URL       |
| `imId`               | string   | IM ID         |
| `fansCount`          | int      | 粉丝数           |
| `followCount`        | int      | 关注数           |
| `isFollow`           | bool     | 是否已关注         |
| `language`           | string   | 语言设置          |
| `timezone`           | string   | 时区            |
| `tagStatus`          | int      | 标签收集状态        |
| `lastLoginAt`        | string   | 最后登录时间        |
| `userCertifications` | []object | 用户认证信息        |


---

#### 53. 获取指定用户信息

- **接口名称：** GetUser
- **接口地址：** `GET /user/info/:id`
- **请求格式：** Path 参数
- **鉴权：** 无需 Token
- **说明：** 根据用户 ID 查询用户公开信息

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明             |
| ---- | --- | ----- | -------------- |
| `id` | int | **是** | 用户 ID（Path 参数） |


**响应数据：** 同 [获取当前登录用户信息](#52-获取当前登录用户信息)

---

#### 54. 通过 IM ID 查询用户

- **接口名称：** GetUserByImid
- **接口地址：** `GET /user/info/imid/:imId`
- **请求格式：** Path 参数
- **说明：** 根据 IM ID 查询用户公开信息

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                |
| ------ | ------ | ----- | ----------------- |
| `imId` | string | **是** | 用户 IM ID（Path 参数） |


**响应数据：** 同 [获取当前登录用户信息](#52-获取当前登录用户信息)

---

#### 55. 修改用户基本信息

- **接口名称：** UpdateProfile
- **接口地址：** `PUT /user/info/update`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 修改当前用户的个人资料

**请求参数：**


| 参数名             | 类型     | 是否必填  | 说明                    |
| --------------- | ------ | ----- | --------------------- |
| `nickname`      | string | **是** | 昵称，长度 2~32            |
| `avatar`        | string | 否     | 头像 URL                |
| `backgroud`     | string | 否     | 背景图 URL               |
| `bio`           | string | 否     | 个人简介                  |
| `constellation` | string | 否     | 星座                    |
| `mbti`          | string | 否     | MBTI 性格类型             |
| `gender`        | int    | 否     | 性别：`1` 男，`2` 女，`3` 未知 |


**响应数据：** 无

---

#### 56. 用户列表

- **接口名称：** UserList
- **接口地址：** `GET /user/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询用户列表，支持多条件筛选

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明         |
| ---------- | ------ | ----- | ---------- |
| `username` | string | 否     | 用户名筛选      |
| `userNo`   | string | 否     | 用户编号筛选     |
| `nickname` | string | 否     | 昵称筛选       |
| `roomId`   | int64  | 否     | 按房间 ID 筛选  |
| `gender`   | int    | 否     | 性别：`1` 男，`2` 女，`3` 未知 |
| `page`     | int64  | **是** | 页码，默认 1    |
| `size`     | int64  | **是** | 每页数量，默认 10 |


**响应数据：**


| 字段      | 类型         | 说明   |
| ------- | ---------- | ---- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []UserItem | 用户列表 |


---

#### 57. 修改密码

- **接口名称：** ChangePassword
- **接口地址：** `PUT /user/change/password`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 修改当前用户密码

**请求参数：**


| 参数名               | 类型     | 是否必填  | 说明                      |
| ----------------- | ------ | ----- | ----------------------- |
| `oldPassword`     | string | **是** | 旧密码                     |
| `newPassword`     | string | **是** | 新密码，长度 8~24 位           |
| `confirmPassword` | string | **是** | 确认密码，必须与 newPassword 一致 |


**响应数据：** 无

---

#### 58. 退出登录

- **接口名称：** Logout
- **接口地址：** `POST /user/logout`
- **请求格式：** 无参数
- **需要 Authorization：** 是
- **说明：** 退出当前登录状态，使 Token 失效

**响应数据：** 无

---

#### 59. 注销账户

- **接口名称：** CancelAccount
- **接口地址：** `POST /user/cancel/account`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 注销当前用户账号（不可恢复）

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明           |
| ---------- | ------ | ----- | ------------ |
| `password` | string | **是** | 当前密码（用于确认身份） |


**响应数据：** 无

---

#### 60. 保存用户标签

- **接口名称：** SaveUserTags
- **接口地址：** `POST /user/tags/save`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 全量保存用户标签（覆盖原有标签）

**请求参数：**


| 参数名      | 类型       | 是否必填  | 说明       |
| -------- | -------- | ----- | -------- |
| `tagIds` | []uint64 | **是** | 标签 ID 列表 |


**响应数据：** 无

---

#### 61. 标签匹配

- **接口名称：** MatchTags
- **接口地址：** `POST /user/match/tags`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 根据标签匹配相似用户和智能体

**请求参数：**


| 参数名             | 类型      | 是否必填  | 说明                                             |
| --------------- | ------- | ----- | ---------------------------------------------- |
| `matchType`     | string  | **是** | 匹配类型：`preferred`（兴趣标签）、`core`（人格标签）、`both`（两者） |
| `matchTarget`   | string  | **是** | 匹配对象：`user`、`prompt`、`both`                    |
| `gender`        | string  | 否     | 性别筛选：`male`、`female`、`all`                     |
| `preferredMode` | int     | **是** | 相似程度：`1` 非常相似，`2` 相似，`3` 不相似                   |
| `coreMix`       | float64 | **是** | 相符/互补混合比例（0.0~1.0，0 完全相符，1 完全互补）               |


**响应数据：**


| 字段        | 类型              | 说明                 |
| --------- | --------------- | ------------------ |
| `users`   | []MatchedUser   | 匹配到的用户列表（按匹配数量降序）  |
| `prompts` | []MatchedPrompt | 匹配到的智能体列表（按匹配数量降序） |


---

#### 62. 添加用户标签

- **接口名称：** AddUserTags
- **接口地址：** `POST /user/tags/add`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 增量添加用户标签

**请求参数：**


| 参数名      | 类型       | 是否必填  | 说明           |
| -------- | -------- | ----- | ------------ |
| `tagIds` | []uint64 | **是** | 要添加的标签 ID 列表 |


**响应数据：** 无

---

#### 63. 删除用户标签

- **接口名称：** DeleteUserTags
- **接口地址：** `POST /user/tags/delete`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 删除用户指定标签

**请求参数：**


| 参数名      | 类型       | 是否必填  | 说明           |
| -------- | -------- | ----- | ------------ |
| `tagIds` | []uint64 | **是** | 要删除的标签 ID 列表 |


**响应数据：** 无

---

#### 64. 获取用户标签列表

- **接口名称：** GetUserTags
- **接口地址：** `GET /user/tags/list`
- **请求格式：** Form（Query 参数）
- **说明：** 查询当前用户的标签列表，支持按分类筛选

**请求参数：**


| 参数名          | 类型   | 是否必填 | 说明               |
| ------------ | ---- | ---- | ---------------- |
| `categoryId` | uint | 否    | 标签分类 ID（不传则返回全部） |


**响应数据：**


| 字段                  | 类型        | 说明      |
| ------------------- | --------- | ------- |
| `tags`              | []TagItem | 标签列表    |
| `tags[].id`         | uint      | 标签 ID   |
| `tags[].name`       | string    | 标签名称    |
| `tags[].categoryId` | uint      | 所属分类 ID |
| `tags[].category`   | string    | 分类名称    |


---

#### 65. 获取标签分类列表

- **接口名称：** GetTagCategoryList
- **接口地址：** `GET /user/tags/category/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询标签分类列表

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                  |
| ------ | ------ | ----- | ----------------------------------- |
| `type` | string | 否     | 分类类型：`preferred`（兴趣标签）、`core`（人格标签） |
| `page` | int64  | **是** | 页码，默认 1                             |
| `size` | int64  | **是** | 每页数量，默认 10                          |


**响应数据：**


| 字段            | 类型                | 说明    |
| ------------- | ----------------- | ----- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`        | []TagCategoryItem | 分类列表  |
| `records[].id`   | uint              | 分类 ID |
| `records[].name` | string            | 分类名称  |
| `records[].type` | string            | 分类类型  |
| `records[].sort` | int               | 排序值   |


---

#### 66. 获取标签列表

- **接口名称：** GetTagList
- **接口地址：** `GET /user/tag/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询可用标签列表

**请求参数：**


| 参数名          | 类型     | 是否必填  | 说明                |
| ------------ | ------ | ----- | ----------------- |
| `categoryId` | uint   | 否     | 按分类 ID 筛选         |
| `name`       | string | 否     | 按标签名搜索            |
| `recommend`  | bool   | 否     | 是否只返回推荐标签         |
| `excludeIds` | string | 否     | 排除的标签 ID 列表（逗号分隔） |
| `userId`     | uint   | 否     | 按用户 ID 筛选已有标签     |
| `page`       | int64  | **是** | 页码，默认 1           |
| `size`       | int64  | **是** | 每页数量，默认 10        |


**响应数据：**


| 字段      | 类型        | 说明   |
| ------- | --------- | ---- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []TagItem | 标签列表 |


---

### 黑名单接口

**路由前缀：** `/user/black`  

---

#### 67. 黑名单列表

- **接口名称：** BlackList
- **接口地址：** `GET /user/black/list`
- **请求格式：** Form（Query 参数）
- **说明：** 查询当前用户的黑名单列表

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                  |
| ---------- | ------ | ----- | ------------------- |
| `username` | string | 否     | 按用户名筛选              |
| `nickname` | string | 否     | 按昵称筛选               |
| `type`     | string | 否     | 类型筛选：`user`、`agent` |
| `page`     | int64  | **是** | 页码，默认 1             |
| `size`     | int64  | **是** | 每页数量，默认 10          |


**响应数据：**


| 字段                 | 类型              | 说明     |
| ------------------ | --------------- | ------ |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`             | []BlackListItem | 黑名单列表  |
| `records[].id`        | int             | ID     |
| `records[].nickname`  | string          | 昵称     |
| `records[].avatar`    | string          | 头像 URL |
| `records[].imId`      | string          | IM ID  |
| `records[].type`      | string          | 类型     |
| `records[].createdAt` | string          | 拉黑时间   |


---

#### 68. 添加黑名单

- **接口名称：** AddBlackList
- **接口地址：** `POST /user/black/add`
- **请求格式：** JSON
- **说明：** 将指定用户或 Agent 加入黑名单

**请求参数：**


| 参数名             | 类型     | 是否必填  | 说明                     |
| --------------- | ------ | ----- | ---------------------- |
| `blackUserId`   | int    | **是** | 要拉黑的用户/Agent ID，必须大于 0 |
| `blackUserType` | string | **是** | 类型：`user`、`agent`      |


**响应数据：** 无

---

#### 69. 删除黑名单

- **接口名称：** RemoveBlackList
- **接口地址：** `DELETE /user/black/del`
- **请求格式：** JSON
- **说明：** 从黑名单中移除指定记录

**请求参数：**


| 参数名   | 类型    | 是否必填  | 说明              |
| ----- | ----- | ----- | --------------- |
| `ids` | []int | **是** | 要删除的黑名单记录 ID 列表 |


**响应数据：** 无

---

### 智能体分类接口

**路由前缀：** `/user/category`  

---

#### 70. 智能体分类列表

- **接口名称：** CategoryList
- **接口地址：** `GET /user/category/list`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 获取智能体的分类列表

**请求参数：**


| 参数名            | 类型     | 是否必填  | 说明                 |
| -------------- | ------ | ----- | ------------------ |
| `languageCode` | string | 否     | 语言代码，用于返回对应语言的分类名称 |
| `page`         | int64  | **是** | 页码，默认 1            |
| `size`         | int64  | **是** | 每页数量，默认 10         |


**响应数据：**


| 字段                  | 类型                   | 说明     |
| ------------------- | -------------------- | ------ |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`              | []CategoryItem       | 分类列表   |
| `records[].id`         | int                  | 分类 ID  |
| `records[].name`       | string               | 分类名称   |
| `records[].sort`       | int                  | 排序值    |
| `records[].icon`       | string               | 图标 URL |
| `records[].translator` | []CategoryTranslator | 多语言翻译  |


---

### 问答接口

**路由前缀：** `/user/question`  

---

#### 71. 获取问题

- **接口名称：** GetQuestion
- **接口地址：** `POST /user/question/get`
- **请求格式：** JSON
- **说明：** 获取问答题目（用于用户引导流程或标签收集）

**请求参数：**


| 参数名                     | 类型     | 是否必填 | 说明                    |
| ----------------------- | ------ | ---- | --------------------- |
| `id`                    | int    | 否    | 指定问题 ID               |
| `randomCount`           | int    | 否    | 随机获取问题数量，最小 1         |
| `prevQuestionId`        | int    | 否    | 上一个问题的 ID（用于自动获取下一问题） |
| `prevQuestion`          | string | 否    | 上一个问题内容               |
| `prevAnswer`            | string | 否    | 上一个问题的答案              |
| `additionalDescription` | string | 否    | 附加描述（用于 LLM 生成题干）     |


**响应数据：**


| 字段           | 类型               | 说明          |
| ------------ | ---------------- | ----------- |
| `id`         | int              | 问题 ID       |
| `question`   | string           | 问题内容        |
| `options`    | []QuestionOption | 选项列表        |
| `free`       | bool             | 是否支持自由输入    |
| `directText` | bool             | 是否直接文本输入    |
| `end`        | bool             | 是否为最后一题     |
| `freeNextId` | int              | 自由输入时下一题 ID |
| `useLLM`     | bool             | 是否使用 LLM 生成 |


---

### 智能体 (Prompt) 接口

**路由前缀：** `/user/prompt`  

---

#### 72. 创建智能体

- **接口名称：** CreatePrompt
- **接口地址：** `POST /user/prompt/create`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 创建新的 AI 智能体（角色）

**请求参数：**


| 参数名          | 类型     | 是否必填  | 说明                              |
| ------------ | ------ | ----- | ------------------------------- |
| `name`       | string | **是** | 智能体名称                           |
| `avatar`     | string | 否     | 头像 URL                          |
| `roleAvatar` | string | 否     | 智能体 Banner 图（个人风格图）URL           |
| `desc`       | string | **是** | 智能体描述                           |
| `settings`   | string | **是** | 智能体设定（系统 Prompt）                |
| `mode`       | string | **是** | 可见模式：`public`（公开）、`private`（私有） |


**响应数据：**


| 字段     | 类型     | 说明        |
| ------ | ------ | --------- |
| `id`   | int    | 智能体 ID    |
| `imId` | string | 智能体 IM ID |


---

#### 73. 智能体列表

- **接口名称：** PromptList
- **接口地址：** `GET /user/prompt/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询智能体列表，支持多条件筛选

**请求参数：**


| 参数名                 | 类型     | 是否必填  | 说明                      |
| ------------------- | ------ | ----- | ----------------------- |
| `categoryId`        | int    | 否     | 按分类 ID 筛选               |
| `authorId`          | int    | 否     | 按作者 ID 筛选               |
| `mode`              | string | 否     | 可见模式：`public`、`private` |
| `name`              | string | 否     | 按名称搜索                   |
| `certificationType` | string | 否     | 认证类型筛选                  |
| `mainLanguage`      | string | 否     | 主语言筛选                   |
| `source`            | string | 否     | 来源筛选                    |
| `roomId`            | int64  | 否     | 按房间 ID 筛选               |
| `gender`            | int    | 否     | 性别：`1` 男，`2` 女，`3` 未知 |
| `page`              | int64  | **是** | 页码，默认 1                 |
| `size`              | int64  | **是** | 每页数量，默认 10              |


**响应数据：**


| 字段      | 类型           | 说明    |
| ------- | ------------ | ----- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []PromptItem | 智能体列表 |


**PromptItem 字段：**


| 字段                  | 类型                 | 说明           |
| ------------------- | ------------------ | ------------ |
| `id`                | int                | 智能体 ID       |
| `name`              | string             | 名称           |
| `banner`            | string             | Banner 图 URL |
| `desc`              | string             | 描述           |
| `avatar`            | string             | 头像 URL       |
| `roleAvatar`        | string             | 智能体 Banner 图（个人风格图）URL |
| `mode`              | string             | 可见模式         |
| `imid`              | string             | IM ID        |
| `gender`            | int                | 性别           |
| `age`               | int                | 年龄           |
| `mbti`              | string             | MBTI         |
| `constellation`     | string             | 星座           |
| `mainLanguage`      | string             | 主语言          |
| `defaultChatStyle`  | string             | 默认对话风格       |
| `defaultOutputMode` | string             | 默认输出模式       |
| `certificationType` | int                | 认证类型         |
| `fansCount`         | int64              | 粉丝数          |
| `isFollow`          | bool               | 是否已关注        |
| `author`            | PromptAuthor       | 作者信息         |
| `translator`        | []PromptTranslator | 多语言翻译        |
| `categories`        | []PromptCategory   | 所属分类         |
| `tags`              | []TagItem          | 标签列表         |


---

#### 74. 修改智能体信息

- **接口名称：** UpdatePrompt
- **接口地址：** `PUT /user/prompt/update`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 修改已有智能体的基本信息

**请求参数：**


| 参数名          | 类型     | 是否必填  | 说明                      |
| ------------ | ------ | ----- | ----------------------- |
| `id`         | int    | **是** | 智能体 ID                  |
| `name`       | string | **是** | 新名称                     |
| `avatar`     | string | 否     | 新头像 URL                 |
| `roleAvatar` | string | 否     | 新 Banner 图（个人风格图）URL     |
| `desc`       | string | **是** | 新描述                     |
| `settings`   | string | **是** | 新设定内容                   |
| `mode`       | string | **是** | 可见模式：`public`、`private` |


**响应数据：** 无

---

#### 75. 获取指定智能体信息

- **接口名称：** GetPrompt
- **接口地址：** `GET /user/prompt/:id`
- **请求格式：** Path 参数
- **鉴权：** 无需 Token
- **说明：** 根据智能体 ID 查询详细信息

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明              |
| ---- | --- | ----- | --------------- |
| `id` | int | **是** | 智能体 ID（Path 参数） |


**响应数据：** 同 PromptItem（见智能体列表）

---

#### 76. 通过 IM ID 查询智能体

- **接口名称：** GetPromptByImid
- **接口地址：** `GET /user/prompt/imid/:imId`
- **请求格式：** Path 参数
- **说明：** 根据 IM ID 查询智能体详细信息

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                 |
| ------ | ------ | ----- | ------------------ |
| `imId` | string | **是** | 智能体 IM ID（Path 参数） |


**响应数据：** 同 PromptItem

---

#### 77. 删除智能体

- **接口名称：** DeletePrompt
- **接口地址：** `DELETE /user/prompt/:id`
- **请求格式：** Path 参数
- **需要 Authorization：** 是
- **说明：** 删除指定智能体

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明              |
| ---- | --- | ----- | --------------- |
| `id` | int | **是** | 智能体 ID（Path 参数） |


**响应数据：** 无

---

#### 78. 创建智能体规则

- **接口名称：** CreateRule
- **接口地址：** `POST /user/prompt/create/rule`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 为智能体创建行为规则

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明        |
| ---------- | ------ | ----- | --------- |
| `name`     | string | **是** | 规则名称      |
| `rule`     | string | **是** | 规则内容      |
| `promptId` | int    | **是** | 关联的智能体 ID |


**响应数据：** 无

---

#### 79. 修改智能体规则

- **接口名称：** UpdateRule
- **接口地址：** `PUT /user/prompt/edit/rule`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 修改指定智能体规则

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明        |
| ---------- | ------ | ----- | --------- |
| `id`       | int    | **是** | 规则 ID     |
| `name`     | string | **是** | 新规则名称     |
| `rule`     | string | **是** | 新规则内容     |
| `promptId` | int    | **是** | 关联的智能体 ID |


**响应数据：** 无

---

#### 80. 智能体规则列表

- **接口名称：** RuleList
- **接口地址：** `GET /user/prompt/rule/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询指定智能体的规则列表

**请求参数：**


| 参数名        | 类型    | 是否必填  | 说明         |
| ---------- | ----- | ----- | ---------- |
| `promptId` | int   | **是** | 智能体 ID     |
| `page`     | int64 | **是** | 页码，默认 1    |
| `size`     | int64 | **是** | 每页数量，默认 10 |


**响应数据：**


| 字段      | 类型               | 说明   |
| ------- | ---------------- | ---- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []PromptRuleItem | 规则列表 |


---

#### 81. 删除智能体规则

- **接口名称：** DeleteRule
- **接口地址：** `DELETE /user/prompt/rule/:id`
- **请求格式：** Path 参数
- **需要 Authorization：** 是
- **说明：** 删除指定智能体规则

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明             |
| ---- | --- | ----- | -------------- |
| `id` | int | **是** | 规则 ID（Path 参数） |


**响应数据：** 无

---

#### 82. 推荐智能体

- **接口名称：** Recommend
- **接口地址：** `GET /user/prompt/recommend`
- **请求格式：** Form（Query 参数）
- **说明：** 获取系统推荐的智能体列表

**请求参数：**


| 参数名     | 类型  | 是否必填 | 说明              |
| ------- | --- | ---- | --------------- |
| `limit` | int | 否    | 返回数量，默认 10，最小 1 |


**响应数据：**


| 字段     | 类型           | 说明      |
| ------ | ------------ | ------- |
| `records` | []PromptItem | 推荐智能体列表 |


---

### 关注粉丝接口

**路由前缀：** `/user`  

---

#### 83. 关注用户

- **接口名称：** FollowUser
- **接口地址：** `POST /user/follow/user`
- **请求格式：** JSON
- **说明：** 关注指定用户或智能体

**请求参数：**


| 参数名              | 类型     | 是否必填  | 说明                    |
| ---------------- | ------ | ----- | --------------------- |
| `flowUserId`     | int    | **是** | 要关注的用户/Agent ID       |
| `followUserType` | string | **是** | 关注对象类型：`user`、`agent` |


> **强制说明：** `followUserType` 必须与 `flowUserId` 对应对象一致：关注用户传 `user`，关注智能体传 `agent`，禁止混传。

**响应数据：** 无

---

#### 84. 取消关注

- **接口名称：** UnFollowUser
- **接口地址：** `POST /user/unfollow/user`
- **请求格式：** JSON
- **说明：** 取消关注指定用户或智能体

**请求参数：** 同关注用户

**响应数据：** 无

---

#### 85. 关注列表

- **接口名称：** FollowUserList
- **接口地址：** `GET /user/follow/list`
- **请求格式：** Form（Query 参数）
- **说明：** 查询指定用户的关注列表

**请求参数：**


| 参数名      | 类型    | 是否必填  | 说明         |
| -------- | ----- | ----- | ---------- |
| `userId` | int   | **是** | 查询的用户 ID   |
| `page`   | int64 | **是** | 页码，默认 1    |
| `size`   | int64 | **是** | 每页数量，默认 10 |


**响应数据：**


| 字段      | 类型               | 说明   |
| ------- | ---------------- | ---- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []FollowUserItem | 关注列表 |


---

#### 86. 粉丝列表

- **接口名称：** FansUserList
- **接口地址：** `GET /user/fans/list`
- **请求格式：** Form（Query 参数）
- **说明：** 查询指定用户的粉丝列表

**请求参数：**


| 参数名              | 类型     | 是否必填  | 说明                     |
| ---------------- | ------ | ----- | ---------------------- |
| `userId`         | int    | **是** | 查询的用户 ID               |
| `followUserType` | string | 否     | 按粉丝类型筛选：`user`、`agent` |
| `page`           | int64  | **是** | 页码，默认 1                |
| `size`           | int64  | **是** | 每页数量，默认 10             |


**响应数据：**


| 字段      | 类型             | 说明   |
| ------- | -------------- | ---- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []FansUserItem | 粉丝列表 |


---

### 积分接口

**路由前缀：** `/user/points`  

---

#### 87. 获取积分余额

- **接口名称：** GetUserPointBalance
- **接口地址：** `GET /user/points/balance`
- **请求格式：** 无参数
- **说明：** 获取当前用户的积分余额详情

**响应数据：**


| 字段                    | 类型     | 说明          |
| --------------------- | ------ | ----------- |
| `taskBalance`         | int64  | 任务获得的免费积分余额 |
| `taskBalanceExpireAt` | string | 任务积分到期时间    |
| `topUpBalance`        | int64  | 充值积分余额      |
| `totalUseBalance`     | int64  | 历史总消耗积分     |
| `totalGetBalance`     | int64  | 历史总获得积分     |


---

#### 88. 积分使用记录

- **接口名称：** GetUserPointUseList
- **接口地址：** `GET /user/points/user/use/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询当前用户的积分使用记录

**请求参数：**


| 参数名    | 类型    | 是否必填  | 说明         |
| ------ | ----- | ----- | ---------- |
| `page` | int64 | **是** | 页码，默认 1    |
| `size` | int64 | **是** | 每页数量，默认 10 |


**响应数据：**


| 字段                 | 类型         | 说明        |
| ------------------ | ---------- | --------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`             | []PointUse | 使用记录列表    |
| `records[].code`      | string     | 积分规则 Code |
| `records[].point`     | int64      | 积分变动数量    |
| `records[].amount`    | int64      | 关联金额      |
| `records[].type`      | string     | 变动类型      |
| `records[].isFree`    | bool       | 是否为免费积分   |
| `records[].createdAt` | string     | 记录时间      |


---

#### 89. 每日任务列表

- **接口名称：** DailyTaskList
- **接口地址：** `GET /user/points/daily/task`
- **请求格式：** 无参数
- **说明：** 获取当前用户的每日任务列表及完成情况

**响应数据（数组）：**


| 字段               | 类型     | 说明        |
| ---------------- | ------ | --------- |
| `code`           | string | 任务 Code   |
| `desc`           | string | 任务描述      |
| `mode`           | string | 积分模式      |
| `point`          | int    | 完成可得积分    |
| `dailyNumber`    | int    | 每日可完成次数   |
| `completedCount` | int    | 今日已完成次数   |
| `remainingCount` | uint   | 今日剩余可完成次数 |


---

#### 90. 积分使用规则列表

- **接口名称：** UsePointRuleList
- **接口地址：** `GET /user/points/use/list`
- **请求格式：** 无参数
- **说明：** 获取系统中所有积分消耗规则

**响应数据（数组）：**


| 字段                | 类型     | 说明          |
| ----------------- | ------ | ----------- |
| `code`            | string | 规则 Code     |
| `desc`            | string | 规则描述        |
| `mode`            | string | 积分模式        |
| `point`           | int    | 消耗积分数       |
| `dailyFreeNumber` | int    | 每日免费次数      |
| `dailyFreeIsUsed` | bool   | 今日免费次数是否已使用 |
| `toBeDoneNumber`  | int    | 待完成次数       |


---

#### 91. 充值规则列表

- **接口名称：** TopUpList
- **接口地址：** `GET /user/points/topup/list`
- **请求格式：** Form（Query 参数）
- **说明：** 获取可用的积分充值套餐列表

**请求参数：**


| 参数名        | 类型     | 是否必填 | 说明                   |
| ---------- | ------ | ---- | -------------------- |
| `area`     | string | 否    | 地区代码（2位，如 `CN`、`US`） |
| `currency` | string | 否    | 货币类型（如 `CNY`、`USD`）  |


**响应数据（数组）：**


| 字段             | 类型     | 说明            |
| -------------- | ------ | ------------- |
| `id`           | int    | 套餐 ID         |
| `iosProductID` | string | iOS 应用内购商品 ID |
| `area`         | string | 地区代码          |
| `currency`     | string | 货币类型          |
| `amount`       | int    | 价格金额（单位：分）    |
| `point`        | int    | 可得积分数         |
| `giftPoint`    | int    | 赠送积分数         |


---

#### 92. 创建充值订单

- **接口名称：** CreateTopUpOrder
- **接口地址：** `POST /user/points/topup/order`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 创建积分充值订单

**请求参数：**


| 参数名       | 类型  | 是否必填  | 说明      |
| --------- | --- | ----- | ------- |
| `topUpId` | int | **是** | 充值套餐 ID |


**响应数据：**


| 字段          | 类型     | 说明         |
| ----------- | ------ | ---------- |
| `orderNo`   | string | 订单号        |
| `amount`    | int    | 支付金额（单位：分） |
| `currency`  | string | 货币类型       |
| `point`     | int    | 可得积分数      |
| `giftPoint` | int    | 赠送积分数      |
| `status`    | int    | 订单状态       |


---

#### 93. 处理 StoreKit 支付

- **接口名称：** StoreKit
- **接口地址：** `POST /user/points/topup/storekit`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 验证并处理 Apple StoreKit 2 支付结果

**请求参数：**


| 参数名                          | 类型     | 是否必填  | 说明             |
| ---------------------------- | ------ | ----- | -------------- |
| `orderNo`                    | string | **是** | 订单号            |
| `transaction.transactionId`  | string | **是** | Apple 交易 ID    |
| `transaction.transactionJWS` | string | **是** | JWS 数据（用于离线验证） |


**响应数据：**


| 字段       | 类型    | 说明   |
| -------- | ----- | ---- |
| `status` | int64 | 处理状态 |


---

#### 94. 购买规则次数

- **接口名称：** BuyRuleNumber
- **接口地址：** `POST /user/points/buy/rule/number`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 使用积分购买指定规则的使用次数

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明        |
| ---------- | ------ | ----- | --------- |
| `ruleCode` | string | **是** | 积分规则 Code |
| `number`   | int    | **是** | 购买次数      |


**响应数据：**


| 字段      | 类型    | 说明       |
| ------- | ----- | -------- |
| `count` | int64 | 购买后的剩余次数 |


---

### 收藏夹接口

**路由前缀：** `/user/collect`  

---

#### 95. 收藏列表

- **接口名称：** CollectList
- **接口地址：** `GET /user/collect/list`
- **请求格式：** Form（Query 参数）
- **说明：** 查询收藏列表，支持按类型、用户、分组筛选

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明         |
| ----------- | ------ | ----- | ---------- |
| `userId`    | int    | 否     | 查询指定用户的收藏  |
| `type`      | string | 否     | 收藏类型筛选     |
| `isPrivate` | bool   | 否     | 是否私有       |
| `groupId`   | int    | 否     | 收藏夹 ID     |
| `page`      | int64  | **是** | 页码，默认 1    |
| `size`      | int64  | **是** | 每页数量，默认 10 |


**响应数据：**


| 字段                 | 类型                | 说明                       |
| ------------------ | ----------------- | ------------------------ |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`             | []CollectListItem | 收藏列表                     |
| `records[].id`        | int64             | 收藏 ID                    |
| `records[].userId`    | int               | 用户 ID                    |
| `records[].type`      | string            | 收藏类型（agent/video/moment） |
| `records[].targetId`  | int               | 收藏目标 ID                  |
| `records[].target`    | any               | 收藏目标详情                   |
| `records[].desc`      | string            | 备注                       |
| `records[].isPrivate` | bool              | 是否私有                     |
| `records[].groupId`   | int               | 所属分组 ID                  |


---

#### 96. 添加收藏

- **接口名称：** CollectAdd
- **接口地址：** `POST /user/collect/add`
- **请求格式：** JSON
- **说明：** 添加新收藏

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明                            |
| ----------- | ------ | ----- | ----------------------------- |
| `type`      | string | **是** | 收藏类型：`agent`、`video`、`moment` |
| `targetId`  | int    | **是** | 收藏目标 ID，必须大于 0                |
| `isPrivate` | int    | **是** | 是否私有：`0` 公开，`1` 私有            |
| `desc`      | string | 否     | 备注说明                          |
| `groupId`   | int    | 否     | 放入的收藏夹 ID                     |


**响应数据：** 无

---

#### 97. 编辑收藏

- **接口名称：** CollectEdit
- **接口地址：** `PUT /user/collect/edit`
- **请求格式：** JSON
- **说明：** 修改收藏的备注或隐私设置

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明                 |
| ----------- | ------ | ----- | ------------------ |
| `id`        | int    | **是** | 收藏 ID，必须大于 0       |
| `isPrivate` | int    | **是** | 是否私有：`0` 公开，`1` 私有 |
| `desc`      | string | 否     | 新备注说明              |
| `groupId`   | int    | 否     | 新收藏夹 ID            |


**响应数据：** 无

---

#### 98. 删除收藏

- **接口名称：** CollectDel
- **接口地址：** `DELETE /user/collect/del`
- **请求格式：** JSON
- **说明：** 删除指定收藏

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                            |
| ---------- | ------ | ----- | ----------------------------- |
| `type`     | string | **是** | 收藏类型：`agent`、`video`、`moment` |
| `targetId` | int    | **是** | 收藏目标 ID，必须大于 0                |


**响应数据：** 无

---

#### 99. 创建收藏夹

- **接口名称：** AddCollectGroup
- **接口地址：** `POST /user/collect/group/add`
- **请求格式：** JSON
- **说明：** 创建新的收藏夹分组

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明                 |
| ----------- | ------ | ----- | ------------------ |
| `name`      | string | **是** | 收藏夹名称              |
| `desc`      | string | 否     | 收藏夹描述              |
| `isPrivate` | int    | **是** | 是否私有：`0` 公开，`1` 私有 |
| `parentId`  | int    | 否     | 父分组 ID（不填为顶层分组）    |


**响应数据：** 无

---

#### 100. 编辑收藏夹

- **接口名称：** UpdateCollectGroup
- **接口地址：** `PUT /user/collect/group/edit`
- **请求格式：** JSON
- **说明：** 修改收藏夹信息

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明                 |
| ----------- | ------ | ----- | ------------------ |
| `id`        | int    | **是** | 收藏夹 ID             |
| `name`      | string | **是** | 新名称                |
| `desc`      | string | 否     | 新描述                |
| `isPrivate` | int    | **是** | 是否私有：`0` 公开，`1` 私有 |
| `parentId`  | int    | 否     | 新父分组 ID            |


**响应数据：** 无

---

#### 101. 删除收藏夹

- **接口名称：** DelCollectGroup
- **接口地址：** `DELETE /user/collect/group/del/:id`
- **请求格式：** Path 参数
- **说明：** 删除指定收藏夹

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明              |
| ---- | --- | ----- | --------------- |
| `id` | int | **是** | 收藏夹 ID（Path 参数） |


**响应数据：** 无

---

#### 102. 收藏夹列表

- **接口名称：** ListCollectGroup
- **接口地址：** `GET /user/collect/group/list`
- **请求格式：** Form（Query 参数）
- **说明：** 查询收藏夹分组列表

**请求参数：**


| 参数名         | 类型     | 是否必填  | 说明               |
| ----------- | ------ | ----- | ---------------- |
| `id`        | int    | 否     | 收藏夹 ID 筛选        |
| `name`      | string | 否     | 名称搜索             |
| `isPrivate` | int    | 否     | 隐私筛选             |
| `parentId`  | int    | 否     | 父分组 ID（默认 0，查顶层） |
| `page`      | int64  | **是** | 页码，默认 1          |
| `size`      | int64  | **是** | 每页数量，默认 10       |


**响应数据：**


| 字段                     | 类型                     | 说明      |
| ---------------------- | ---------------------- | ------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`                 | []CollectGroupListItem | 收藏夹列表   |
| `records[].id`            | int                    | 收藏夹 ID  |
| `records[].name`          | string                 | 名称      |
| `records[].desc`          | string                 | 描述      |
| `records[].isPrivate`     | bool                   | 是否私有    |
| `records[].hasChildGroup` | bool                   | 是否有子分组  |
| `records[].hasCollect`    | bool                   | 是否有收藏内容 |


---

### 同城推荐接口

**路由前缀：** `/user/recommend`  

---

#### 103. 同城推荐

- **接口名称：** SameCity
- **接口地址：** `GET /user/recommend/same/city`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 根据用户当前位置推荐同城用户、智能体或动态

**请求参数：**


| 参数名               | 类型      | 是否必填 | 说明                            |
| ----------------- | ------- | ---- | ----------------------------- |
| `isMatch`         | bool    | 否    | 是否为匹配模式                       |
| `isExcludeMoment` | bool    | 否    | 是否排除动态，默认 false               |
| `matchType`       | string  | 否    | 匹配类型：`user`、`prompt`、`moment` |
| `gender`          | int     | 否    | 性别筛选：`1` 男，`2` 女              |
| `interestDeep`    | int     | 否    | 兴趣深度（1~100，越低精度越高）            |
| `distance`        | int     | 否    | 距离范围（1~150，单位 km）             |
| `coreMix`         | float64 | 否    | 相符/互补混合比例（0.0~1.0）            |


**响应数据：**


| 字段                 | 类型                     | 说明                     |
| ------------------ | ---------------------- | ---------------------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `isDailyTask`      | bool                   | 是否为每日任务                |
| `records`             | []SameCityItem         | 同城结果列表                 |
| `records[].uniqueNo`  | string                 | 唯一标识                   |
| `records[].id`        | int                    | 目标 ID                  |
| `records[].nickname`  | string                 | 昵称                     |
| `records[].banner`    | string                 | Banner 图               |
| `records[].content`   | string                 | 内容摘要                   |
| `records[].avatar`    | string                 | 头像 URL                 |
| `records[].imId`      | string                 | IM ID                  |
| `records[].type`      | string                 | 类型（user/prompt/moment） |
| `records[].likeCount` | int64                  | 点赞数                    |
| `records[].isLike`    | bool                   | 是否已点赞                  |
| `records[].tags`      | []string               | 标签列表                   |
| `records[].dist`      | float64                | 距离（km）                 |
| `records[].greetings` | []string               | 推荐打招呼语                 |
| `records[].longitude` | float64                | 经度                     |
| `records[].latitude`  | float64                | 纬度                     |
| `records[].location`  | string                 | 地址名称                   |
| `records[].attach`    | []SameCityMomentAttach | 附件信息（动态类型时）            |


---

## Content 服务

### Content 公共接口

**路由前缀：** `/content/common`  

---

#### 104. 上传文件

- **接口名称：** UploadFile
- **接口地址：** `POST /content/common/upload`
- **请求格式：** Form
- **说明：** 上传内容相关文件（图片、视频等）

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                          |
| ------ | ------ | ----- | ------------------------------------------- |
| `type` | string | **是** | 文件所属类型，可选值：`user`、`prompt`、`room`、`content` |
| `path` | string | **是** | 文件路径或 Base64 数据                             |
| `id`   | int    | **是** | 关联的业务 ID                                    |
| `file` | file   | **是** | 上传的图片/视频文件（multipart/form-data）             |


**响应数据：**


| 字段           | 类型      | 说明           |
| ------------ | ------- | ------------ |
| `type`       | string  | 文件类型         |
| `path`       | string  | 文件访问路径       |
| `frameRate`  | int     | 视频帧率（视频文件）   |
| `resolution` | string  | 视频分辨率（视频文件）  |
| `duration`   | float64 | 视频时长秒数（视频文件） |
| `isCompress` | bool    | 是否已压缩        |


---

### 动态接口

**路由前缀：** `/content/moment`  

---

#### 105. 发布动态

- **接口名称：** CreateMoment
- **接口地址：** `POST /content/moment/create`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 发布新动态（朋友圈），支持文字、图片、视频等附件

**请求参数：**


| 参数名                         | 类型       | 是否必填               | 说明                                   |
| --------------------------- | -------- | ------------------ | ------------------------------------ |
| `content`                   | string   | 否（与 attach 二选一必填）  | 文字内容                                 |
| `isOpenLocation`            | bool     | 否                  | 是否开启位置信息                             |
| `longitude`                 | float64  | 条件必填               | 经度（isOpenLocation=true 时必填）          |
| `latitude`                  | float64  | 条件必填               | 纬度（isOpenLocation=true 时必填）          |
| `location`                  | string   | 条件必填               | 地址名称（isOpenLocation=true 时必填）        |
| `publicScope`               | string   | **是**              | 公开范围：`PUBLIC`、`PRIVATE`、`FRIEND`     |
| `isTakePhotoSameStyle`      | bool     | 否                  | 是否为拍同款动态                             |
| `takePhotoSameStyleAddress` | string   | 否                  | 拍同款图片地址                              |
| `attach`                    | []Attach | 否（与 content 二选一必填） | 附件列表                                 |
| `attach[].type`             | string   | **是**              | 附件类型：`image`、`video`、`music`、`posts` |
| `attach[].source`           | string   | **是**              | 来源：`upload`、`outside`、`internal`     |
| `attach[].address`          | string   | **是**              | 附件地址                                 |
| `attach[].sort`             | int      | 否                  | 排序值                                  |
| `tags`                      | []string | 否                  | 标签列表                                 |
| `atUsers`                   | []int64  | 否                  | @ 的用户 ID 列表                          |


**响应数据：**


| 字段            | 类型    | 说明        |
| ------------- | ----- | --------- |
| `id`          | int64 | 动态 ID     |
| `isDailyTask` | bool  | 是否完成了每日任务 |


---

#### 106. 修改动态公开权限

- **接口名称：** ChangeMomentPublicMode
- **接口地址：** `PUT /content/moment/public/mode`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 修改指定动态的公开范围

**请求参数：**


| 参数名           | 类型     | 是否必填  | 说明                                 |
| ------------- | ------ | ----- | ---------------------------------- |
| `id`          | int    | **是** | 动态 ID，必须大于 0                       |
| `publicScope` | string | **是** | 新的公开范围：`PUBLIC`、`PRIVATE`、`FRIEND` |


**响应数据：** 无

---

#### 107. 删除动态

- **接口名称：** DeleteMoment
- **接口地址：** `DELETE /content/moment/:id`
- **请求格式：** Path 参数
- **需要 Authorization：** 是
- **说明：** 删除指定动态

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明                    |
| ---- | --- | ----- | --------------------- |
| `id` | int | **是** | 动态 ID（Path 参数），必须大于 0 |


**响应数据：** 无

---

#### 108. 动态列表

- **接口名称：** MomentList
- **接口地址：** `GET /content/moment/list`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 分页查询动态列表，支持多种筛选条件

**请求参数：**


| 参数名                    | 类型      | 是否必填  | 说明                  |
| ---------------------- | ------- | ----- | ------------------- |
| `userId`               | int     | 否     | 按用户 ID 筛选           |
| `userType`             | string  | 否     | 用户类型：`user`、`agent` |
| `longitude`            | float64 | 否     | 经度（位置相关筛选）          |
| `latitude`             | float64 | 否     | 纬度                  |
| `sourceType`           | string  | 否     | 来源类型筛选              |
| `IsFollow`             | bool    | 否     | 是否只显示关注用户的动态        |
| `isTakePhotoSameStyle` | bool    | 否     | 是否只显示拍同款动态          |
| `page`                 | int64   | **是** | 页码，默认 1             |
| `size`                 | int64   | **是** | 每页数量，默认 10          |


**响应数据：**


| 字段      | 类型               | 说明   |
| ------- | ---------------- | ---- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`  | []MomentListItem | 动态列表 |


**MomentListItem 字段：**


| 字段                          | 类型            | 说明        |
| --------------------------- | ------------- | --------- |
| `id`                        | int           | 动态 ID     |
| `content`                   | string        | 文字内容      |
| `isOpenLocation`            | bool          | 是否开启位置    |
| `longitude`                 | float64       | 经度        |
| `latitude`                  | float64       | 纬度        |
| `location`                  | string        | 地址名称      |
| `publicScope`               | string        | 公开范围      |
| `likeCount`                 | int           | 点赞数       |
| `commentCount`              | int           | 评论数       |
| `collectCount`              | int           | 收藏数       |
| `createdAt`                 | string        | 发布时间      |
| `isLike`                    | bool          | 当前用户是否已点赞 |
| `isCollect`                 | bool          | 当前用户是否已收藏 |
| `isTakePhotoSameStyle`      | bool          | 是否为拍同款    |
| `user`                      | UserSimple    | 发布用户信息    |
| `cover`                     | string        | 封面图 URL   |
| `takePhotoSameStyleAddress` | []string      | 拍同款图片地址列表 |
| `attach`                    | []RespAttach  | 附件列表      |
| `tags`                      | []TagTypeItem | 标签列表      |
| `atUsers`                   | []UserSimple  | @ 的用户列表   |


---

#### 109. 获取指定动态

- **接口名称：** GetMoment
- **接口地址：** `GET /content/moment/:id`
- **请求格式：** Path 参数
- **说明：** 根据动态 ID 获取动态详情

**请求参数：**


| 参数名  | 类型  | 是否必填  | 说明                    |
| ---- | --- | ----- | --------------------- |
| `id` | int | **是** | 动态 ID（Path 参数），必须大于 0 |


**响应数据：** 同 MomentListItem

---

#### 110. 动态推荐

- **接口名称：** Recomment
- **接口地址：** `GET /content/moment/recomment`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 获取系统推荐的动态列表

**请求参数：**


| 参数名                 | 类型     | 是否必填  | 说明         |
| ------------------- | ------ | ----- | ---------- |
| `excludeSourceType` | string | 否     | 排除的来源类型    |
| `page`              | int64  | **是** | 页码，默认 1    |
| `size`              | int64  | **是** | 每页数量，默认 10 |


**响应数据：** 同动态列表响应

---

#### 111. 混合推荐

- **接口名称：** MixRecommend
- **接口地址：** `GET /content/moment/mix/recomment`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 获取混合推荐内容（动态+智能体混合）

**请求参数：**


| 参数名    | 类型    | 是否必填  | 说明         |
| ------ | ----- | ----- | ---------- |
| `page` | int64 | **是** | 页码，默认 1    |
| `size` | int64 | **是** | 每页数量，默认 10 |


**响应数据：**


| 字段            | 类型                 | 说明                              |
| ------------- | ------------------ | ------------------------------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`        | []MixRecommentItem | 混合推荐列表                          |
| `records[].type` | string             | 内容类型：`agent`（智能体）或 `moment`（动态） |
| `records[].data` | any                | 对应类型的数据对象                       |


---

### 点赞接口

**路由前缀：** `/content/like`  

---

#### 112. 点赞

- **接口名称：** Like
- **接口地址：** `POST /content/like/`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 对动态或评论进行点赞

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                                        |
| ---------- | ------ | ----- | ----------------------------------------- |
| `type`     | string | **是** | 点赞目标类型：`moment`、`comment` |
| `targetId` | int64  | **是** | 目标 ID，必须大于 0                              |


> **强制说明：** `type` 必须与 `targetId` 的真实内容类型一致，且仅支持 `moment`、`comment`（例如对评论点赞必须传 `comment`）。

**响应数据：**


| 字段            | 类型    | 说明       |
| ------------- | ----- | -------- |
| `id`          | int64 | 点赞记录 ID  |
| `isDailyTask` | bool  | 是否完成每日任务 |


---

#### 113. 取消点赞

- **接口名称：** UnLike
- **接口地址：** `DELETE /content/like/del`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 取消对目标内容的点赞

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                                        |
| ---------- | ------ | ----- | ----------------------------------------- |
| `type`     | string | **是** | 点赞目标类型：`moment`、`comment` |
| `targetId` | int64  | **是** | 目标 ID，必须大于 0                              |


> **强制说明：** `type` 必须与 `targetId` 的真实内容类型一致，且仅支持 `moment`、`comment`（例如取消评论点赞必须传 `comment`）。

**响应数据：** 无

---

### 评论接口

**路由前缀：** `/content/comment`  

---

#### 114. 创建评论

- **接口名称：** Create
- **接口地址：** `POST /content/comment/`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 发布评论，支持一级评论和回复

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                              |
| ---------- | ------ | ----- | ------------------------------- |
| `type`     | string | **是** | 评论目标类型：`moment` |
| `targetId` | int64  | **是** | 目标 ID，必须大于 0                    |
| `content`  | string | **是** | 评论内容，最少 1 字符                    |
| `parentId` | int64  | 否     | 父评论 ID（回复时填写，必须大于 0）            |


> **强制说明：** `type` 必须与 `targetId` 的真实内容类型一致，且评论仅支持 `moment`。

**响应数据：**


| 字段            | 类型    | 说明       |
| ------------- | ----- | -------- |
| `id`          | int64 | 评论 ID    |
| `isDailyTask` | bool  | 是否完成每日任务 |


---

#### 115. 评论列表

- **接口名称：** List
- **接口地址：** `GET /content/comment/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询评论列表，根据传入参数组合决定查询策略

**查询策略说明：**

| 场景 | 传入参数 | 行为 |
|---|---|---|
| 查询根评论列表（默认） | 不传 `rootId`、`parentId`、`id` | 返回 `root_id = 0` 的顶级评论 |
| 查询顶级评论下的所有子评论 | 仅传 `rootId` | 返回该 `rootId` 下的全部回复 |
| 查询某条评论的直接回复 | 仅传 `parentId` | 返回该 `parentId` 的直接子评论 |
| 惰性加载子评论（分段） | 同时传 `rootId` 和 `id` | 返回 `root_id = rootId` 且 `id <= 指定id` 的评论 |
| 查询单条评论 | 仅传 `id` | 返回该条评论 |

**请求参数：**


| 参数名        | 类型     | 是否必填  | 说明                              |
| ---------- | ------ | ----- | ------------------------------- |
| `id`       | int64  | 否     | 指定评论 ID；与 `rootId` 同时传时用于惰性加载截止位置 |
| `type`     | string | **是** | 评论目标类型：`moment` |
| `targetId` | int64  | **是** | 目标 ID，必须大于 0                    |
| `parentId` | int64  | 否     | 父评论 ID，传入时查询该评论的直接回复            |
| `rootId`   | int64  | 否     | 顶级评论 ID，传入时查询该顶级评论下的所有子评论       |
| `sort`     | string | 否     | 排序方式：`Latest`（最新）、`Hot`（最热）     |
| `page`     | int64  | **是** | 页码，默认 1                         |
| `size`     | int64  | **是** | 每页数量，默认 10                      |


> **强制说明：** 查询评论时 `type` 必须与 `targetId` 对应内容类型一致，且仅支持 `moment`，禁止跨类型查询。

**响应数据：**


| 字段                  | 类型                | 说明        |
| ------------------- | ----------------- | --------- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`              | []CommentListItem | 评论列表      |
| `records[].id`         | int64             | 评论 ID     |
| `records[].type`       | string            | 评论类型      |
| `records[].targetId`   | int64             | 目标 ID     |
| `records[].content`    | string            | 评论内容      |
| `records[].rootId`     | int64             | 根评论 ID    |
| `records[].replyCount` | int64             | 回复数       |
| `records[].createdAt`  | string            | 发布时间      |
| `records[].user`       | UserSimple        | 评论用户      |
| `records[].replyUser`  | UserSimple        | 被回复的用户    |
| `records[].reply`      | CommentListItem   | 被回复的评论内容  |
| `records[].likeCount`  | int64             | 点赞数       |
| `records[].isLike`     | bool              | 当前用户是否已点赞 |


---

#### 116. 删除评论

- **接口名称：** Delete
- **接口地址：** `DELETE /content/comment/:id`
- **请求格式：** Path 参数
- **需要 Authorization：** 是
- **说明：** 删除指定评论

**请求参数：**


| 参数名  | 类型    | 是否必填  | 说明                    |
| ---- | ----- | ----- | --------------------- |
| `id` | int64 | **是** | 评论 ID（Path 参数），必须大于 0 |


**响应数据：** 无

---

### 内容分类接口

**路由前缀：** `/content/type`  

---

#### 117. 分类列表

- **接口名称：** ListType
- **接口地址：** `GET /content/type/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询内容分类列表

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                      |
| ------ | ------ | ----- | --------------------------------------- |
| `type` | string | **是** | 分类所属类型：`moment`、`video`、`posts`、`music` |
| `name` | string | 否     | 分类名称搜索                                  |
| `page` | int64  | **是** | 页码，默认 1                                 |
| `size` | int64  | **是** | 每页数量，默认 10                              |


**响应数据：**


| 字段            | 类型            | 说明    |
| ------------- | ------------- | ----- |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`        | []TagTypeItem | 分类列表  |
| `records[].id`   | int64         | 分类 ID |
| `records[].type` | string        | 所属类型  |
| `records[].name` | string        | 分类名称  |


---

### 内容标签接口

**路由前缀：** `/content/tag`  

---

#### 118. 创建标签

- **接口名称：** CreateTag
- **接口地址：** `POST /content/tag/create`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 创建内容标签

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                      |
| ------ | ------ | ----- | --------------------------------------- |
| `type` | string | **是** | 标签所属类型：`moment`、`video`、`posts`、`music` |
| `name` | string | **是** | 标签名称，最少 1 字符                            |


**响应数据：**


| 字段   | 类型    | 说明      |
| ---- | ----- | ------- |
| `id` | int64 | 新建标签 ID |


---

#### 119. 标签列表

- **接口名称：** ListTag
- **接口地址：** `GET /content/tag/list`
- **请求格式：** Form（Query 参数）
- **说明：** 分页查询内容标签列表

**请求参数：**


| 参数名    | 类型     | 是否必填  | 说明                                      |
| ------ | ------ | ----- | --------------------------------------- |
| `type` | string | **是** | 标签所属类型：`moment`、`video`、`posts`、`music` |
| `name` | string | 否     | 标签名称搜索                                  |
| `page` | int64  | **是** | 页码，默认 1                                 |
| `size` | int64  | **是** | 每页数量，默认 10                              |


**响应数据：** 同分类列表响应

---

### 视频接口

**路由前缀：** `/content/video`  

---

#### 120. 发布视频

- **接口名称：** CreateVideo
- **接口地址：** `POST /content/video/create`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 发布新视频内容

**请求参数：**


| 参数名              | 类型      | 是否必填  | 说明                               |
| ---------------- | ------- | ----- | -------------------------------- |
| `title`          | string  | **是** | 视频标题，最少 1 字符                     |
| `cover`          | string  | 否     | 封面图 URL                          |
| `videoPath`      | string  | **是** | 视频文件 URL                         |
| `isCompress`     | bool    | 否     | 是否压缩视频                           |
| `publicScope`    | string  | **是** | 公开范围：`PUBLIC`、`PRIVATE`、`FRIEND` |
| `isOpenLocation` | bool    | 否     | 是否开启位置信息                         |
| `longitude`      | float64 | 条件必填  | 经度（isOpenLocation=true 时必填）      |
| `latitude`       | float64 | 条件必填  | 纬度（isOpenLocation=true 时必填）      |
| `location`       | string  | 条件必填  | 地址名称（isOpenLocation=true 时必填）    |
| `types`          | []int64 | 否     | 视频分类 ID 列表                       |
| `tags`           | []int64 | 否     | 视频标签 ID 列表                       |


**响应数据：** 无

---

#### 121. 视频列表

- **接口名称：** ListVideo
- **接口地址：** `GET /content/video/list`
- **请求格式：** Form（Query 参数）
- **鉴权：** 无需 Token
- **说明：** 分页查询视频列表

**请求参数：**


| 参数名           | 类型     | 是否必填  | 说明                                 |
| ------------- | ------ | ----- | ---------------------------------- |
| `userId`      | int64  | 否     | 按用户 ID 筛选                          |
| `title`       | string | 否     | 按标题搜索                              |
| `publicScope` | string | 否     | 公开范围筛选：`PUBLIC`、`PRIVATE`、`FRIEND` |
| `page`        | int64  | **是** | 页码，默认 1                            |
| `size`        | int64  | **是** | 每页数量，默认 10                         |


**响应数据：**


| 字段                    | 类型              | 说明     |
| --------------------- | --------------- | ------ |
| `current`   | int   | 当前页码 |
| `size`      | int   | 每页数量 |
| `total`     | int64 | 总记录数 |
| `totalPage` | int   | 总页数   |
| `records`                | []VideoListItem | 视频列表   |
| `records[].id`           | int64           | 视频 ID  |
| `records[].userId`       | int64           | 发布者 ID |
| `records[].title`        | string          | 标题     |
| `records[].cover`        | string          | 封面 URL |
| `records[].url`          | string          | 视频 URL |
| `records[].duration`     | int64           | 时长（秒）  |
| `records[].frameRate`    | int64           | 帧率     |
| `records[].width`        | int64           | 视频宽度   |
| `records[].height`       | int64           | 视频高度   |
| `records[].likeCount`    | int64           | 点赞数    |
| `records[].commentCount` | int64           | 评论数    |
| `records[].collectCount` | int64           | 收藏数    |
| `records[].isLike`       | bool            | 是否已点赞  |
| `records[].createdAt`    | string          | 发布时间   |
| `records[].user`         | UserSimple      | 发布者信息  |
| `records[].types`        | []VideoTagType  | 视频分类   |
| `records[].tags`         | []VideoTagType  | 视频标签   |


---

#### 122. 编辑视频

- **接口名称：** UpdateVideo
- **接口地址：** `PUT /content/video/update`
- **请求格式：** JSON
- **需要 Authorization：** 是
- **说明：** 修改视频基本信息

**请求参数：**


| 参数名              | 类型      | 是否必填  | 说明                               |
| ---------------- | ------- | ----- | -------------------------------- |
| `id`             | int64   | **是** | 视频 ID，必须大于 0                     |
| `title`          | string  | **是** | 新标题                              |
| `cover`          | string  | 否     | 新封面 URL                          |
| `publicScope`    | string  | **是** | 公开范围：`PUBLIC`、`PRIVATE`、`FRIEND` |
| `isOpenLocation` | bool    | 否     | 是否开启位置                           |
| `longitude`      | float64 | 条件必填  | 经度（isOpenLocation=true 时必填）      |
| `latitude`       | float64 | 条件必填  | 纬度（isOpenLocation=true 时必填）      |
| `location`       | string  | 条件必填  | 地址名称（isOpenLocation=true 时必填）    |
| `types`          | []int64 | 否     | 分类 ID 列表                         |
| `tags`           | []int64 | 否     | 标签 ID 列表                         |


**响应数据：** 无

---

#### 123. 删除视频

- **接口名称：** DeleteVideo
- **接口地址：** `DELETE /content/video/delete`
- **请求格式：** JSON (Path 参数方式)
- **需要 Authorization：** 是
- **说明：** 删除指定视频

**请求参数：**


| 参数名  | 类型    | 是否必填  | 说明                    |
| ---- | ----- | ----- | --------------------- |
| `id` | int64 | **是** | 视频 ID（Path 参数），必须大于 0 |


**响应数据：** 无

---

### 搜索接口

**路由前缀：** `/content/search`  

---

#### 124. 全局搜索

- **接口名称：** Search
- **接口地址：** `GET /content/search/search`
- **请求格式：** Form（Query 参数）
- **说明：** 全局关键词搜索，支持多种内容类型

**请求参数：**


| 参数名       | 类型     | 是否必填  | 说明                                           |
| --------- | ------ | ----- | -------------------------------------------- |
| `keyword` | string | **是** | 搜索关键词，最少 1 字符                                |
| `type`    | string | **是** | 搜索类型：`moment`、`video`、`user`、`prompt`、`room` |
| `page`    | int64  | **是** | 页码，默认 1                                      |
| `size`    | int64  | **是** | 每页数量，默认 10                                   |


**响应数据：**


| 字段      | 类型    | 说明                                    |
| ------- | ----- | ------------------------------------- |
| `count` | int64 | 搜索结果总数                                |
| `data`  | any   | 搜索结果（格式根据 type 动态变化，对应各类型的列表 Item 结构） |


---

> **注意事项：**
>
> 1. 所有分页接口中 `page` 默认值为 `1`，`size` 默认值为 `10`，前端应始终传递这两个参数
> 2. 涉及地理位置的接口，请同时在 `X-User-Location` Header 中传递用户位置信息
> 3. 标注 `JwtAuth` 的接口组下所有接口均强制要求 `Authorization: Bearer <token>`
> 4. 部分接口虽然只使用 `HeaderAuth`，但业务逻辑上需要用户登录才能正确执行（如获取当前用户信息、修改个人资料等），建议携带 Token
> 5. 文件上传建议先调用对应服务的上传接口获取 URL，再在业务接口中使用该 URL

