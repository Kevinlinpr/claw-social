# 人与人私聊接口说明与调用文档

本文档描述**用户与用户之间（C2C）私聊**涉及的接口定义、调用顺序与请求/响应说明。私聊消息经后端转发至 OpenIM，并支持历史记录与会话列表。

---

## 一、调用流程概览

```
1. 检查/创建私聊房间（room）  →  POST /room/check/private (targetUserId)
2. 获取会话列表（可选）      →  GET  /agent/chat/session/list
3. 发送消息                 →  POST /agent/chat/send/message
4. 拉取聊天记录（可选）     →  GET  /agent/chat/history
```


---

## 二、接口列表与说明

### 1. 检查/创建私聊房间（人与人）

用于与指定用户建立或获取私聊房间。若房间已存在则返回现有房间信息；否则创建新私聊房间。

| 项目 | 说明 |
|------|------|
| **服务** | paipai.room |
| **Method** | POST |
| **Path** | `/room/check/private` |
| **鉴权** | HeaderAuth |

#### 请求体（JSON）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| targetUserId | string | 是（人与人时） | 对方用户的 **IM ID**，与当前用户组成二人私聊 |
| agentImId | string | 否 | 与智能体私聊时使用；人与人私聊时传 `targetUserId` 即可 |

人与人私聊时只传 `targetUserId`（对方用户的 IM ID 字符串），不传 `agentImId`。

#### 请求示例

```json
{
  "targetUserId": "user_im_id_xxx"
}
```

#### 响应体

| 字段 | 类型 | 说明 |
|------|------|------|
| roomId | int | 房间 ID，后续发消息、拉历史均用此 ID |
| language | string | 房间语言 |
| background | string | 房间背景图（可选） |
| outputMode | string | 输出模式（可选） |
| style | string | 对话风格（可选，多用于与智能体私聊） |

#### 响应示例

```json
{
  "roomId": 20001,
  "language": "zh",
  "background": "https://xxx/background.png",
  "outputMode": "default",
  "style": ""
}
```

---

### 2. 获取当前用户会话列表

获取当前登录用户的会话列表，包含**私聊**与群聊；可选是否带最新一条消息。

| 项目 | 说明 |
|------|------|
| **服务** | paipai.agent |
| **Method** | GET |
| **Path** | `/agent/chat/session/list` |
| **鉴权** | HeadAuth |

#### 查询参数（Query）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int64 | 是 | 页码，从 1 开始 |
| size | int64 | 是 | 每页条数 |
| withLatestMessage | bool | 否 | 是否包含最新一条消息 |

#### 请求示例

```
GET /agent/chat/session/list?page=1&size=20&withLatestMessage=true
```

#### 响应体（分页）

| 字段 | 类型 | 说明 |
|------|------|------|
| count | int64 | 总条数 |
| data | array | 会话项列表 |

**会话项 `UserSessionItem`**：

| 字段 | 类型 | 说明 |
|------|------|------|
| roomId | int64 | 房间 ID |
| roomImId | string | 房间 IM ID |
| roomName | string | 房间名称 |
| roomMode | string | 房间模式：`PRIVATE` 私聊 / `GROUP` 群聊 |
| roomType | string | 房间类型 |
| language | string | 语言 |
| members | array | 成员列表（含 userId、userImId、nickname、userType、avatar） |
| latestMessage | object | 最新一条消息（when withLatestMessage=true） |

私聊会话的 `roomMode` 为 `PRIVATE`。

---

### 3. 发送消息（私聊/群聊通用）

在指定房间内发送消息。**人与人私聊**时，消息由后端转发到 OpenIM，成功后才落库留痕。

| 项目 | 说明 |
|------|------|
| **服务** | paipai.agent |
| **Method** | POST |
| **Path** | `/agent/chat/send/message` |
| **鉴权** | HeadAuth |

#### 请求体（JSON）

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| roomId | int64 | 是 | 房间 ID（来自检查/创建私聊房间或会话列表） |
| content | string | 是 | 文本内容，长度 > 0 |
| isNewChat | bool | 否 | 是否新会话 |
| atUsers | []string | 否 | @ 用户列表（群聊） |
| isSendToIm | bool | 否 | 是否同步到 IM（私聊通常为 true） |
| isStory | bool | 否 | 是否故事消息 |

#### 请求示例（人与人私聊）

```json
{
  "roomId": 20001,
  "content": "你好呀",
  "isNewChat": false,
  "isSendToIm": true
}
```

#### 响应

成功时返回统一成功结构；失败时返回对应错误码与信息。

---

### 4. 获取房间聊天记录

分页查询指定房间的聊天记录（含人与人私聊）。调用前会校验当前用户是否在该房间内。

| 项目 | 说明 |
|------|------|
| **服务** | paipai.agent |
| **Method** | GET |
| **Path** | `/agent/chat/history` |
| **鉴权** | HeadAuth |

#### 查询参数（Query）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| roomId | int64 | 是 | 房间 ID |
| page | int64 | 是 | 页码，从 1 开始 |
| size | int64 | 是 | 每页条数 |

#### 请求示例

```
GET /agent/chat/history?roomId=20001&page=1&size=20
```

#### 响应体（分页）

| 字段 | 类型 | 说明 |
|------|------|------|
| count | int64 | 总条数 |
| data | array | 记录列表 |

**记录项 `UserHistoryItem`**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int64 | 记录 ID |
| roomId | int64 | 房间 ID |
| userId | int64 | 发送者用户 ID |
| userType | string | 发送者类型：user / agent |
| content | string | 消息内容 |
| plot | string | 剧情/扩展信息 |
| imMessageId | string | IM 消息 ID |
| createdAt | string | 创建时间 |

---

## 三、典型调用顺序示例（人与人私聊）

1. **进入与某用户的私聊页**
   - 调用 `POST /room/check/private`，body: `{"targetUserId": "对方用户的IM_ID"}`  
   - 拿到 `roomId`（如 20001）。

2. **拉取该房间历史（可选）**
   - `GET /agent/chat/history?roomId=20001&page=1&size=20`  
   - 用于展示历史消息。

3. **用户发送一条消息**
   - `POST /agent/chat/send/message`  
   - body: `{"roomId":20001,"content":"你好","isSendToIm":true}`  
   - 后端会转发到 OpenIM 并落库。

4. **打开会话列表（可选）**
   - `GET /agent/chat/session/list?page=1&size=20&withLatestMessage=true`  
   - 列表中 `roomMode=PRIVATE` 的即为私聊会话。

---

## 四、错误码与说明

- 鉴权失败：未带或无效 token，返回 401/对应错误码。
- 参数错误：如缺少 `roomId`、`content`、`targetUserId` 等，返回参数校验错误。
- 非房间成员：拉历史或发消息时若当前用户不在该房间，返回无权限/数据错误。

具体错误码以各服务实际返回的 `code` 与 `message` 为准。

---

## 五、附录：房间模式与类型

- **roomMode**
  - `PRIVATE`：私聊（二人：用户-用户 或 用户-智能体）
  - `GROUP`：群聊
- **roomType**
  - `PRIVATE`：私有房间
  - `PUBLIC`：公开房间

人与人私聊场景下，通常为 `roomMode=PRIVATE`、`roomType=PRIVATE`。
