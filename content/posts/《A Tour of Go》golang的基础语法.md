+++
date = '2025-12-11T17:46:13+08:00'
draft = false
title = '《A Tour of Go》golang的基础语法'
categories = ["golang"]
tags = ["golang"]
series = []
+++


![](/images/file-20251211133350673.png)
[tour.golang.org](https://tour.go-zh.org/list)


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

2. 函数参数类型简写

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
// swap 函数调用示例
func main() {
    a, b := swap("hello", "world")
    fmt.Println(a, b) // 输出: world hello
}
```

4. 带名字的返回值

```go
func split(sum int) (x, y int) {
	x = sum * 4 / 9
	y = sum - x
	return
}
// split 函数调用示例
func main() {
    x, y := split(17)
    fmt.Println(x, y) // 输出: 7 10
}

```

5. 结构体函数

```go
// Datacenter 结构体和 AddServer 方法的完整示例
package main
import "fmt"

// Datacenter 定义
type Datacenter struct {
    serverCount int
}

// AddServer 首字母大写，是导出的 (public)
func (d *Datacenter) AddServer() {
    d.serverCount++
}

func main() {
    dc := &Datacenter{} // 创建一个 Datacenter 实例
    fmt.Println("初始服务器数：", dc.serverCount) // dc.serverCount 可以直接访问是因为在同一个package内 
    dc.AddServer()
    fmt.Println("添加服务器后：", dc.serverCount)
    dc.AddServer()
    fmt.Println("再添加一次后：", dc.serverCount)
}
```

### 变量

1. 变量声明： `var a int` 
2. 变量初始化：
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
    n,o := 1,2
    
    fmt.Println(c,python,java,i,j,k,m,n,o)
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
>💡 go和c++循环的区别在于 没有小括号() 且变量可以通过短变量声明 
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
for i, v := range s { // 其中v是对s元素的拷贝, 修改元素需要访问s[i]
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
int sum = 0;
for (int i=0; i < 10; i++)
{
    sum+=i;
}
for (;sum<1000;)
{
    sum+=sum;
}
cout<<sum<<endl;
```

### if/else（分支）
> 💡 if 和 c++的区别在于没有小括号(), else 的区别则必须与上一个花括号在同一行
```go
sum := 10
if sum < 10 {
    fmt.Println(sum)
}

// if的特殊写法
// 将初始化（或前置操作）与条件判断绑定在一起，变量的作用域限制在最小范围，从而避免污染外部的命名空间
// 在处理可能返回错误的代码时非常实用 
if sum=10; sum == 10 {
    fmt.Println(sum)
}

// 假设 os.ReadFile 返回 ([]byte, error)
if data, err := os.ReadFile("file.txt"); err != nil {
    // data 和 err 变量只在这里以及可能的 else/else if 中可见
    fmt.Println("读取文件失败:", err)
    return
} else {
    // 只有当 err 为 nil 时，才执行这里，data 在此作用域内可见
    fmt.Println("文件内容大小:", len(data))
}

// 在这个 if 结构体之外，data 和 err 变量都不能被访问
```

### switch
> 💡 golang 中的switch和cpp的区别在与go给每一个case默认添加了一个break （可以不用手动加了！）
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
> 💡 结构体就是一组字段 
```go 
type Vertex struct {
	X, Y int
}

func main() {
	// 1. 声明并赋值
	// 内存：v1 是值类型，直接在栈上分配内存，存储完整的结构体数据
	var v1 Vertex
	v1.X, v1.Y = 1, 2
	fmt.Println(v1) // {1 2}

	// 2. 字面量初始化（按顺序）
	// 内存：v2 也是值类型，在栈上分配，v1 和 v2 是独立的内存区域
	v2 := Vertex{1, 2}
	fmt.Println(v2) // {1 2}

	// 3. 命名字段初始化（未指定的字段为零值）
	// 内存：v3 同样是值类型，在栈上分配，未初始化的字段自动置零
	v3 := Vertex{X: 1}
	fmt.Println(v3) // {1 0}

	// 4. 结构体指针
	// 内存：v4 是指针类型，v4 本身在栈上（存储地址），
	//      但它指向的 Vertex 结构体数据可能在堆上分配
	v4 := &Vertex{1, 2} 
	v4.Y = 3 // 等价与 *(v4).Y = 3 
	fmt.Println(v4) // &{1 3}

	// 5. 使用 new 关键字
	// 内存：new 分配内存并返回指针，结构体字段初始化为零值
	//      v5 在栈上存储地址，指向的 Vertex 数据可能在堆上
	v5 := new(Vertex)
	v5.X = 1
	v5.Y = 2
	fmt.Println(v5) // &{1 2}
}
```

