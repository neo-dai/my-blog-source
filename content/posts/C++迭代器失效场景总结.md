+++
date = '2025-12-11T17:27:25+08:00'
draft = false
title = 'C++迭代器失效场景总结'
categories = ["c++笔记"]
tags = ["c++"]
series = []
+++


## 目录
- [1. 什么是迭代器失效](#1-什么是迭代器失效)
- [2. vector的迭代器失效](#2-vector的迭代器失效)
- [3. deque的迭代器失效](#3-deque的迭代器失效)
- [4. list的迭代器失效](#4-list的迭代器失效)
- [5. map/set的迭代器失效](#5-mapset的迭代器失效)
- [6. unordered_map/unordered_set的迭代器失效](#6-unordered_mapunordered_set的迭代器失效)
- [7. 迭代器失效的预防措施](#7-迭代器失效的预防措施)
- [8. 总结表格](#8-总结表格)

---

## 1. 什么是迭代器失效

**迭代器失效**是指当容器的内部结构发生改变时，原有的迭代器可能变得不再有效，继续使用会导致**未定义行为**，包括程序崩溃、数据错误等。

迭代器失效的主要原因：
- **容器扩容**（导致内存重新分配）
- **元素插入/删除**（改变容器内部结构）
- **容器被移动或销毁**

---

## 2. vector的迭代器失效

### 2.1 插入操作导致失效

**场景1：push_back导致扩容**

```cpp
#include <vector>
#include <iostream>

void example_vector_pushback() {
    std::vector<int> vec = {1, 2, 3, 4, 5};
    vec.reserve(5);  // 容量为5
    
    auto it = vec.begin();
    auto it_mid = vec.begin() + 2;  // 指向第3个元素
    
    std::cout << "扩容前: *it_mid = " << *it_mid << std::endl;  // 输出: 3
    
    vec.push_back(6);  // 触发扩容！
    
    // ❌ 危险！it和it_mid已经失效
    // std::cout << *it_mid << std::endl;  // 未定义行为
}
```

**失效原因**：
- `push_back`导致vector扩容时，会重新分配内存
- 所有元素被复制到新的内存位置
- 所有迭代器、指针、引用全部失效

---

**场景2：insert操作**

```cpp
void example_vector_insert() {
    std::vector<int> vec = {1, 2, 3, 4, 5};
    
    auto it = vec.begin() + 2;  // 指向值为3的元素
    
    // 在位置1插入元素
    vec.insert(vec.begin() + 1, 99);
    
    // ❌ it已经失效！
    // 即使没有扩容，insert之后的所有迭代器都会失效
}
```

**失效规则**：
- 如果**插入导致扩容**：所有迭代器失效
- 如果**没有扩容**：插入点之后（包括插入点）的迭代器失效，插入点之前的仍有效

**正确做法**：

```cpp
void correct_vector_insert() {
    std::vector<int> vec = {1, 2, 3, 4, 5};
    
    auto it = vec.begin() + 2;
    
    // insert返回指向新插入元素的迭代器
    it = vec.insert(it, 99);  // ✅ 更新迭代器
    
    std::cout << *it << std::endl;  // 输出: 99
}
```

---

### 2.2 删除操作导致失效

**场景1：erase单个元素**

```cpp
void example_vector_erase() {
    std::vector<int> vec = {1, 2, 3, 4, 5};
    
    auto it = vec.begin() + 2;  // 指向3
    
    vec.erase(it);  // 删除3
    
    // ❌ it已经失效！
    // std::cout << *it << std::endl;  // 未定义行为
}
```

**失效规则**：
- 被删除元素的迭代器失效
- 删除点之后的所有迭代器失效
- 删除点之前的迭代器仍然有效

**正确做法**：

```cpp
void correct_vector_erase() {
    std::vector<int> vec = {1, 2, 3, 4, 5};
    
    auto it = vec.begin();
    
    while (it != vec.end()) {
        if (*it % 2 == 0) {
            it = vec.erase(it);  // ✅ erase返回下一个有效迭代器
        } else {
            ++it;
        }
    }
    // vec现在是 {1, 3, 5}
}
```

---

**场景2：删除所有偶数（错误示范）**

```cpp
void wrong_erase_loop() {
    std::vector<int> vec = {1, 2, 3, 4, 5, 6};
    
    // ❌ 错误的删除方式
    for (auto it = vec.begin(); it != vec.end(); ++it) {
        if (*it % 2 == 0) {
            vec.erase(it);  // it失效，++it是未定义行为！
        }
    }
}
```

---

### 2.3 其他导致失效的操作

```cpp
void other_invalidate_operations() {
    std::vector<int> vec = {1, 2, 3, 4, 5};
    auto it = vec.begin();
    
    // clear清空容器
    vec.clear();  // ❌ 所有迭代器失效
    
    // resize改变大小
    vec = {1, 2, 3, 4, 5};
    it = vec.begin();
    vec.resize(10);  // ❌ 可能扩容，所有迭代器可能失效
    
    // reserve增加容量
    vec.reserve(100);  // ❌ 扩容，所有迭代器失效
    
    // swap交换容器
    std::vector<int> vec2 = {10, 20, 30};
    vec.swap(vec2);  // ❌ 两个容器的迭代器都失效（或互换）
}
```

---

## 3. deque的迭代器失效

### 3.1 插入操作

```cpp
#include <deque>

void example_deque_insert() {
    std::deque<int> dq = {1, 2, 3, 4, 5};
    
    auto it = dq.begin() + 2;
    
    // 在首尾插入
    dq.push_front(0);   // ❌ 所有迭代器失效（但引用和指针仍有效）
    dq.push_back(6);    // ❌ 所有迭代器失效（但引用和指针仍有效）
    
    // 在中间插入
    it = dq.begin() + 3;
    dq.insert(it, 99);  // ❌ 所有迭代器、引用、指针全部失效
}
```

**失效规则**：
- **首尾插入**（`push_front`/`push_back`）：所有迭代器失效，但引用和指针仍有效
- **中间插入**：所有迭代器、引用、指针全部失效

---

### 3.2 删除操作

```cpp
void example_deque_erase() {
    std::deque<int> dq = {1, 2, 3, 4, 5};
    
    auto it = dq.begin() + 2;
    
    // 删除首尾元素
    dq.pop_front();  // ❌ 只有首元素的迭代器失效，其他有效
    dq.pop_back();   // ❌ 只有尾元素的迭代器失效，其他有效
    
    // 删除中间元素
    it = dq.begin() + 1;
    dq.erase(it);    // ❌ 所有迭代器、引用、指针全部失效
}
```

**失效规则**：
- **首尾删除**：只有被删除元素的迭代器失效
- **中间删除**：所有迭代器、引用、指针全部失效

---

## 4. list的迭代器失效

`list`是双向链表，迭代器失效情况相对简单。

### 4.1 插入操作

```cpp
#include <list>

void example_list_insert() {
    std::list<int> lst = {1, 2, 3, 4, 5};
    
    auto it = lst.begin();
    ++it;  // 指向2
    
    lst.push_front(0);   // ✅ 所有迭代器仍有效
    lst.push_back(6);    // ✅ 所有迭代器仍有效
    lst.insert(it, 99);  // ✅ 所有迭代器仍有效
}
```

**失效规则**：
- 插入操作**不会**导致任何迭代器失效

---

### 4.2 删除操作

```cpp
void example_list_erase() {
    std::list<int> lst = {1, 2, 3, 4, 5};
    
    auto it1 = lst.begin();
    auto it2 = ++lst.begin();
    auto it3 = ++(++lst.begin());
    
    lst.erase(it2);  // ❌ 只有it2失效，it1和it3仍有效
    
    std::cout << *it1 << std::endl;  // ✅ 输出: 1
    std::cout << *it3 << std::endl;  // ✅ 输出: 3
}
```

**失效规则**：
- 删除操作**只会**使被删除元素的迭代器失效
- 其他迭代器不受影响

**正确的删除循环**：

```cpp
void correct_list_erase() {
    std::list<int> lst = {1, 2, 3, 4, 5, 6};
    
    auto it = lst.begin();
    while (it != lst.end()) {
        if (*it % 2 == 0) {
            it = lst.erase(it);  // ✅ 返回下一个有效迭代器
        } else {
            ++it;
        }
    }
    // lst现在是 {1, 3, 5}
}
```

---

## 5. map/set的迭代器失效

`map`、`set`、`multimap`、`multiset`底层是**红黑树**。

### 5.1 插入操作

```cpp
#include <map>
#include <set>

void example_map_insert() {
    std::map<int, std::string> m = {{1, "one"}, {2, "two"}, {3, "three"}};
    
    auto it = m.begin();
    
    m.insert({4, "four"});  // ✅ 所有迭代器仍有效
    m[5] = "five";          // ✅ 所有迭代器仍有效
}
```

**失效规则**：
- 插入操作**不会**导致任何迭代器失效

---

### 5.2 删除操作

```cpp
void example_map_erase() {
    std::map<int, std::string> m = {
        {1, "one"}, {2, "two"}, {3, "three"}, {4, "four"}
    };
    
    auto it1 = m.begin();           // 指向{1, "one"}
    auto it2 = ++m.begin();         // 指向{2, "two"}
    auto it3 = ++(++m.begin());     // 指向{3, "three"}
    
    m.erase(it2);  // ❌ 只有it2失效，it1和it3仍有效
    
    std::cout << it1->first << std::endl;  // ✅ 输出: 1
    std::cout << it3->first << std::endl;  // ✅ 输出: 3
    // std::cout << it2->first << std::endl;  // ❌ 未定义行为
}
```

**失效规则**：
- 删除操作**只会**使被删除元素的迭代器失效
- 其他迭代器不受影响

**正确的删除循环**：

```cpp
void correct_map_erase() {
    std::map<int, std::string> m = {
        {1, "one"}, {2, "two"}, {3, "three"}, {4, "four"}
    };
    
    // C++11以后，erase返回下一个有效迭代器
    auto it = m.begin();
    while (it != m.end()) {
        if (it->first % 2 == 0) {
            it = m.erase(it);  // ✅ C++11
        } else {
            ++it;
        }
    }
    
    // C++11之前的写法
    for (auto it = m.begin(); it != m.end(); ) {
        if (it->first % 2 == 0) {
            m.erase(it++);  // ✅ 先拷贝it，再递增，然后删除拷贝的it
        } else {
            ++it;
        }
    }
}
```

---

## 6. unordered_map/unordered_set的迭代器失效

`unordered_map`、`unordered_set`底层是**哈希表**。

### 6.1 插入操作

```cpp
#include <unordered_map>

void example_unordered_map_insert() {
    std::unordered_map<int, std::string> um = {
        {1, "one"}, {2, "two"}, {3, "three"}
    };
    
    auto it = um.begin();
    
    // 如果插入导致rehash（负载因子超过阈值）
    um.insert({4, "four"});  // ⚠️ 可能触发rehash，所有迭代器失效
}
```

**失效规则**：
- 如果插入**导致rehash**：所有迭代器失效（但引用和指针仍有效）
- 如果**没有rehash**：所有迭代器仍有效

**检查是否会rehash**：

```cpp
void check_rehash() {
    std::unordered_map<int, std::string> um;
    um.reserve(10);  // 预留空间，避免频繁rehash
    
    std::cout << "bucket_count: " << um.bucket_count() << std::endl;
    std::cout << "load_factor: " << um.load_factor() << std::endl;
    std::cout << "max_load_factor: " << um.max_load_factor() << std::endl;
    
    // 插入前检查
    if (um.size() + 1 > um.bucket_count() * um.max_load_factor()) {
        std::cout << "下次插入将触发rehash！" << std::endl;
    }
}
```

---

### 6.2 删除操作

```cpp
void example_unordered_map_erase() {
    std::unordered_map<int, std::string> um = {
        {1, "one"}, {2, "two"}, {3, "three"}
    };
    
    auto it1 = um.begin();
    auto it2 = ++um.begin();
    
    um.erase(it1);  // ❌ 只有it1失效，it2仍有效
}
```

**失效规则**：
- 删除操作**只会**使被删除元素的迭代器失效
- 其他迭代器不受影响

---

## 7. 迭代器失效的预防措施

### 7.1 使用返回的迭代器

```cpp
// ✅ 始终使用insert/erase返回的迭代器
it = vec.insert(it, value);
it = vec.erase(it);
```

---

### 7.2 预分配空间

```cpp
// ✅ 避免频繁扩容
std::vector<int> vec;
vec.reserve(1000);  // 预留空间

std::unordered_map<int, int> um;
um.reserve(1000);  // 预留空间，避免rehash
```

---

### 7.3 使用索引代替迭代器

```cpp
// ✅ 在vector中，索引不会失效
std::vector<int> vec = {1, 2, 3, 4, 5};
for (size_t i = 0; i < vec.size(); ) {
    if (vec[i] % 2 == 0) {
        vec.erase(vec.begin() + i);
        // 不需要i++，因为后面的元素会前移
    } else {
        ++i;
    }
}
```

---

### 7.4 使用remove-erase惯用法

```cpp
#include <algorithm>

// ✅ 对于vector，使用remove-erase惯用法更安全
std::vector<int> vec = {1, 2, 3, 4, 5, 6};
vec.erase(
    std::remove_if(vec.begin(), vec.end(), 
        [](int x) { return x % 2 == 0; }),
    vec.end()
);
```

---

### 7.5 选择合适的容器

```cpp
// 如果需要频繁插入删除，考虑使用list
std::list<int> lst = {1, 2, 3, 4, 5};
// list的迭代器更稳定

// 如果需要稳定的迭代器且查找性能重要，考虑map/set
std::map<int, std::string> m;
// 插入不会导致迭代器失效
```

---

## 8. 总结表格

| 容器类型 | 插入操作 | 删除操作 |
|---------|---------|---------|
| **vector** | 扩容时全部失效<br>不扩容时插入点及之后失效 | 删除点及之后失效 |
| **deque** | 首尾插入：所有迭代器失效<br>中间插入：全部失效 | 首尾删除：仅被删除元素失效<br>中间删除：全部失效 |
| **list** | 不会失效 | 仅被删除元素失效 |
| **map/set** | 不会失效 | 仅被删除元素失效 |
| **unordered_map<br>unordered_set** | rehash时全部失效<br>否则不失效 | 仅被删除元素失效 |

---

## 关键要点

1. **vector**和**deque**最容易出现迭代器失效
2. **list**、**map/set**的迭代器相对稳定
3. **unordered容器**需要注意rehash
4. 删除和插入操作后，始终使用返回的迭代器
5. 尽量使用STL算法（如`remove_if`）而不是手动循环删除
6. 预分配空间可以避免很多问题

---

## 调试技巧

1. **编译器选项**：使用`-D_GLIBCXX_DEBUG`（GCC）或类似选项开启调试模式
2. **AddressSanitizer**：使用`-fsanitize=address`检测内存错误
3. **静态分析工具**：使用clang-tidy等工具
4. **单元测试**：为容器操作编写单元测试

```bash
# 编译时开启调试选项
g++ -std=c++17 -D_GLIBCXX_DEBUG -fsanitize=address -g main.cpp -o main
```

---

**参考资料**：
- C++ Reference: https://en.cppreference.com/
- Effective STL by Scott Meyers
- C++ Primer 5th Edition


