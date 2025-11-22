+++
date = '2025-11-22T15:22:26+08:00'
draft = true
title = 'MapReduce中译'
categories = []
tags = []
series = [分布式系统学习]
+++


# [cite\_start]MapReduce：大型集群上的简化数据处理 [cite: 1]

[cite\_start]**Jeffrey Dean and Sanjay Ghemawat** [cite: 2]
jeff@google.com, sanjay@google.com
[cite\_start]Google, Inc. [cite: 3]

## 摘要 (Abstract)

[cite\_start]MapReduce 是一个编程模型，也是一个用于处理和生成大数据集的相关实现 [cite: 5][cite\_start]。用户指定一个 **Map（映射）** 函数，处理一个键/值对（key/value pair）以生成一组中间键/值对；以及一个 **Reduce（归约）** 函数，用于合并与同一中间键关联的所有中间值 [cite: 6][cite\_start]。如论文所示，许多现实世界的任务都可以用这个模型来表达 [cite: 7]。

[cite\_start]以这种函数式风格编写的程序会自动并行化，并在由普通商用机器组成的大型集群上执行 [cite: 8][cite\_start]。运行时系统负责处理输入数据的划分、在机器集上调度程序执行、处理机器故障以及管理所需的机器间通信等细节 [cite: 9][cite\_start]。这使得没有任何并行和分布式系统经验的程序员也能轻松利用大型分布式系统的资源 [cite: 10]。

[cite\_start]我们的 MapReduce 实现运行在大型普通商用机器集群上，并且具有高度的可扩展性：典型的 MapReduce 计算在数千台机器上处理数太字节（TB）的数据 [cite: 11][cite\_start]。程序员发现该系统易于使用：目前已实现了数百个 MapReduce 程序，每天在 Google 的集群上执行超过一千个 MapReduce 作业 [cite: 12]。

-----

## 1\. 介绍 (Introduction)

[cite\_start]在过去五年中，作者和 Google 的许多其他人实现了数百种专用计算，用于处理大量的原始数据（如爬取的文档、Web 请求日志等），以计算各种类型的衍生数据，如倒排索引、Web 文档图结构的各种表示、每台主机爬取页面数量的摘要、给定日期内最频繁查询的集合等 [cite: 14][cite\_start]。大多数此类计算在概念上都很直观 [cite: 16][cite\_start]。然而，输入数据通常很大，为了在合理的时间内完成，计算必须分布在数百或数千台机器上 [cite: 17][cite\_start]。如何并行化计算、分发数据以及处理故障的问题，往往导致原本简单的计算被大量复杂的代码所掩盖，以处理这些问题 [cite: 18]。

[cite\_start]为了应对这种复杂性，我们设计了一种新的抽象，允许我们表达试图执行的简单计算，但在库中隐藏了并行化、容错（Fault-Tolerance）、数据分发和负载均衡的繁杂细节 [cite: 19][cite\_start]。我们的抽象灵感来自于 Lisp 和许多其他函数式语言中的 map 和 reduce 原语 [cite: 20][cite\_start]。我们意识到，我们的大多数计算都涉及对输入中的每个逻辑“记录”应用 **Map** 操作，以计算一组中间键/值对，然后对所有共享相同键的值应用 **Reduce** 操作，以适当合并衍生数据 [cite: 21][cite\_start]。我们使用带有用户指定的 Map 和 Reduce 操作的函数式模型，使我们要能够轻松地并行化大型计算，并使用重新执行（re-execution）作为容错的主要机制 [cite: 22]。

[cite\_start]这项工作的主要贡献是一个简单而强大的接口，能够实现大规模计算的自动并行化和分发，并结合了该接口在大型商用 PC 集群上的高性能实现 [cite: 23]。

[cite\_start]第 2 节描述了基本的编程模型并给出了几个例子 [cite: 24][cite\_start]。第 3 节描述了针对我们基于集群的计算环境量身定制的 MapReduce 接口的实现 [cite: 25][cite\_start]。第 4 节描述了我们发现有用的几种编程模型优化 [cite: 26][cite\_start]。第 5 节对我们的实现进行了各种任务的性能测量 [cite: 27][cite\_start]。第 6 节探讨了 MapReduce 在 Google 内部的使用，包括我们使用它作为重写生产索引系统基础的经验 [cite: 28][cite\_start]。第 7 节讨论了相关和未来的工作 [cite: 30]。

-----

## 2\. 编程模型 (Programming Model)

[cite\_start]计算接受一组输入键/值对，并产生一组输出键/值对 [cite: 32][cite\_start]。MapReduce 库的用户将计算表达为两个函数：**Map** 和 **Reduce** [cite: 33]。

[cite\_start]**Map**，由用户编写，接受一个输入对并产生一组中间键/值对 [cite: 34][cite\_start]。MapReduce 库将与同一中间键 $I$ 关联的所有中间值分组，并将它们传递给 **Reduce** 函数 [cite: 35]。

[cite\_start]**Reduce** 函数，也由用户编写，接受一个中间键 $I$ 和该键的一组值 [cite: 36][cite\_start]。它将这些值合并在一起，形成一个可能更小的值集 [cite: 37][cite\_start]。通常，每次 Reduce 调用只产生零个或一个输出值 [cite: 38][cite\_start]。中间值通过迭代器提供给用户的 Reduce 函数 [cite: 39][cite\_start]。这允许我们要处理因为太大而无法放入内存的值列表 [cite: 40]。

### 2.1 示例 (Example)

[cite\_start]考虑计算大量文档集合中每个单词出现次数的问题 [cite: 42][cite\_start]。用户将编写类似以下伪代码的代码 [cite: 43]：

```c++
map(String key, String value):
    // key: 文档名称
    // value: 文档内容
    for each word w in value:
        EmitIntermediate(w, "1");

reduce(String key, Iterator values):
    // key: 一个单词
    // values: 计数列表
    int result = 0;
    for each v in values:
        result += ParseInt(v);
    Emit(AsString(result));
```

[cite\_start]Map 函数发出每个单词及其相关的出现次数（在这个简单的例子中就是 '1'）[cite: 54][cite\_start]。Reduce 函数将特定单词发出的所有计数求和 [cite: 55]。

[cite\_start]此外，用户编写代码填充一个 mapreduce 规范对象，其中包含输入和输出文件的名称以及可选的调优参数 [cite: 56][cite\_start]。然后用户调用 MapReduce 函数，并将规范对象传递给它 [cite: 57][cite\_start]。用户的代码与 MapReduce 库（用 C++ 实现）链接在一起 [cite: 58][cite\_start]。附录 A 包含此示例的完整程序文本 [cite: 59]。

### 2.2 类型 (Types)

[cite\_start]尽管前面的伪代码是用字符串输入和输出编写的，但在概念上，用户提供的 Map 和 Reduce 函数具有关联的类型 [cite: 62]：

```text
map     (k1, v1)       ->  list(k2, v2)
reduce  (k2, list(v2)) ->  list(v2)
```

[cite\_start]即，输入键和值来自与输出键和值不同的域 [cite: 66][cite\_start]。此外，中间键和值与输出键和值来自同一域 [cite: 67]。

[cite\_start]我们的 C++ 实现将字符串传递给用户定义的函数，并从用户定义的函数接收字符串，留给用户代码在字符串和适当类型之间进行转换 [cite: 68]。

### 2.3 更多示例 (More Examples)

[cite\_start]以下是一些可以轻松表示为 MapReduce 计算的有趣程序的简单示例 [cite: 70]：

  * [cite\_start]**分布式 Grep (Distributed Grep)：** Map 函数如果匹配提供的模式则发出一行 [cite: 71][cite\_start]。Reduce 函数是一个恒等函数，只是将提供的中间数据复制到输出 [cite: 72]。
  * [cite\_start]**URL 访问频率计数 (Count of URL Access Frequency)：** Map 函数处理网页请求日志并输出 `(URL, 1)` [cite: 73][cite\_start]。Reduce 函数将相同 URL 的所有值相加，并发出 `(URL, total count)` 对 [cite: 74]。
  * [cite\_start]**反向 Web 链接图 (Reverse Web-Link Graph)：** Map 函数为在名为 `source` 的页面中找到的指向 `target` URL 的每个链接输出 `(target, source)` 对 [cite: 75][cite\_start]。Reduce 函数将与给定 `target` URL 关联的所有 `source` URL 列表连接起来，并发出对：`(target, list(source))` [cite: 76]。
  * [cite\_start]**每台主机的术语向量 (Term-Vector per Host)：** 术语向量将文档或文档集中出现的最重要的单词总结为 `(word, frequency)` 对列表 [cite: 77][cite\_start]。Map 函数为每个输入文档发出一个 `(hostname, term vector)` 对（其中 hostname 从文档的 URL 中提取）[cite: 78][cite\_start]。Reduce 函数接收给定主机的所有每文档术语向量 [cite: 79][cite\_start]。它将这些术语向量相加，丢弃不频繁的术语，然后发出最终的 `(hostname, term vector)` 对 [cite: 80]。
  ![更多 MapReduce 示例](./MapReduce%20Figure%201%20EXecution%20overview.png)
  * [cite\_start]**倒排索引 (Inverted Index)：** Map 函数解析每个文档，并发出一个 `(word, document ID)` 对序列 [cite: 111][cite\_start]。Reduce 函数接受给定单词的所有对，对相应的文档 ID 进行排序，并发出一个 `(word, list(document ID))` 对 [cite: 112][cite\_start]。所有输出对的集合形成一个简单的倒排索引 [cite: 113][cite\_start]。以此计算为基础增加跟踪单词位置的功能也很容易 [cite: 114]。
  * [cite\_start]**分布式排序 (Distributed Sort)：** Map 函数从每个记录中提取键，并发出 `(key, record)` 对 [cite: 115][cite\_start]。Reduce 函数原样发出所有对。此计算依赖于 4.1 节中描述的分区工具和 4.2 节中描述的排序属性 [cite: 116]。

-----

## 3\. 实现 (Implementation)

[cite\_start]MapReduce 接口可能有许多不同的实现 [cite: 118][cite\_start]。正确的选择取决于环境 [cite: 118][cite\_start]。例如，一种实现可能适合小型共享内存机器，另一种适合大型 NUMA 多处理器，还有一种适合更大的网络机器集合 [cite: 119]。

[cite\_start]本节描述了针对 Google 广泛使用的计算环境的实现：通过交换式以太网连接在一起的大型普通商用 PC 集群 [cite: 120, 122]。在我们的环境中：

1.  [cite\_start]机器通常是运行 Linux 的双处理器 x86 处理器，每台机器有 2-4 GB 内存 [cite: 123]。
2.  [cite\_start]使用普通网络硬件，机器层面通常为 100 Mb/s 或 1 Gb/s，但整体二分带宽（bisection bandwidth）平均要低得多 [cite: 124]。
3.  [cite\_start]一个集群由数百或数千台机器组成，因此机器故障很常见 [cite: 125]。
4.  [cite\_start]存储由直接连接到各个机器的廉价 IDE 磁盘提供 [cite: 126][cite\_start]。内部开发的分布式文件系统（GFS）用于管理存储在这些磁盘上的数据 [cite: 127][cite\_start]。该文件系统使用复制在不可靠的硬件之上提供可用性和可靠性 [cite: 128]。
5.  [cite\_start]用户将作业提交给调度系统。每个作业由一组任务组成，由调度程序映射到集群内的一组可用机器上 [cite: 129]。

### 3.1 执行概览 (Execution Overview)

[cite\_start]Map 调用通过自动将输入数据划分为 $M$ 个拆分（split）分布在多台机器上 [cite: 131, 133][cite\_start]。输入拆分可以由不同的机器并行处理 [cite: 133][cite\_start]。Reduce 调用通过使用分区函数（例如 `hash(key) mod R`）将中间键空间划分为 $R$ 个片段来分布 [cite: 134][cite\_start]。分区数量 ($R$) 和分区函数由用户指定 [cite: 135]。

\![图 1: 执行概览](source: 110)
*图 1：执行概览*

[cite\_start]图 1 显示了我们的实现中 MapReduce 操作的整体流程 [cite: 136]。当用户程序调用 MapReduce 函数时，会发生以下操作序列（图 1 中的数字标签对应于下面的列表）：

1.  [cite\_start]用户程序中的 MapReduce 库首先将输入文件拆分为 $M$ 个片段，通常每个片段 16 MB 到 64 MB（用户可通过可选参数控制）[cite: 138][cite\_start]。然后它在集群的一组机器上启动程序的许多副本 [cite: 139]。
2.  [cite\_start]程序副本中有一个是特殊的——**Master（主节点）** [cite: 140][cite\_start]。其余的是由 Master 分配工作的 **Worker（工作节点）** [cite: 141][cite\_start]。有 $M$ 个 Map 任务和 $R$ 个 Reduce 任务需要分配 [cite: 142][cite\_start]。Master 选择空闲的 Worker 并为每个 Worker 分配一个 Map 任务或 Reduce 任务 [cite: 143]。
3.  [cite\_start]被分配了 Map 任务的 Worker 读取相应输入拆分的内容 [cite: 144][cite\_start]。它从输入数据中解析出键/值对，并将每一对传递给用户定义的 Map 函数 [cite: 145][cite\_start]。Map 函数产生的中间键/值对缓存在内存中 [cite: 146]。
4.  [cite\_start]定期地，缓冲的对被写入本地磁盘，并由分区函数划分为 $R$ 个区域 [cite: 147][cite\_start]。这些缓冲对在本地磁盘上的位置被传回给 Master，Master 负责将这些位置转发给 Reduce Worker [cite: 148]。
5.  [cite\_start]当 Reduce Worker 收到 Master 关于这些位置的通知时，它使用远程过程调用（RPC）从 Map Worker 的本地磁盘读取缓冲数据 [cite: 149][cite\_start]。当 Reduce Worker 读取了所有中间数据后，它会按中间键对其进行排序，以便将所有相同键的出现组合在一起 [cite: 150][cite\_start]。排序是必需的，因为通常许多不同的键映射到同一个 Reduce 任务 [cite: 151][cite\_start]。如果中间数据量太大无法放入内存，则使用外部排序 [cite: 152]。
6.  [cite\_start]Reduce Worker 迭代排序后的中间数据，并且对于遇到的每个唯一中间键，它将键和相应的中间值集传递给用户的 Reduce 函数 [cite: 153][cite\_start]。Reduce 函数的输出被追加到该 Reduce 分区的最终输出文件中 [cite: 154]。
7.  [cite\_start]当所有 Map 任务和 Reduce 任务完成后，Master 唤醒用户程序 [cite: 156][cite\_start]。此时，用户程序中的 MapReduce 调用返回到用户代码 [cite: 157]。

[cite\_start]成功完成后，MapReduce 执行的输出可在 $R$ 个输出文件中获得（每个 Reduce 任务一个，文件名由用户指定）[cite: 158][cite\_start]。通常，用户不需要将这 $R$ 个输出文件合并为一个文件——他们经常将这些文件作为输入传递给另一个 MapReduce 调用，或者从另一个能够处理划分为多个文件的输入的分布式应用程序中使用它们 [cite: 159]。

### 3.2 Master 数据结构 (Master Data Structures)

[cite\_start]Master 维护几个数据结构。对于每个 Map 任务和 Reduce 任务，它存储状态（空闲、进行中或已完成）以及 Worker 机器的标识（对于非空闲任务）[cite: 161]。

[cite\_start]Master 是中间文件区域位置信息从 Map 任务传播到 Reduce 任务的管道 [cite: 162][cite\_start]。因此，对于每个已完成的 Map 任务，Master 存储该 Map 任务产生的 $R$ 个中间文件区域的位置和大小 [cite: 163][cite\_start]。当 Map 任务完成时，会接收到对此位置和大小信息的更新 [cite: 164][cite\_start]。这些信息被增量推送到具有正在进行的 Reduce 任务的 Worker [cite: 165]。

### 3.3 容错 (Fault Tolerance)

[cite\_start]由于 MapReduce 库旨在帮助使用成百上千台机器处理海量数据，因此该库必须能够优雅地容忍机器故障 [cite: 167]。

**Worker 故障 (Worker Failure)**

[cite\_start]Master 定期 Ping 每个 Worker [cite: 169][cite\_start]。如果在一定时间内没有收到 Worker 的响应，Master 将该 Worker 标记为已失败 [cite: 169][cite\_start]。该 Worker 完成的任何 Map 任务都会重置回其初始空闲状态，因此有资格在其他 Worker 上重新调度 [cite: 170][cite\_start]。同样，在失败的 Worker 上正在进行的任何 Map 任务或 Reduce 任务也会重置为空闲状态，并有资格重新调度 [cite: 171]。

[cite\_start]已完成的 Map 任务在失败时需要重新执行，因为它们的输出存储在失败机器的本地磁盘上，因此无法访问 [cite: 172][cite\_start]。已完成的 Reduce 任务不需要重新执行，因为它们的输出存储在全局文件系统中 [cite: 173]。

[cite\_start]当一个 Map 任务首先由 Worker A 执行，后来又由 Worker B 执行（因为 A 失败）时，所有执行 Reduce 任务的 Worker 都会收到重新执行的通知 [cite: 174, 176][cite\_start]。任何尚未从 Worker A 读取数据的 Reduce 任务将从 Worker B 读取数据 [cite: 177]。

[cite\_start]MapReduce 对大规模 Worker 故障具有弹性。例如，在一次 MapReduce 操作期间，正在运行的集群上的网络维护导致每组 80 台机器在几分钟内无法访问 [cite: 178][cite\_start]。MapReduce Master 只是重新执行了不可达 Worker 机器所做的工作，并继续取得进展，最终完成了 MapReduce 操作 [cite: 179]。

**Master 故障 (Master Failure)**

[cite\_start]让 Master 写入上述 Master 数据结构的定期检查点（Checkpoints）很容易 [cite: 181][cite\_start]。如果 Master 任务死亡，可以从最后的检查点状态启动一个新的副本 [cite: 182][cite\_start]。然而，鉴于只有一个 Master，其发生故障的可能性不大；因此我们当前的实现如果 Master 失败则中止 MapReduce 计算 [cite: 183, 184][cite\_start]。客户可以检查此情况并在需要时重试 MapReduce 操作 [cite: 185]。

**故障存在时的语义 (Semantics in the Presence of Failures)**

[cite\_start]当用户提供的 Map 和 Reduce 算子是其输入值的确定性函数时，我们的分布式实现产生的输出与整个程序的无故障顺序执行产生的输出相同 [cite: 187]。

[cite\_start]我们依靠 Map 和 Reduce 任务输出的原子提交（atomic commits）来实现这一属性 [cite: 188][cite\_start]。每个正在进行的任务将其输出写入私有临时文件 [cite: 189][cite\_start]。一个 Reduce 任务产生一个这样的文件，一个 Map 任务产生 $R$ 个这样的文件（每个 Reduce 任务一个）[cite: 190][cite\_start]。当 Map 任务完成时，Worker 向 Master 发送一条消息，并在消息中包含 $R$ 个临时文件的名称 [cite: 191][cite\_start]。如果 Master 收到已完成 Map 任务的完成消息，它将忽略该消息 [cite: 192][cite\_start]。否则，它会在 Master 数据结构中记录 $R$ 个文件的名称 [cite: 193]。

[cite\_start]当 Reduce 任务完成时，Reduce Worker 以原子方式将其临时输出文件重命名为最终输出文件 [cite: 194][cite\_start]。如果同一个 Reduce 任务在多台机器上执行，则将针对同一个最终输出文件执行多个重命名调用 [cite: 195][cite\_start]。我们依靠底层文件系统提供的原子重命名操作来保证最终文件系统状态仅包含一次 Reduce 任务执行所产生的数据 [cite: 196]。

[cite\_start]我们绝大多数的 Map 和 Reduce 算子都是确定性的，在这种情况下，我们的语义等同于顺序执行的事实使得程序员很容易推断其程序的行为 [cite: 197, 199][cite\_start]。当 Map 和/或 Reduce 算子是不确定的时候，我们提供较弱但仍然合理的语义 [cite: 200][cite\_start]。在存在不确定算子的情况下，特定 Reduce 任务 $R_{1}$ 的输出等同于不确定程序的顺序执行所产生的 $R_{1}$ 的输出 [cite: 201][cite\_start]。然而，不同 Reduce 任务 $R_{2}$ 的输出可能对应于该不确定程序的不同顺序执行所产生的 $R_{2}$ 的输出 [cite: 202]。

### 3.4 局部性 (Locality)

[cite\_start]在我们的计算环境中，网络带宽是一种相对稀缺的资源 [cite: 207][cite\_start]。我们通过利用输入数据（由 GFS [8] 管理）存储在组成集群的机器的本地磁盘上这一事实来节省网络带宽 [cite: 208][cite\_start]。GFS 将每个文件划分为 64 MB 的块，并在不同的机器上存储每个块的多个副本（通常是 3 个副本）[cite: 209][cite\_start]。MapReduce Master 考虑输入文件的位置信息，并尝试在包含相应输入数据副本的机器上调度 Map 任务 [cite: 210][cite\_start]。如果做不到这一点，它会尝试在任务输入数据的副本附近（例如，在与包含数据的机器处于同一网络交换机的 Worker 机器上）调度 Map 任务 [cite: 211][cite\_start]。当在集群的大部分 Worker 上运行大型 MapReduce 操作时，大多数输入数据是在本地读取的，不消耗网络带宽 [cite: 212]。

### 3.5 任务粒度 (Task Granularity)

[cite\_start]如上所述，我们将 Map 阶段细分为 $M$ 个片段，将 Reduce 阶段细分为 $R$ 个片段 [cite: 214][cite\_start]。理想情况下，$M$ 和 $R$ 应该远大于 Worker 机器的数量 [cite: 215][cite\_start]。让每个 Worker 执行许多不同的任务可以改善动态负载均衡，并且在 Worker 失败时也能加速恢复：它已完成的许多 Map 任务可以分布在所有其他 Worker 机器上 [cite: 216]。

[cite\_start]在我们的实现中，$M$ 和 $R$ 的大小有实际限制，因为 Master 必须做出 $O(M+R)$ 次调度决策，并在内存中保留 $O(M*R)$ 的状态 [cite: 217][cite\_start]。（然而，内存使用的常数因子很小：状态的 $O(M*R)$ 部分包含每个 Map 任务/Reduce 任务对大约一个字节的数据。）[cite: 218]

[cite\_start]此外，$R$ 通常受到用户的限制，因为每个 Reduce 任务的输出最终都在一个单独的输出文件中 [cite: 220][cite\_start]。实际上，我们倾向于选择 $M$，使得每个单独的任务大约是 16 MB 到 64 MB 的输入数据（这样上述的局部性优化最有效），并且我们将 $R$ 设定为我们需要使用的 Worker 机器数量的小倍数 [cite: 221][cite\_start]。我们经常使用 $M=200,000$ 和 $R=5,000$ 执行 MapReduce 计算，使用 2,000 台 Worker 机器 [cite: 222]。

### 3.6 备份任务 (Backup Tasks)

[cite\_start]延长 MapReduce 操作总时间的一个常见原因是“落后者（Straggler）”：一台机器花费异常长的时间来完成计算中最后几个 Map 或 Reduce 任务之一 [cite: 224][cite\_start]。落后者出现的原因有很多。例如，具有坏磁盘的机器可能会遇到频繁的可纠正错误，将其读取性能从 30 MB/s 降低到 1 MB/s [cite: 225][cite\_start]。集群调度系统可能在该机器上调度了其他任务，由于竞争 CPU、内存、本地磁盘或网络带宽，导致 MapReduce 代码执行缓慢 [cite: 226]。

[cite\_start]我们有一种通用机制来减轻落后者的问题 [cite: 228][cite\_start]。当 MapReduce 操作接近完成时，Master 会调度剩余正在进行的任务的备份执行（backup executions） [cite: 229][cite\_start]。无论是主执行还是备份执行完成，该任务都被标记为完成 [cite: 230][cite\_start]。我们调整了这种机制，使其通常只会使操作使用的计算资源增加几个百分点 [cite: 231][cite\_start]。我们发现这显着减少了完成大型 MapReduce 操作的时间 [cite: 232][cite\_start]。例如，当禁用备份任务机制时，5.3 节中描述的排序程序完成时间增加了 44% [cite: 233]。

-----

## 4\. 改进 (Refinements)

[cite\_start]虽然简单地编写 Map 和 Reduce 函数提供的基本功能足以满足大多数需求，但我们发现一些扩展很有用 [cite: 235]。本节将描述这些扩展。

### 4.1 分区函数 (Partitioning Function)

[cite\_start]MapReduce 的用户指定他们想要的 Reduce 任务/输出文件的数量 ($R$) [cite: 238][cite\_start]。数据使用中间键上的分区函数在这些任务之间进行分区 [cite: 239][cite\_start]。提供了一个默认的分区函数，使用哈希（例如 `hash(key) mod R`）[cite: 241][cite\_start]。这往往会导致相当均衡的分区。然而，在某些情况下，通过键的其他函数对数据进行分区是有用的 [cite: 242][cite\_start]。例如，有时输出键是 URL，我们希望来自单个主机的所有条目最终都在同一个输出文件中 [cite: 243][cite\_start]。为了支持这种情况，MapReduce 库的用户可以提供特殊的分区函数 [cite: 244][cite\_start]。例如，使用 `hash(Hostname(urlkey)) mod R` 作为分区函数会导致来自同一主机的所有 URL 最终都在同一个输出文件中 [cite: 245]。

### 4.2 排序保证 (Ordering Guarantees)

[cite\_start]我们保证在给定的分区内，中间键/值对按键的递增顺序处理 [cite: 247][cite\_start]。这种排序保证使得每个分区生成一个排序的输出文件变得容易，这在输出文件格式需要支持按键的高效随机访问查找，或者输出用户发现数据排序很方便时非常有用 [cite: 248]。

### 4.3 Combiner 函数 (Combiner Function)

[cite\_start]在某些情况下，每个 Map 任务产生的中间键存在显着的重复，并且用户指定的 Reduce 函数是可交换和可结合的 [cite: 251][cite\_start]。第 2.1 节中的单词计数示例就是一个很好的例子 [cite: 252][cite\_start]。由于单词频率倾向于遵循 Zipf 分布，每个 Map 任务将产生数百或数千个形式为 `<the, 1>` 的记录 [cite: 253][cite\_start]。所有这些计数都将通过网络发送到单个 Reduce 任务，然后由 Reduce 函数相加产生一个数字 [cite: 254][cite\_start]。我们允许用户指定一个可选的 **Combiner（组合器）** 函数，在通过网络发送数据之前对这些数据进行部分合并 [cite: 255]。

[cite\_start]Combiner 函数在执行 Map 任务的每台机器上执行 [cite: 256][cite\_start]。通常，实现 Combiner 和 Reduce 函数使用相同的代码 [cite: 257][cite\_start]。Reduce 函数和 Combiner 函数之间的唯一区别是 MapReduce 库处理函数输出的方式 [cite: 258][cite\_start]。Reduce 函数的输出被写入最终输出文件 [cite: 259][cite\_start]。Combiner 函数的输出被写入中间文件，该文件将被发送到 Reduce 任务 [cite: 260]。

[cite\_start]部分合并显着加速了某些类别的 MapReduce 操作。附录 A 包含一个使用 Combiner 的示例 [cite: 261]。

### 4.4 输入和输出类型 (Input and Output Types)

[cite\_start]MapReduce 库支持以几种不同的格式读取输入数据 [cite: 263][cite\_start]。例如，“文本”模式输入将每一行视为一个键/值对：键是文件中的偏移量，值是行的内容 [cite: 264, 265][cite\_start]。另一种常见的支持格式存储按键排序的键/值对序列 [cite: 266][cite\_start]。每个输入类型实现都知道如何将自己拆分为有意义的范围以作为单独的 Map 任务进行处理（例如，文本模式的范围拆分确保范围拆分仅发生在行边界处）[cite: 267][cite\_start]。用户可以通过提供简单的读取器接口实现来添加对新输入类型的支持 [cite: 268]。

[cite\_start]以类似的方式，我们支持一组输出类型，用于生成不同格式的数据，并且用户代码很容易添加对新输出类型的支持 [cite: 271]。

### 4.5 副作用 (Side-effects)

[cite\_start]在某些情况下，MapReduce 的用户发现从他们的 Map 和/或 Reduce 算子生成辅助文件作为附加输出很方便 [cite: 273][cite\_start]。我们依靠应用程序编写者使这些副作用具有原子性和幂等性 [cite: 274][cite\_start]。通常，应用程序写入一个临时文件，并在完全生成后原子地重命名该文件 [cite: 275]。

[cite\_start]我们不提供对单个任务生成的多个输出文件的原子两阶段提交的支持 [cite: 276][cite\_start]。因此，产生具有跨文件一致性要求的多个输出文件的任务应该是确定性的 [cite: 277][cite\_start]。这种限制在实践中从未成为问题 [cite: 278]。

### 4.6 跳过坏记录 (Skipping Bad Records)

[cite\_start]有时用户代码中存在错误，导致 Map 或 Reduce 函数在某些记录上确定性地崩溃 [cite: 280][cite\_start]。此类错误会阻止 MapReduce 操作完成。通常的做法是修复错误，但有时这不可行；也许错误在于源代码不可用的第三方库中 [cite: 281, 282][cite\_start]。此外，有时忽略一些记录是可以接受的，例如在对大数据集进行统计分析时 [cite: 283][cite\_start]。我们提供一种可选的执行模式，MapReduce 库会检测哪些记录导致确定性崩溃，并跳过这些记录以继续进行 [cite: 284]。

[cite\_start]每个 Worker 进程都安装了一个信号处理程序，用于捕获分段违规（segmentation violations）和总线错误 [cite: 285][cite\_start]。在调用用户 Map 或 Reduce 操作之前，MapReduce 库将参数的序列号存储在全局变量中 [cite: 286][cite\_start]。如果用户代码生成信号，信号处理程序将向 MapReduce Master 发送包含序列号的“最后一口气” UDP 数据包 [cite: 289][cite\_start]。当 Master 在特定记录上看到不止一次失败时，它会在发出相应 Map 或 Reduce 任务的下一次重新执行时指示应跳过该记录 [cite: 290]。

### 4.7 本地执行 (Local Execution)

[cite\_start]调试 Map 或 Reduce 函数中的问题可能很棘手，因为实际计算发生在分布式系统中，通常在数千台机器上，并且工作分配决策由 Master 动态做出 [cite: 292][cite\_start]。为了便于调试、分析和小规模测试，我们要开发了 MapReduce 库的替代实现，该实现在本地机器上顺序执行 MapReduce 操作的所有工作 [cite: 293][cite\_start]。向用户提供了控件，以便可以将计算限制为特定的 Map 任务 [cite: 294][cite\_start]。用户使用特殊标志调用他们的程序，然后可以轻松使用他们认为有用的任何调试或测试工具（例如 gdb）[cite: 295]。

### 4.8 状态信息 (Status Information)

[cite\_start]Master 运行一个内部 HTTP 服务器并导出一组状态页面供人查阅 [cite: 297][cite\_start]。状态页面显示计算的进度，例如已完成多少任务、正在进行多少任务、输入字节数、中间数据字节数、输出字节数、处理速率等 [cite: 298][cite\_start]。页面还包含指向每个任务生成的标准错误和标准输出文件的链接 [cite: 298][cite\_start]。用户可以使用这些数据来预测计算将花费多长时间，以及是否应该向计算添加更多资源 [cite: 299][cite\_start]。这些页面也可用于弄清楚计算何时比预期慢得多 [cite: 300][cite\_start]。此外，顶级状态页面显示哪些 Worker 失败了，以及它们失败时正在处理哪些 Map 和 Reduce 任务 [cite: 301][cite\_start]。在尝试诊断用户代码中的错误时，此信息很有用 [cite: 302]。

### 4.9 计数器 (Counters)

[cite\_start]MapReduce 库提供了一个计数器工具来统计各种事件的发生次数 [cite: 304][cite\_start]。例如，用户代码可能想要统计处理的单词总数或索引的德语文档数量等 [cite: 305]。

[cite\_start]为了使用此工具，用户代码创建一个命名的计数器对象，然后在 Map 和/或 Reduce 函数中适当地增加计数器 [cite: 306]。例如：

```c++
Counter* uppercase;
uppercase = GetCounter("uppercase");

map(String name, String contents):
    for each word w in contents:
        if (IsCapitalized(w)):
            uppercase->Increment();
        EmitIntermediate(w, "1");
```

[cite\_start]来自各个 Worker 机器的计数器值定期传播到 Master（搭载在 Ping 响应上）[cite: 312][cite\_start]。Master 聚合来自成功的 Map 和 Reduce 任务的计数器值，并在 MapReduce 操作完成时将它们返回给用户代码 [cite: 313][cite\_start]。当前的计数器值也显示在 Master 状态页面上，以便人类可以观察实时计算的进度 [cite: 314][cite\_start]。在聚合计数器值时，Master 消除同一 Map 或 Reduce 任务的重复执行的影响，以避免重复计数 [cite: 315][cite\_start]。（重复执行可能源于我们要使用的备份任务和由于故障导致的任务重新执行。）[cite: 316]

[cite\_start]MapReduce 库自动维护一些计数器值，例如处理的输入键/值对的数量和产生的输出键/值对的数量 [cite: 317]。

[cite\_start]用户发现计数器工具对于检查 MapReduce 操作行为的健全性很有用 [cite: 318][cite\_start]。例如，在某些 MapReduce 操作中，用户代码可能希望确保产生的输出对的数量完全等于处理的输入对的数量，或者处理的德语文档的比例在处理的文档总数的某个可容忍比例范围内 [cite: 319]。

-----

## 5\. 性能 (Performance)

[cite\_start]在本节中，我们测量 MapReduce 在大型机器集群上运行两个计算时的性能 [cite: 321][cite\_start]。一个计算在大约 1 TB 的数据中搜索特定模式 [cite: 322][cite\_start]。另一个计算对大约 1 TB 的数据进行排序 [cite: 323][cite\_start]。这两个程序代表了 MapReduce 用户编写的大部分实际程序——一类程序将数据从一种表示形式混洗（shuffle）到另一种表示形式，另一类程序从大数据集中提取少量有趣的数据 [cite: 324]。

### 5.1 集群配置 (Cluster Configuration)

[cite\_start]所有程序都在由大约 1800 台机器组成的集群上执行 [cite: 326][cite\_start]。每台机器都有两个启用超线程的 2GHz Intel Xeon 处理器、4GB 内存、两个 160GB IDE 磁盘和一个千兆以太网链路 [cite: 327][cite\_start]。机器被安排在一个两级树形交换网络中，根部具有大约 100-200 Gbps 的聚合带宽 [cite: 336][cite\_start]。所有机器都在同一个托管设施中，因此任何一对机器之间的往返时间小于 1 毫秒 [cite: 337]。

[cite\_start]在 4GB 内存中，大约 1-1.5GB 被运行在集群上的其他任务预留 [cite: 338][cite\_start]。程序是在周末下午执行的，当时 CPU、磁盘和网络大多处于空闲状态 [cite: 339]。

### 5.2 Grep

[cite\_start]Grep 程序扫描 $10^{10}$ 个 100 字节的记录，搜索一个相对罕见的三个字符的模式（该模式出现在 92,337 个记录中）[cite: 341][cite\_start]。输入被拆分为大约 64MB 的片段 ($M=15000$)，整个输出放在一个文件中 ($R=1$) [cite: 342]。

\![图 2: 随时间变化的数据传输率](source: 335)
*图 2：随时间变化的数据传输率*

[cite\_start]图 2 显示了计算随时间推移的进度 [cite: 343][cite\_start]。Y 轴显示扫描输入数据的速率 [cite: 344][cite\_start]。随着更多机器被分配给此 MapReduce 计算，速率逐渐上升，并在分配了 1764 个 Worker 时达到超过 30 GB/s 的峰值 [cite: 345][cite\_start]。随着 Map 任务完成，速率开始下降，并在计算开始大约 80 秒后降为零 [cite: 346][cite\_start]。整个计算从开始到结束大约需要 150 秒 [cite: 347][cite\_start]。这包括大约一分钟的启动开销 [cite: 347][cite\_start]。开销是由于程序传播到所有 Worker 机器，以及与 GFS 交互以打开 1000 个输入文件集并获取局部性优化所需信息造成的延迟 [cite: 348]。

### 5.3 排序 (Sort)

[cite\_start]排序程序对 $10^{10}$ 个 100 字节的记录（大约 1 TB 数据）进行排序 [cite: 350][cite\_start]。该程序模仿 TeraSort 基准测试 [cite: 351]。

[cite\_start]排序程序包含不到 50 行的用户代码 [cite: 352][cite\_start]。三行的 Map 函数从文本行中提取 10 字节的排序键，并发出键和原始文本行作为中间键/值对 [cite: 353, 427][cite\_start]。我们使用内置的 Identity 函数作为 Reduce 算子 [cite: 427][cite\_start]。此函数将中间键/值对原样作为输出键/值对传递 [cite: 428][cite\_start]。最终排序后的输出被写入一组 2 路复制的 GFS 文件（即，作为程序输出写入 2 TB）[cite: 429]。

[cite\_start]如前所述，输入数据被拆分为 64MB 的片段 ($M=15000$) [cite: 430][cite\_start]。我们将排序后的输出划分为 4000 个文件 ($R=4000$) [cite: 431][cite\_start]。分区函数使用键的初始字节将其隔离到 $R$ 个片段之一中 [cite: 431][cite\_start]。我们针对此基准测试的分区函数内置了键分布的知识 [cite: 432][cite\_start]。在通用的排序程序中，我们会添加一个预处理 MapReduce 操作，该操作将收集键的样本，并使用采样键的分布来计算最终排序过程的拆分点 [cite: 433]。

\![图 3: 排序程序不同执行过程中的数据传输率](source: 426)
*图 3：排序程序不同执行过程中的数据传输率*

[cite\_start]图 3 (a) 显示了排序程序正常执行的进度 [cite: 434][cite\_start]。左上图显示了读取输入的速率 [cite: 435][cite\_start]。速率峰值约为 13 GB/s，并且由于所有 Map 任务在 200 秒过去之前完成而迅速消退 [cite: 436][cite\_start]。注意输入速率低于 grep [cite: 437][cite\_start]。这是因为排序 Map 任务花费大约一半的时间和 I/O 带宽将中间输出写入其本地磁盘 [cite: 438][cite\_start]。grep 的相应中间输出大小可以忽略不计 [cite: 439]。

[cite\_start]左中图显示了数据从 Map 任务通过网络发送到 Reduce 任务的速率 [cite: 440][cite\_start]。这种混洗（shuffling）在第一个 Map 任务完成后立即开始 [cite: 441][cite\_start]。图中的第一个驼峰是针对第一批大约 1700 个 Reduce 任务的（整个 MapReduce 被分配了大约 1700 台机器，每台机器一次最多执行一个 Reduce 任务）[cite: 443][cite\_start]。计算进行大约 300 秒后，第一批 Reduce 任务中的一些完成了，我们开始为剩余的 Reduce 任务混洗数据 [cite: 444][cite\_start]。所有的混洗在计算进行大约 600 秒后完成 [cite: 445]。

[cite\_start]左下图显示了 Reduce 任务将排序后的数据写入最终输出文件的速率 [cite: 446][cite\_start]。在第一次混洗周期结束和写入周期开始之间存在延迟，因为机器正忙于对中间数据进行排序 [cite: 447][cite\_start]。写入持续了一段时间，速率约为 2-4 GB/s [cite: 448][cite\_start]。所有写入在计算进行大约 850 秒后完成 [cite: 449][cite\_start]。包括启动开销在内，整个计算耗时 891 秒 [cite: 449][cite\_start]。这与 TeraSort 基准测试目前报告的最佳结果 1057 秒相似 [cite: 450]。

[cite\_start]需要注意几点：输入速率高于混洗速率和输出速率，这是因为我们的局部性优化——大多数数据是从本地磁盘读取的，绕过了我们相对带宽受限的网络 [cite: 451][cite\_start]。混洗速率高于输出速率，因为输出阶段写入排序数据的两个副本（出于可靠性和可用性原因，我们要制作输出的两个副本）[cite: 452][cite\_start]。如果是底层文件系统使用纠删码（erasure coding）而不是复制，则写入数据的网络带宽需求将减少 [cite: 454]。

### 5.4 备份任务的影响 (Effect of Backup Tasks)

[cite\_start]在图 3 (b) 中，我们显示了禁用备份任务的排序程序的执行情况 [cite: 457][cite\_start]。执行流程与图 3 (a) 所示类似，只是有一个很长的尾部，几乎没有发生任何写入活动 [cite: 458][cite\_start]。960 秒后，除 5 个 Reduce 任务外，所有任务都完成了 [cite: 459][cite\_start]。然而，这最后几个落后者直到 300 秒后才完成 [cite: 460][cite\_start]。整个计算耗时 1283 秒，耗时增加了 44% [cite: 461]。

### 5.5 机器故障 (Machine Failures)

[cite\_start]在图 3 (c) 中，我们显示了排序程序的执行情况，其中我们在计算几分钟后故意杀死了 1746 个 Worker 进程中的 200 个 [cite: 463][cite\_start]。底层集群调度程序立即在这些机器上重新启动了新的 Worker 进程（因为只是进程被杀死，机器仍然正常运行）[cite: 464]。

[cite\_start]Worker 的死亡显示为负输入速率，因为一些先前完成的 Map 工作消失了（因为相应的 Map Worker 被杀死）并且需要重做 [cite: 465][cite\_start]。此 Map 工作的重新执行发生得相对较快 [cite: 466][cite\_start]。整个计算在 933 秒内完成，包括启动开销（仅比正常执行时间增加 5%）[cite: 466]。

-----

## 6\. 经验 (Experience)

[cite\_start]我们在 2003 年 2 月编写了 MapReduce 库的第一个版本，并在 2003 年 8 月对其进行了重大增强，包括局部性优化、跨 Worker 机器的任务执行动态负载均衡等 [cite: 468][cite\_start]。自那时起，我们惊喜地发现 MapReduce 库对我们处理的问题类型的适用性非常广泛 [cite: 468]。它已在 Google 内部广泛用于各种领域，包括：

  * [cite\_start]大规模机器学习问题 [cite: 470]；
  * [cite\_start]Google News 和 Froogle 产品的聚类问题 [cite: 471]；
  * [cite\_start]提取用于生成热门查询报告的数据（例如 Google Zeitgeist）[cite: 472]；
  * [cite\_start]为新实验和产品提取网页属性（例如，从大量网页语料库中提取地理位置以进行本地化搜索）[cite: 473]；以及
  * [cite\_start]大规模图计算 [cite: 474]。

\![图 4: 随时间变化的 MapReduce 实例数](source: 488)
*图 4：随时间变化的 MapReduce 实例数*

[cite\_start]表 1：2004 年 8 月运行的 MapReduce 作业 [cite: 490]

| 指标 | 数量 |
| :--- | :--- |
| 作业数量 | 29,423 |
| 平均作业完成时间 | 634 秒 |
| 使用的机器天数 | 79,186 天 |
| 读取的输入数据 | 3,288 TB |
| 产生的中间数据 | 758 TB |
| 写入的输出数据 | 193 TB |
| 每个作业的平均 Worker 机器数 | 157 |
| 每个作业的平均 Worker 死亡数 | 1.2 |
| 每个作业的平均 Map 任务数 | 3,351 |
| 每个作业的平均 Reduce 任务数 | 55 |
| 唯一的 Map 实现 | 395 |
| 唯一的 Reduce 实现 | 269 |
| 唯一的 Map/Reduce 组合 | 426 |

[cite\_start]图 4 显示了随着时间的推移，检入我们要主源代码管理系统的独立 MapReduce 程序的数量显着增长，从 2003 年初的 0 增长到 2004 年 9 月下旬的近 900 个独立实例 [cite: 491][cite\_start]。MapReduce 如此成功是因为它使得编写一个简单的程序并在半小时内在数千台机器上高效运行成为可能，极大地加快了开发和原型设计周期 [cite: 491][cite\_start]。此外，它允许没有分布式和/或并行系统经验的程序员轻松利用大量资源 [cite: 492]。

[cite\_start]在每个作业结束时，MapReduce 库会记录有关该作业使用的计算资源的统计信息 [cite: 493][cite\_start]。在表 1 中，我们显示了 2004 年 8 月在 Google 运行的 MapReduce 作业子集的一些统计信息 [cite: 494]。

### 6.1 大规模索引 (Large-Scale Indexing)

[cite\_start]迄今为止，我们对 MapReduce 最重要的用途之一是完全重写了生产索引系统，该系统生成用于 Google Web 搜索服务的数据结构 [cite: 496][cite\_start]。索引系统将爬虫系统检索到的、存储为一组 GFS 文件的大量文档作为输入 [cite: 499][cite\_start]。这些文档的原始内容超过 20 TB [cite: 500][cite\_start]。索引过程作为 5 到 10 个 MapReduce 操作的序列运行 [cite: 501][cite\_start]。使用 MapReduce（而不是索引系统先前版本中的临时分布式传递）提供了几个好处 [cite: 502]：

  * [cite\_start]索引代码更简单、更小、更容易理解，因为处理容错、分发和并行化的代码隐藏在 MapReduce 库中 [cite: 503][cite\_start]。例如，当使用 MapReduce 表达时，计算的一个阶段的大小从大约 3800 行 C++ 代码下降到大约 700 行 [cite: 504]。
  * [cite\_start]MapReduce 库的性能足够好，以至于我们可以将概念上不相关的计算分开，而不是为了避免额外的数据传递而将它们混合在一起 [cite: 505][cite\_start]。这使得更改索引过程变得容易 [cite: 506][cite\_start]。例如，在我们的旧索引系统中需要几个月才能完成的一项更改，在新系统中只需几天即可实现 [cite: 506]。
  * [cite\_start]索引过程变得更容易操作，因为由机器故障、慢速机器和网络中断引起的大多数问题都由 MapReduce 库自动处理，无需操作员干预 [cite: 507][cite\_start]。此外，通过向索引集群添加新机器，很容易提高索引过程的性能 [cite: 508]。

-----

## 7\. 相关工作 (Related Work)

[cite\_start]许多系统提供了受限的编程模型，并利用这些限制来自动并行化计算 [cite: 510][cite\_start]。例如，可以使用并行前缀计算在 $N$ 个处理器上以 $\log N$ 的时间计算 $N$ 元素数组的所有前缀的关联函数 [cite: 511][cite\_start]。MapReduce 可以被视为基于我们对大型现实世界计算的经验，对其中一些模型的简化和提炼 [cite: 512][cite\_start]。更重要的是，我们提供了一个可扩展到数千个处理器的容错实现 [cite: 513][cite\_start]。相比之下，大多数并行处理系统仅在较小的规模上实现，并将处理机器故障的细节留给程序员 [cite: 514]。

[cite\_start]Bulk Synchronous Programming [17] 和一些 MPI 原语 [11] 提供了更高级别的抽象，使程序员更容易编写并行程序 [cite: 515, 517][cite\_start]。这些系统与 MapReduce 的一个关键区别在于，MapReduce 利用受限的编程模型来自动并行化用户程序并提供透明的容错功能 [cite: 518]。

[cite\_start]我们的局部性优化灵感来自诸如 active disks [12, 15] 等技术，这些技术将计算推送到靠近本地磁盘的处理元件中，以减少通过 I/O 子系统或网络发送的数据量 [cite: 519][cite\_start]。我们在直接连接少量磁盘的普通商用处理器上运行，而不是直接在磁盘控制器处理器上运行，但一般方法是相似的 [cite: 520]。

[cite\_start]我们的备份任务机制类似于 Charlotte 系统 [3] 中使用的 eager scheduling 机制 [cite: 521][cite\_start]。简单的 eager scheduling 的缺点之一是，如果给定的任务导致重复失败，则整个计算无法完成 [cite: 522][cite\_start]。我们通过跳过坏记录的机制修复了此问题的一些实例 [cite: 523]。

[cite\_start]MapReduce 实现依赖于内部集群管理系统，该系统负责在大量共享机器上分发和运行用户任务 [cite: 524][cite\_start]。虽然不是本文的重点，但集群管理系统在精神上类似于 Condor [16] 等其他系统 [cite: 525]。

[cite\_start]MapReduce 库中的排序工具在操作上类似于 NOW-Sort [1] [cite: 526][cite\_start]。源机器（Map Worker）将被排序的数据分区并将其发送到 $R$ 个 Reduce Worker 中的一个 [cite: 527][cite\_start]。每个 Reduce Worker 在本地对其数据进行排序（如果可能的话在内存中）[cite: 528][cite\_start]。当然，NOW-Sort 没有使用户库广泛适用的用户可定义的 Map 和 Reduce 函数 [cite: 529]。

[cite\_start]River [2] 提供了一种编程模型，其中进程通过分布式队列发送数据来相互通信 [cite: 530][cite\_start]。与 MapReduce 一样，River 系统试图即使在异构硬件或系统扰动引入非均匀性的情况下也能提供良好的平均情况性能 [cite: 531][cite\_start]。River 通过仔细调度磁盘和网络传输来实现平衡的完成时间 [cite: 532][cite\_start]。MapReduce 采用了不同的方法。通过限制编程模型，MapReduce 框架能够将问题划分为大量细粒度的任务 [cite: 533][cite\_start]。这些任务在可用的 Worker 上动态调度，以便更快的 Worker 处理更多任务 [cite: 534][cite\_start]。受限的编程模型还允许我们在作业接近尾声时调度任务的冗余执行，这极大地减少了在存在非均匀性（如慢速或卡住的 Worker）的情况下的完成时间 [cite: 535]。

[cite\_start]BAD-FS [5] 具有与 MapReduce 非常不同的编程模型，并且与 MapReduce 不同，它针对的是跨广域网的作业执行 [cite: 536][cite\_start]。然而，有两个基本的相似之处 [cite: 538][cite\_start]。(1) 两个系统都使用冗余执行来从故障引起的数据丢失中恢复 [cite: 539][cite\_start]。(2) 两者都使用感知局部性的调度来减少通过拥塞网络链路发送的数据量 [cite: 540]。

[cite\_start]TACC [7] 是一个旨在简化高可用性网络服务构建的系统 [cite: 541][cite\_start]。与 MapReduce 一样，它依赖于重新执行作为实现容错的机制 [cite: 542]。

-----

## 8\. 结论 (Conclusions)

[cite\_start]MapReduce 编程模型已在 Google 成功用于许多不同的目的 [cite: 544][cite\_start]。我们将此成功归因于几个原因。首先，该模型易于使用，即使对于没有并行和分布式系统经验的程序员也是如此，因为它隐藏了并行化、容错、局部性优化和负载均衡的细节 [cite: 545][cite\_start]。其次，各种各样的问题都可以轻松地表达为 MapReduce 计算 [cite: 546][cite\_start]。例如，MapReduce 用于为 Google 的生产网络搜索服务生成数据、用于排序、用于数据挖掘、用于机器学习以及许多其他系统 [cite: 547][cite\_start]。第三，我们开发了一个 MapReduce 实现，可以扩展到包含数千台机器的大型机器集群 [cite: 548][cite\_start]。该实现有效地利用了这些机器资源，因此适用于 Google 遇到的许多大型计算问题 [cite: 549]。

[cite\_start]我们从这项工作中学到了几件事。首先，限制编程模型使得并行化和分发计算以及使此类计算具有容错性变得容易 [cite: 550][cite\_start]。其次，网络带宽是一种稀缺资源 [cite: 551][cite\_start]。因此，我们系统中的许多优化都针对减少通过网络发送的数据量：局部性优化允许我们要从本地磁盘读取数据，将中间数据的单个副本写入本地磁盘可以节省网络带宽 [cite: 551][cite\_start]。第三，冗余执行可用于减少慢速机器的影响，并处理机器故障和数据丢失 [cite: 552]。

-----

## 附录 A：单词频率 (Word Frequency)

[cite\_start]本节包含一个程序，用于统计在命令行指定的输入文件集中每个唯一单词的出现次数 [cite: 600]。

```c++
#include "mapreduce/mapreduce.h"

// 用户的 Map 函数
class WordCounter : public Mapper {
public:
    virtual void Map(const MapInput& input) {
        const string& text = input.value();
        const int n = text.size();
        for (int i = 0; i < n; ) {
            // 跳过前导空格
            while ((i < n) && isspace(text[i]))
                i++;
            
            // 找到单词结尾
            int start = i;
            while ((i < n) && !isspace(text[i]))
                i++;
            
            if (start < i)
                Emit(text.substr(start, i-start), "1");
        }
    }
};

REGISTER_MAPPER(WordCounter);

// 用户的 Reduce 函数
class Adder : public Reducer {
public:
    virtual void Reduce(ReduceInput* input) {
        // 迭代具有相同键的所有条目并累加值
        int64 value = 0;
        while (!input->done()) {
            value += StringToInt(input->value());
            input->NextValue();
        }
        // 发出 input->key() 的总和
        Emit(IntToString(value));
    }
};

REGISTER_REDUCER(Adder);

int main(int argc, char** argv) {
    ParseCommandLineFlags(argc, argv);
    
    MapReduceSpecification spec;
    
    // 将输入文件列表存入 "spec"
    for (int i = 1; i < argc; i++) {
        MapReduceInput* input = spec.add_input();
        input->set_format("text");
        input->set_filepattern(argv[i]);
        input->set_mapper_class("WordCounter");
    }
    
    // 指定输出文件:
    // /gfs/test/freq-00000-of-00100
    // /gfs/test/freq-00001-of-00100
    // ...
    MapReduceOutput* out = spec.output();
    out->set_filebase("/gfs/test/freq");
    out->set_num_tasks(100);
    out->set_format("text");
    out->set_reducer_class("Adder");
    
    // 可选: 在 map 任务中进行部分求和以节省网络带宽
    out->set_combiner_class("Adder");
    
    // 调优参数: 最多使用 2000 台机器，每个任务 100 MB 内存
    spec.set_machines(2000);
    spec.set_map_megabytes(100);
    spec.set_reduce_megabytes(100);
    
    // 现在运行它
    MapReduceResult result;
    if (!MapReduce(spec, &result)) abort();
    
    // 完成: 'result' 结构包含有关计数器、耗时、使用的机器数量等信息
    return 0;
}
```