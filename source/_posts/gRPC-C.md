---
title: gRPC-C++
date: 2021-09-12 13:21:01
tags:
- grpc
- c++
---

之前搞了Go版本的，但是C++版本的感觉编码要复杂一些，提前学一下，说不定以后就用得上。

<!--more -->

### Environment

先要搞好环境，这里是用的cmake的版本是3.16.3, ubuntu 18.04。

```shell
#可以添加MY_INSTALL_DIR环境变量
mkdir ~/.local
export MY_INSTALL_DIR=~/.local

#安装ubuntu的一些环境
$ sudo apt install -y build-essential autoconf libtool pkg-config
#git下grpc的包grpc 290多MB，还有其他的子模块500MB左右。
$ git clone --recurse-submodules -b v1.38.0 https://github.com/grpc/grpc
#build and install gRPC, protocol buffers, and Abseil
$ cd grpc
#下载子模块
$ mkdir -p cmake/build
$ pushd cmake/build
#cmake
#DCMAKE_INSTALL_PREFIX D是Define的意思，后面的是要编译的文件所在的路径
$ cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR \
      ../..
#make
$ make -j
$ sudo make install
$ popd
$ mkdir -p third_party/abseil-cpp/cmake/build
$ pushd third_party/abseil-cpp/cmake/build
$ cmake -DCMAKE_INSTALL_PREFIX=$MY_INSTALL_DIR \
      -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      ../..
$ make -j
$ make install
$ popd
```

以上没有问题基本就没有问题了，测试一下测试用例

```shell
$ cd examples/cpp/helloworld

$ mkdir -p cmake/build
$ pushd cmake/build
$ cmake -DCMAKE_PREFIX_PATH=$MY_INSTALL_DIR ../..
$ make -j
```

没问题就可以了，开始写代码。

### Prepare

#### test.proto file context

proto文件仍然用之前go语言时用的文件`test.proto`

```protobuf
syntax = "proto3";

package grpc_test;
option go_package="../../grpc_test";
// The greeting service definition.
// 单请求、回复rpc
service Greeter {
  // Sends a greeting
  rpc SayHello (HelloRequest) returns (HelloReply) {}
  rpc SayHelloAll (stream HelloRequest) returns (stream HelloReply) {}
}
// The request message containing the user's name.
message HelloRequest {
  string name = 1;
}

// The response message containing the greetings
message HelloReply {
  string message = 1;
}
```

#### compile for pb

这里用的是grpc make install时候安装的protoc，版本是3.15.8

```shell
protoc --grpc_out=. --plugin=protoc-gen-grpc=`which grpc_cpp_plugin` test.proto 
# get test.grpc.pb.h & test.grpc.pb.cc
protoc --cpp_out=. test.proto
# get test.pb.h & test.pb.cc
```

然后就可以得到`test.pb.h` ，`test.pb.cc`，`test.grpc.pb.h`和`test.grpc.pb.cc`四个文件，前两个包含除了`Service`的部分，后面的包含具体的`Message`部分，然后就可以编写`client.cpp`和`server.cpp`两个文件。

### FILE

#### struct & CMakeList.txt

项目的结构是这样的：

```c++
header/				//存放头文件
├── test.grpc.pb.h
└── test.pb.h
target/				//存放有main函数的cpp文件，用来生成可执行文件
├── client.cpp
└── server.cpp
source/             //存放源文件
├── test.grpc.pb.cc
└── test.pb.cc
CMakeLists.txt
common.cmake 
```

根据目录结构写出`CMakeList.txt`文件，参照了`grpc`官方的`CMakeList.txt`，其中有一个比较重要的`common.cmake`的引用，但是我还没看明白他是怎么区分的。之后再说，`CMakeList.txt`文件内容如下：

```cmake
cmake_minimum_required(VERSION 3.16.3)
project(grpcpp_test)

#用已经写好的cmake模块作为辅助
include(./common.cmake)
#stdc++=11
set(CMAKE_CXX_STANDARD 11)
#将这两个文件夹中的内容加入编译范围
AUX_SOURCE_DIRECTORY( source/ SOURCEFILE)
AUX_SOURCE_DIRECTORY( header/ HEADER)
#先编译出链接文件
add_library(DEPEND ${SOURCEFILE} ${HEADER})
target_link_libraries(DEPEND
        ${_GRPC_GRPCPP}
        ${_PROTOBUF_LIBPROTOBUF})
#对每个需要作为执行目标的文件进行编译同时加入编译选项
foreach(_target
        client server)
    add_executable(${_target} target/${_target}.cpp)
    target_link_libraries(${_target}
            DEPEND
            ${_GRPC_GRPCPP}
            ${_PROTOBUF_LIBPROTOBUF})
endforeach()
```

#### common.cmake

`common.cmake`文件内容较长，这里也贴出来吧，建议通过目录索引阅读：

```cmake
# Copyright 2018 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# cmake build file for C++ route_guide example.
# Assumes protobuf and gRPC have been installed using cmake.
# See cmake_externalproject/CMakeLists.txt for all-in-one cmake build
# that automatically builds all the dependencies before building route_guide.

cmake_minimum_required(VERSION 3.5.1)

set (CMAKE_CXX_STANDARD 11)

if(MSVC)
  add_definitions(-D_WIN32_WINNT=0x600)
endif()

find_package(Threads REQUIRED)

if(GRPC_AS_SUBMODULE)
  # One way to build a projects that uses gRPC is to just include the
  # entire gRPC project tree via "add_subdirectory".
  # This approach is very simple to use, but the are some potential
  # disadvantages:
  # * it includes gRPC's CMakeLists.txt directly into your build script
  #   without and that can make gRPC's internal setting interfere with your
  #   own build.
  # * depending on what's installed on your system, the contents of submodules
  #   in gRPC's third_party/* might need to be available (and there might be
  #   additional prerequisites required to build them). Consider using
  #   the gRPC_*_PROVIDER options to fine-tune the expected behavior.
  #
  # A more robust approach to add dependency on gRPC is using
  # cmake's ExternalProject_Add (see cmake_externalproject/CMakeLists.txt).

  # Include the gRPC's cmake build (normally grpc source code would live
  # in a git submodule called "third_party/grpc", but this example lives in
  # the same repository as gRPC sources, so we just look a few directories up)
  add_subdirectory(../../.. ${CMAKE_CURRENT_BINARY_DIR}/grpc EXCLUDE_FROM_ALL)
  message(STATUS "Using gRPC via add_subdirectory.")

  # After using add_subdirectory, we can now use the grpc targets directly from
  # this build.
  set(_PROTOBUF_LIBPROTOBUF libprotobuf)
  set(_REFLECTION grpc++_reflection)
  if(CMAKE_CROSSCOMPILING)
    find_program(_PROTOBUF_PROTOC protoc)
  else()
    set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)
  endif()
  set(_GRPC_GRPCPP grpc++)
  if(CMAKE_CROSSCOMPILING)
    find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
  else()
    set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:grpc_cpp_plugin>)
  endif()
elseif(GRPC_FETCHCONTENT)
  # Another way is to use CMake's FetchContent module to clone gRPC at
  # configure time. This makes gRPC's source code available to your project,
  # similar to a git submodule.
  message(STATUS "Using gRPC via add_subdirectory (FetchContent).")
  include(FetchContent)
  FetchContent_Declare(
    grpc
    GIT_REPOSITORY https://github.com/grpc/grpc.git
    # when using gRPC, you will actually set this to an existing tag, such as
    # v1.25.0, v1.26.0 etc..
    # For the purpose of testing, we override the tag used to the commit
    # that's currently under test.
    GIT_TAG        vGRPC_TAG_VERSION_OF_YOUR_CHOICE)
  FetchContent_MakeAvailable(grpc)

  # Since FetchContent uses add_subdirectory under the hood, we can use
  # the grpc targets directly from this build.
  set(_PROTOBUF_LIBPROTOBUF libprotobuf)
  set(_REFLECTION grpc++_reflection)
  set(_PROTOBUF_PROTOC $<TARGET_FILE:protoc>)
  set(_GRPC_GRPCPP grpc++)
  if(CMAKE_CROSSCOMPILING)
    find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
  else()
    set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:grpc_cpp_plugin>)
  endif()
else()
  # This branch assumes that gRPC and all its dependencies are already installed
  # on this system, so they can be located by find_package().

  # Find Protobuf installation
  # Looks for protobuf-config.cmake file installed by Protobuf's cmake installation.
  set(protobuf_MODULE_COMPATIBLE TRUE)
  find_package(Protobuf CONFIG REQUIRED)
  message(STATUS "Using protobuf ${Protobuf_VERSION}")

  set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
  set(_REFLECTION gRPC::grpc++_reflection)
  if(CMAKE_CROSSCOMPILING)
    find_program(_PROTOBUF_PROTOC protoc)
  else()
    set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)
  endif()

  # Find gRPC installation
  # Looks for gRPCConfig.cmake file installed by gRPC's cmake installation.
  find_package(gRPC CONFIG REQUIRED)
  message(STATUS "Using gRPC ${gRPC_VERSION}")

  set(_GRPC_GRPCPP gRPC::grpc++)
  if(CMAKE_CROSSCOMPILING)
    find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
  else()
    set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:gRPC::grpc_cpp_plugin>)
  endif()
endif()

```

然后就是写`server.cpp`和`client.cpp`两个文件

#### server.cpp

```c++
//
// Created by gs on 2021/9/12.
//

#include "../header/test.grpc.pb.h"
#include <iostream>
#include <string>
#include <grpcpp/grpcpp.h>

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using grpc::ServerReaderWriter;
using grpc_test::Greeter;
using grpc_test::HelloReply;
using grpc_test::HelloRequest;


//继承Greeter类的Service类,这个类是继承了grpc::Service类的子类
class GreeterServiceImpl final : public Greeter::Service{

    //调用通过request获取请求信息，通过response返回信息。
    Status SayHello(ServerContext* context, const HelloRequest* request, HelloReply* response) override{
        std::string prefix = "hello";
        //这里就是返回值了
        response->set_message(prefix + request->name());
        return Status::OK;
    }


    //这个用来打印日志使用。
    void print (std::string temp){
        char *a = new char[4];
        std::cout<<temp<<a<<std::endl;
    }
    //双向流式rpc服务
    Status SayHelloAll(ServerContext* context, ServerReaderWriter< HelloReply, HelloRequest>* stream) override{
        grpc_test::HelloReply rep;
        grpc_test::HelloRequest req;
        std::string str;
        char *a = new char[4];
        int count = 0;
        while(stream->Read(&req)){
            str = req.name();
            sprintf(a,"%3d\n",count++);
            str += a;
            print(str);
            rep.set_message(str);
            stream->Write(rep);
        }
        return Status::OK;
    }

public:
    ~GreeterServiceImpl() override= default;
    GreeterServiceImpl() = default;
    bool Run (){
        std::string address = "localhost:4306";
        //不知道
        grpc::EnableDefaultHealthCheckService(true);
        //这个就是相当于添加了一些启动服务的options
        ServerBuilder builder;
        builder.AddListeningPort(address, grpc::InsecureServerCredentials());
        builder.RegisterService(this);
        //启动服务
        std::unique_ptr<Server> server(builder.BuildAndStart());
        std::cout<<"start successful listening on "<<address<<std::endl;
        //保持。
        server->Wait();
        return true;
    }
};

int main (){
    GreeterServiceImpl service;
    service.Run();
}
```

#### client.cpp

```c++
//
// Created by gs on 2021/9/12.
//
#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>
#include <thread>
#include "../header/test.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;

using grpc_test::Greeter;
using grpc_test::HelloRequest;
using grpc_test::HelloReply;

//自己创建一个类，里面将grpc文件里面的Service_name的Stub作为成员变量进行使用。
//这个stud现在理解就是作为整个client的一个载体，放在任何一个类中都可以。
class GreeterClient {
    std::unique_ptr<Greeter::Stub> _stub;
public:
    //用一个channel来构建这个客户端，也就是用一个连接来实例化这个类。
    GreeterClient(std::shared_ptr<grpc::Channel> channel):
    _stub(Greeter::NewStub(channel)){};
    
    std::string SayHello (const std::string &user){
        grpc_test::HelloRequest request;
        request.set_name(user);
        grpc_test::HelloReply rep;
        //这些ctx应该有什么作用，但是咱也不知道，等查一下官方的文档。
        grpc::ClientContext ctx;

        Status status = _stub->SayHello(&ctx, request, &rep);

        if (status.ok()){
            return rep.message();
        }else {
            std::cout<<"SayHello err"<<std::endl;
            return "RPC failed";
        }
    }

    std::string SayHelloAll (){
        grpc::ClientContext ctx;
        std::shared_ptr<grpc::ClientReaderWriter<grpc_test::HelloRequest,grpc_test::HelloReply >> stream(
                _stub->SayHelloAll(&ctx)
                );
        //用一个线程来执行读操作，没有新内容的时候这个线程是一直阻塞的。
        std::thread Read([stream](){
            grpc_test::HelloReply rep;
            while(stream->Read(&rep)){
                std::cout<<rep.message()<<std::endl;
            }
        });
        grpc_test::HelloRequest req;
        req.set_name("hello world");
        for(int i=0;i<100;i++){
            stream->Write(req);
        }
        stream->WritesDone();//写操作完成
        Read.join();//等待Read线程结束
        grpc::Status status = stream->Finish();//关闭流
        if (!status.ok()){
          std::cout<<"client finish stream failed, msg is "<<status.error_message()<<std::endl;
          return "client finish stream failed";
        }
        return "success";
    }
};

int main (){
    //访问路径
    std::string target_str = "localhost:4306";
    //这里的channel我理解就是一个连接的意思
    GreeterClient greeter(
            grpc::CreateChannel(target_str,grpc::InsecureChannelCredentials()));
    std::string user = "world";
    //请求
    std::string rep = greeter.SayHello(user);
    std::string rep2 = greeter.SayHelloAll();
    std::cout<<"get reply : "<<rep<<"\nget reply2 : "<<rep2<<std::endl;
}
```


