---
title: grpc-go
date: 2021-09-11 11:22:45
tags:
- grpc
- go
- go-chan
---
go版本的grpc，
go是1.17.1版本
<!--more -->

先看[protobuf](www.baidu.com)的介绍，用一个`.proto`文件作为服务定义，然后客户端和服务端都用这个文件生成的代码为基础进行编程。

## grpc (Go version)

先定义服务

```protobuf
service HelloService {
 //一个rpc对应一个远程方法
 
 //单个请求单个回复
 rpc SayHello (HelloRequest) returns (HelloResponse) {}
  
 //单个请求流式回复，服务器流式 RPC
 rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse);

 //流式请求，单个回复，客户端流式 RPC
 rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse);

 //双向流式传输
 rpc BidiHello(stream HelloRequest) returns (stream HelloResponse);

}

message HelloRequest {
  string greeting = 1;
}

message HelloResponse {
  string reply = 1;
}
```

### GO

#### quick start

###### `test.proto`文件

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

###### 编译，生成`test.pb.go`

从`https://github.com/protocolbuffers/protobuf/releases/download/v3.17.3/protoc-3.17.3-linux-x86_64.zip`下载得到protoc的执行文件，放到GOPATH的bin目录下。

```shell
wget https://github.com/protocolbuffers/protobuf/releases/download/v3.17.3/protoc-3.17.3-linux-x86_64.zip
#下载protoc Linux64位的可执行文件
unzip protoc-3.17.3-linux-x86_64.zip
#解压
cp bin/protoc ~/GOPATH/bin/
#放到GOPATH，$GOPATH/bin已经加到$PATH中了
go get -u github.com/golang/protobuf/protoc-gen-go
#protoc不可以直接编译go，需要protoc-gen-go做支持
protoc -I . --go_out=plugins=grpc:. test.proto
# -I是设置源路径，--go_out是使用test.proto中options的路径。
#编译出来`test.pb.go`，编译好之后缺少很多包的支持，需要重新获取依赖
go mod tidy
go mod download
go mod vendor#拉取依赖到本地，记得要把vendor放到.gitignore文件中，否则项目太大了，只要把go.mod&go.sum放到git中即可。
```

这样就编译出了`test.pb.go`文件，之后的grpc编程便可以使用这个文件。

###### `client.go`

然后编写client.go和server.go

```go
//client.go

package main

import (
	"context"
	"fmt"
	"google.golang.org/grpc"
	"grpc_test/pb"
	"io"
	"log"
	"time"
)
//address指的就是访问server的ip和端口
const (
	address  = "localhost:4306"
	name = "helloworld"
)
//一次请求一个回复的例子
func hello_once (){
    //grpc.Dial建立一个连接，是一个异步连接
    //grpc.WithInsecure()指这个端口号不需要安全配置
    //grpc.WithBlock()阻塞等待握手成功
	conn,err := grpc.Dial(address, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalln("Dial err")
	}
    //如果是常驻进程并且忘记Close会导致内存泄漏
	defer conn.Close()
    //用这个连接新建一个客户端
	c := pb.NewGreeterClient(conn)
    //ctx我也不知道有什么用
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	//请求
    req := pb.HelloRequest{Name:name}
	r,err := c.SayHello(ctx, &req)
	if err != nil {
		log.Fatalln("revoke err, %v",err )
	}
	log.Print("success %s\n",r.GetMessage())
}

func hello_all (){
	conn,err := grpc.Dial(address, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalln("Dial err")
	}
	defer conn.Close()
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	client := pb.NewGreeterClient(conn)
	stream, err := client.SayHelloAll(ctx)
	if err != nil {
		log.Fatalf("revoke err, %v",err )
	}
	waitc := make(chan string)
	//用一个协程来收服务端发回来的信息。
    go func() {
		for {
			get, err := stream.Recv()
            //服务端return之后就会发一个EOF，猜测。
			if err == io.EOF {
				return
			}
			if get != nil{
				waitc <- get.GetMessage()
				//log.Printf("%s\n", get.Message)
			}
		}
	}()
	//给服务端发信息。
	for i:=0;i<100;i++ {
		stream.Send(&pb.HelloRequest{
			Name: name,
		})
	}
    //发送完毕，关闭发送，避免服务端一直占用资源。
	err = stream.CloseSend()
	if err != nil {
		return
	}
    //输出所有服务端发送的消息，其实本质上也是等待服务端处理完所有的消息并返回。
	for  st ,ok := <- waitc; ok ; st = <- waitc{
		fmt.Printf("%s",st);
	}
}

func main () {
	hello_all()
}
```

###### `server.go`

```go
//server.go
package main

import (
	"context"
	"fmt"
	"google.golang.org/grpc"
	pb "grpc_test/pb"
	"io"
	"log"
	"net"
)

//还可以放点其他的东西在创建server的时候可以初始化本地信息，然后后面执行远程过程调用的时候也可以使用。
type server struct {
	pb.UnimplementedGreeterServer
}


/**
SayHello(context.Context, *HelloRequest) (*HelloReply, error)
SayHelloAll(Greeter_SayHelloAllServer) error
*/

func (s* server) SayHello(ctx context.Context, req *pb.HelloRequest) (*pb.HelloReply, error){

	fmt.Printf("%s req, %s once\n",req , req.Name)
	resp := pb.HelloReply{
		Message: "adfadf",
	}
	return &resp, nil
}

func (s *server) SayHelloAll(req pb.Greeter_SayHelloAllServer) error {
	for i:=0;i<10000;i++ {
		t, err := req.Recv();
		if err == io.EOF{
			break
		}
		if err != nil{
			log.Fatalln("Recv err")
		}
		fmt.Printf("%s req, %s time %d\n",t ,t.Name , i)
		req.Send(&pb.HelloReply{Message: fmt.Sprintf("reply %v\n", i)})
	}
	return nil
}


func main (){
	lis,err  := net.Listen("tcp","localhost:4306")
	if err!=nil{
		log.Fatalln("listen err");
	}
	s := grpc.NewServer()
	pb.RegisterGreeterServer(s, &server{})

	err=s.Serve(lis)
	if err!=nil {
		fmt.Println("start err")
	}
	fmt.Println("start")


}
```


