+++
date = '2025-11-24T16:03:07+08:00'
draft = false
title = 'Golang基础语法'
categories = ["golang"]
tags = ["go"]
series = ["分布式系统设计"]
+++

![](/images/DockerGopher.png)

本文将简要介绍 Go (Golang) 语言的基础语法和核心概念，适合有一定编程基础但刚接触 Go 的读者。通过具体示例，您可以快速了解 Go 的基本结构、数据类型、函数用法以及常用的编码习惯，有助于后续深入学习和项目实践。

### package & import

1. 每个程序都是由包构成，main本身也是一个package 
2. 可以通过import导入其他包来使用

```go
package main

import (
	"fmt"
	"math/rand"
)

func main() {
	fmt.Println("我最喜欢的数字是 ", rand.Intn(10)) 
	fmt.Println("rand.Intn(20)")
}
```

### 导出名（Exported）

1. package 中 首字母大写的字段可以给其他包直接访问，反之则不行

```go
package infrastructure

// Datacenter 结构体是导出的 (public)
type Datacenter struct {
    // serverCount 首字母小写，是未导出的 (private)
    // 只有 infrastructure 包内部的代码能访问它
    serverCount int 
}

// AddServer 首字母大写，是导出的 (public)
func (d *Datacenter) AddServer() {
    d.serverCount++
}
```

### 函数

1. 基础函数

```go
func add(x int, y int) int {
	return x + y
}
```

2. 简写1

```go
func add(x , y int) int {
	return x + y
}
```

3. 多返回值 

```go
func swap(x, y string) (string, string) {
	return y, x
}
```

4. 带名字的返回值

```go
func split(sum int) (x, y int) {
	x = sum * 4 / 9
	y = sum - x
	return
}
```

5. 结构体函数

```go
// AddServer 首字母大写，是导出的 (public)
func (d *Datacenter) AddServer() {
    d.serverCount++
}
```

### 变量

1. 变量声明： `var a int` 
2. 变量始化：
    - 默认 `var i,j int = 1,2`
    - 自动推导类型 `var i,j = 1,2` 
    - 短变量声明（只能在函数内使用）`i,j:=1,2`
3. 没有初始化的变量会设置为对应类型的默认值 
```go 
package main

import "fmt"

var c,python,java bool
func main() {
    // 默认声明
    var i,j int = 1,2 
    // 自动推导类型
    var k,m = 1,2 
    // 短变量声明
    m,o := 1,2
    
    fmt.Println(c,python,java,i,j,l,m,o)
}

```

### 基本类型
```go
bool string int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64 uintptr
byte // uint8别名
rune // int32别名 标识 Unicode 码位
float32 float64
complex64 complex128 
```
```go 
package main

import (
	"fmt"
	"math/cmplx"
)

var (
	ToBe   bool       = false
	MaxInt uint64     = 1<<64 - 1
	z      complex128 = cmplx.Sqrt(-5 + 12i)
)

func main() {
	fmt.Printf("类型：%T 值：%v\n", ToBe, ToBe)
	fmt.Printf("类型：%T 值：%v\n", MaxInt, MaxInt)
	fmt.Printf("类型：%T 值：%v\n", z, z)
}

```

### 类型转换
`T(v) // 将变量v转为类型T`
`fmt.Println("%T",v) // 类型推导`
`const Pi = 3.14 // 常量`


### 循环 
>💡 go和c++循环的区别在与 没有小括号() 且变量可以通过短变量声明 
```go 
// golang for loop 
sum := 0
// 完整版本
for i := 0; i < 10; i++ {
    sum += i
}
// 循环条件已存在
for ;sum<1000;{
    sum+=sum
}
// while 循环 (感觉非常棒的设计，移除了while关键字 使用for统一循环)
for sum <10000 {
    sum+=sum
}
// 无限循环
for {
}
// for each 
for i, v := range s {
    fmt.Println(i, v)
}
for _, value := range s {
    fmt.Printf("%d: %d\n", value)
}
for i, _ := range s {
    fmt.Printf("%d: %d\n", i)
}
for i := range s {
    fmt.Printf("%d: %d\n", i)
}
fmt.Println(sum)

```
``` cpp
// cpp for loop
int sum = 10;
for (int i=0;i < 0; i++)
{
    sum+=i;
}
for (;sum<1000;i++)
{
    sum+=sum;
}
cout<<sum<<endl;
```

### if/else（分支）
> 💡 if 和 c++的区别在与没有小括号(), else 的区别则必须与上一个话括号在同一行
```go
sum := 10
if sum < 10 {
    fmt.Println(sum)
}

// 特殊写法
if sum=10; sum == 10 {
    fmt.Println(sum)
}
```

### switch
> 💡 golang 中的switch和cpp的区别在与go给每一个case默认添加了一个break
```go
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Print("Go 运行的系统环境：")
    // 这些case是按顺序检查
	switch os := runtime.GOOS; os {
	case "darwin":
		fmt.Println("macOS.")
	case "linux":
		fmt.Println("Linux.")
	default:
		// freebsd, openbsd,
		// plan9, windows...
		fmt.Printf("%s.\n", os)
	}
}
```
### defer
> 💡 1. 被defer标记的语句会推迟到函数退出前才执行 类似于cpp RAII 2. 如果有多个defer 则按先进后出（栈）的顺序
```go
package main

import "fmt"

func main() {
	defer fmt.Println("world")

	fmt.Println("hello")
}

```

### 指针
> 💡 go和c++指针的区别在于go不支持指针运算 
```go
package main

import "fmt"

func main() {
	i, j := 42, 2701

	p := &i         // 指向 i
	fmt.Println(*p) // 通过指针读取 i 的值
	*p = 21         // 通过指针设置 i 的值
	fmt.Println(i)  // 查看 i 的值

	p = &j         // 指向 j
	*p = *p / 37   // 通过指针对 j 进行除法运算
	fmt.Println(j) // 查看 j 的值
}
```

### 结构体
```go 
package main

import "fmt"

type Vertex struct {
	X int
	Y int
}

func main() {
	v := Vertex{1, 2}
	v.X = 4
	fmt.Println(v.X)

    // 结构题指针 无需使用-> 
    p := v
    p.X = 109 
    fmt.Println(v)
}
```

### 数组 
var 数组名 [数组长度] 数组类型
```go
package main

import "fmt"

func main() {
	var a [2]string
	a[0] = "Hello"
	a[1] = "World"
	fmt.Println(a[0], a[1])
	fmt.Println(a)

	primes := [6]int{2, 3, 5, 7, 11, 13}
	fmt.Println(primes)
}

```