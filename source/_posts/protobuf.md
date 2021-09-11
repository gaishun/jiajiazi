---
title: protobuf
date: 2021-09-11 09:09:41
tags:
- protobuf
- grpc
---
## protobuf

gRPC传输用这个挺好的，跨语言调用

- 足够简单
- 序列化后体积小
- 解析速度比XML块
- 多语言支持
- 兼容性好

## proto3

这里就先不提proto2了

文件后缀名是`.proto`

### Message  &  intersection

```protobuf
syntax = "proto3";//compile is proto3

message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
}
```

#### Type

[Type]: https://developers.google.com/protocol-buffers/docs/proto3#json	"Type"

```protobuf
double, float, int32, int64, uint32, uint64, sint32, sint64,(s* is more effcient in negative number)
fixed32, fixed64, sfixed32, sfixed64, bool, string, bytes.

repeated //by index
Timestamp
Duration
Struct
ListValue
```

###### 默认值：

```protobuf
string ""
bytes ""
bool false
numeric 0
enums 0
message fields are language-dependent.
```

#### enum

```protobuf
message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
  enum Corpus {
    UNIVERSAL = 0;
    WEB = 1;
    IMAGES = 2;
    LOCAL = 3;
    NEWS = 4;
    PRODUCTS = 5;
    VIDEO = 6;
  }
  Corpus corpus = 4;
}
////////////////////////////////////////////////////////////
message MyMessage1 {
  enum EnumAllowingAlias {
    option allow_alias = true;//same variable in different enums, need this options. 
    UNKNOWN = 0;
    STARTED = 1;
    RUNNING = 1;
  }
}
message MyMessage2 {
  enum EnumNotAllowingAlias {
    UNKNOWN = 0;
    STARTED = 1;
    // RUNNING = 1;  // Uncommenting this line will cause a compile error inside Google and a warning message outside.
  }
}

```

#### using other message

```protobuf
message SearchResponse {
  repeated Result results = 1;
}

message Result {
  string url = 1;
  string title = 2;
  repeated string snippets = 3;
}
```

#### Importing Definitions 

> JAVA is not suitable

#### Nested Types

> as deeply as U like

```
//1**************************
//straight Nested another message
message SearchResponse {
  repeated Result results = 1;
}

message Result {
  string url = 1;
  string title = 2;
  repeated string snippets = 3;
}

//2**************************
//nest partial message
message SomeOtherMessage {
  SearchResponse.Result result = 1;
}
```

#### any



#### one of

> have many fields but use at most one field once.
>
> a oneof cannot be repeated.

```protobuf
message SampleMessage {
  oneof test_oneof {
    string name = 4;
    SubMessage sub_message = 9;
  }
}

SampleMessage message;
message.set_name("name");
CHECK(message.has_name());
message.mutable_sub_message();   // Will clear name field.
CHECK(!message.has_name());
```

#### Maps

```protobuf
map<string, Project> projects = 3;
```

## Define Services

```protobuf
service SearchService {
  rpc Search(SearchRequest) returns (SearchResponse);
}
```



## Generating Classes

[C++, C#, Java, JavaScript, PHP, Ruby, Python]: https://github.com/protocolbuffers/protobuf/releases
[GO]: https://github.com/golang/protobuf/releases

```shell
protoc --proto_path=IMPORT_PATH --cpp_out=DST_DIR --java_out=DST_DIR --python_out=DST_DIR --go_out=DST_DIR --ruby_out=DST_DIR --objc_out=DST_DIR --csharp_out=DST_DIR path/to/file.proto
# *_out point the DST_DIR of the output
# proto_path points the import_PATH?
# path/to/file.proto is the file be compiling.
```


