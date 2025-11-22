+++
date = '2025-11-22T15:44:01+08:00'
draft = false
title = 'MapReduce：大型集群上的简化数据处理(英译中)'
categories = []
tags = []
series = ["分布式系统学习"]
math = true       
+++

本文是 **《MapReduce：Simplified Data Processing on Large Clusters》** 论文的中文翻译。

该论文是分布式系统领域的里程碑式工作，提出了 MapReduce 编程模型，极大地简化了大规模数据处理任务的开发难度。MapReduce 与 GFS（Google File System）和 Bigtable 并称为“Google三驾马车”，成为支撑 Google 大规模数据处理和存储的核心基础设施之一。无论你是刚入门分布式系统开发，还是希望深入理解现代大数据处理的核心思想，深入阅读和理解此文都具有重要的学习价值。  

特别需要注意的是，这篇论文也是 **MIT 6.824** 第一讲（Lecture 1: Introduction）的核心阅读材料之一，对于打好分布式系统理论与工程实践的基础极为关键。

【*免责声明*】  
**本译文仅供个人学习与学术交流，严禁用于任何商业用途。如涉及版权问题，请即联系以便及时处理和删除。**

> **原文链接**：[https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/mapreduce-osdi04.pdf](https://static.googleusercontent.com/media/research.google.com/zh-CN//archive/mapreduce-osdi04.pdf)



# MapReduce：大型集群上的简化数据处理

**Jeffrey Dean and Sanjay Ghemawat**

jeff@google.com, sanjay@google.com

*Google, Inc.*

## 摘要 (Abstract)

MapReduce is a programming model and an associ-ated implementation for processing and generating large data sets. Users specify a **map** function that processes a key/value pair to generate a set of intermediate key/value pairs, and a **reduce** function that merges all intermediate values associated with the same intermediate key. Many real-world tasks can be expressed in this model, as shown in the paper.

> MapReduce是一种编程模型，以及一种用于处理和生成大规模数据集的配套实现。用户需指定一个**Map(映射)函数**来处理键/值对并生成一组中间键/值对，以及一个**Reduce(归约)函数**来合并所有与同一中间键关联的中间值。许多现实任务都可以用这个模型来表达，正如本文所展示的。

Programs written in this functional style are automati-cally parallelized and executed on a large cluster of com-modity machines. The run-time system takes care of the details of partitioning the input data, scheduling the pro-gram's execution across a set of machines, handling ma-chine failures, and managing the required inter-machine communication. This allows programmers without any experience with parallel and distributed systems to eas-ily utilize the resources of a large distributed system.

> 采用这种函数式风格编写的程序会自动并行化，并在由廉价商用机器组成的大型集群上执行。运行时系统会处理输入数据分区、跨多台机器调度程序执行、处理机器故障以及管理机器间通信等所有细节。这使得即使是毫无并行和分布式系统经验的程序员，也能轻松利用大型分布式系统的资源。

Our implementation of **MapReduce** runs on a large
cluster of commodity machines and is highly scalable:
a typical MapReduce computation processes many ter-
abytes of data on thousands of machines. Programmers
find the system easy to use: hundreds of MapReduce pro-
grams have been implemented and upwards of one thou-
sand MapReduce jobs are executed on Google's clusters
every day.

> 我们的MapReduce实现运行在由廉价商用机器组成的大型集群上，并具有极高的可扩展性：一次典型的MapReduce计算可在数千台机器上处理数TB的数据。程序员们发现该系统易于使用：已有数百个MapReduce程序被实现，每天在Google集群上执行的MapReduce作业超过一千个。

-----

## 1\. 介绍 (Introduction)

Over the past five years, the authors and many others at Google have implemented hundreds of special-purpose computations that process large amounts of raw data, such as crawled documents, web request logs, etc., in order to compute various kinds of derived data, such as inverted indices, various representations of the graph structure of web documents, summaries of the number of pages crawled per host, the set of most frequent queries in a given day, and so on. Most such computations are conceptu-ally straightforward. However, the input data is usually large, and the computations have to be distributed across hundreds or thousands of machines in order to finish in a reasonable amount of time. The issues of how to par-allelize the computation, distribute the data, and handle failures often conspire to obscure the original simple computation with large amounts of complex code to deal with these issues.

> 在过去五年中，作者和Google的许多同事实现了数百个专用计算程序来处理大量原始数据(如抓取的文档、Web请求日志等)，以计算各种派生数据，如倒排索引、Web文档图结构的各种表示、每台主机抓取的页面数量汇总、给定一天内最频繁的查询集合等。大多数这类计算在概念上都很直接。然而，输入数据通常很大，为了在合理时间内完成，计算必须分布到数百或数千台机器上。如何并行化计算、分发数据和处理故障这些问题，往往会让原本简单的计算被大量用于处理这些问题的复杂代码所掩盖。

As a reaction to this complexity, we designed a new abstraction that allows us to express the simple computa-tions we were trying to perform but hides the messy de-tails of parallelization, fault-tolerance, data distribution and load balancing in a library. Our abstraction is in-spired by the map and reduce primitives present in Lisp and many other functional languages. We realized that most of our computations involved applying a map op- eration to each logical "record" in our input in order to compute a set of intermediate key/value pairs, and then applying a reduce operation to all the values that shared the same key, in order to combine the derived data ap-propriately. Our use of a functional model with user-specified map and reduce operations allows us to paral-lelize large computations easily and to use re-execution as the primary mechanism for fault tolerance.

> 为应对这一复杂性，我们设计了一种新的抽象，它允许我们表达想要执行的简单计算，同时将并行化、容错、数据分发和负载均衡等繁琐细节隐藏在库中。我们的抽象受到Lisp及许多其他函数式语言中map和reduce原语的启发。我们意识到，大多数计算都涉及对输入中的每个逻辑"记录"应用一次map操作以计算一组中间键/值对，然后对共享同一键的所有值应用reduce操作，以恰当地组合派生数据。使用这种带有用户指定map和reduce操作的函数式模型，使我们能够轻松地并行化大型计算，并将重新执行作为容错的主要机制。

The major contributions of this work are a simple and powerful interface that enables automatic parallelization and distribution of large-scale computations, combined with an implementation of this interface that achieves high performance on large clusters of commodity PCs.

> 本文的主要贡献包括：一个简单而强大的接口(能实现大规模计算的自动并行化和分发)，以及该接口在大型廉价PC集群上的高性能实现。

Section 2 describes the basic programming model and gives several examples. Section 3 describes an imple-mentation of the MapReduce interface tailored towards our cluster-based computing environment. Section 4 de-scribes several refinements of the programming model that we have found useful. Section 5 has performance measurements of our implementation for a variety of tasks. Section 6 explores the use of MapReduce within Google including our experiences in using it as the basis for a rewrite of our production indexing system. Sec-tion 7 discusses related and future work.

> 第2节描述了基本的编程模型并给出几个示例。第3节描述了针对我们基于集群的计算环境定制的MapReduce接口实现。第4节描述了编程模型的几项我们认为有用的改进。第5节给出了我们的实现在多种任务上的性能测量结果。第6节探讨了MapReduce在Google内的使用，包括我们将其作为基础重写生产索引系统的经验。第7节讨论了相关工作和未来工作。

-----

## 2\. 编程模型 (Programming Model)

The computation takes a set of input key/value pairs, and produces a set of output key/value pairs. The user of the MapReduce library expresses the computation as two functions: Map and Reduce.

> 该计算接受一组输入键/值对，产生一组输出键/值对。用户使用两个函数来表达计算：**Map**和**Reduce**。

Map, written by the user, takes an input pair and pro-duces a set of intermediate key/value pairs. The MapRe-duce library groups together all intermediate values asso-ciated with the same intermediate key I and passes them to the Reduce function.

> **Map**函数由用户编写，接受一个输入键/值对，产生一组中间键/值对。MapReduce库将所有与同一中间键$I$关联的中间值组合在一起，并传递给**Reduce**函数。

The Reduce function, also written by the user, accepts an intermediate key I and a set of values for that key. It merges together these values to form a possibly smaller set of values. Typically just zero or one output value is produced per Reduce invocation. The intermediate val-ues are supplied to the user's reduce function via an iter-ator. This allows us to handle lists of values that are too large to fit in memory.

> **Reduce**函数也由用户编写，接受一个中间键$I$和该键的一组值。它将这些值合并，形成一个可能更小的值集合。通常每次Reduce调用只产生零个或一个输出值。中间值通过迭代器提供给用户的reduce函数。这使我们能够处理太大而无法放入内存的值列表。

### 2.1 示例 (Example)

考虑计算大量文档集合中每个单词出现次数的问题。用户将编写类似以下伪代码的代码：

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

Map 函数发出每个单词及其相关的出现次数（在这个简单的例子中就是 '1'）。Reduce 函数将特定单词发出的所有计数求和。

此外，用户编写代码填充一个 mapreduce 规范对象，其中包含输入和输出文件的名称以及可选的调优参数。然后用户调用 MapReduce 函数，并将规范对象传递给它。用户的代码与 MapReduce 库（用 C++ 实现）链接在一起。附录 A 包含此示例的完整程序文本。

### 2.2 类型 (Types)

尽管前面的伪代码是用字符串输入和输出编写的，但在概念上，用户提供的 Map 和 Reduce 函数具有关联的类型：

```text
map     (k1, v1)       ->  list(k2, v2)
reduce  (k2, list(v2)) ->  list(v2)
```

即，输入键和值来自与输出键和值不同的域。此外，中间键和值与输出键和值来自同一域。

我们的 C++ 实现将字符串传递给用户定义的函数，并从用户定义的函数接收字符串，留给用户代码在字符串和适当类型之间进行转换。

### 2.3 更多示例 (More Examples)

以下是一些可以轻松表示为 MapReduce 计算的有趣程序的简单示例：

  * **分布式 Grep (Distributed Grep)：** Map 函数如果匹配提供的模式则发出一行。Reduce 函数是一个恒等函数，只是将提供的中间数据复制到输出。
  * **URL 访问频率计数 (Count of URL Access Frequency)：** Map 函数处理网页请求日志并输出 `(URL, 1)`。Reduce 函数将相同 URL 的所有值相加，并发出 `(URL, total count)` 对。
  * **反向 Web 链接图 (Reverse Web-Link Graph)：** Map 函数为在名为 `source` 的页面中找到的指向 `target` URL 的每个链接输出 `(target, source)` 对。Reduce 函数将与给定 `target` URL 关联的所有 `source` URL 列表连接起来，并发出对：`(target, list(source))`。
  * **每台主机的术语向量 (Term-Vector per Host)：** 术语向量将文档或文档集中出现的最重要的单词总结为 `(word, frequency)` 对列表。Map 函数为每个输入文档发出一个 `(hostname, term vector)` 对（其中 hostname 从文档的 URL 中提取）。Reduce 函数接收给定主机的所有每文档术语向量。它将这些术语向量相加，丢弃不频繁的术语，然后发出最终的 `(hostname, term vector)` 对。
  ![](/images/Figure-1.png)

  * **倒排索引 (Inverted Index)：** Map 函数解析每个文档，并发出一个 `(word, document ID)` 对序列。Reduce 函数接受给定单词的所有对，对相应的文档 ID 进行排序，并发出一个 `(word, list(document ID))` 对。所有输出对的集合形成一个简单的倒排索引。以此计算为基础增加跟踪单词位置的功能也很容易。
  * **分布式排序 (Distributed Sort)：** Map 函数从每个记录中提取键，并发出 `(key, record)` 对。Reduce 函数原样发出所有对。此计算依赖于 4.1 节中描述的分区工具和 4.2 节中描述的排序属性。

-----

## 3\. 实现 (Implementation)

MapReduce 接口可能有许多不同的实现。正确的选择取决于环境。例如，一种实现可能适合小型共享内存机器，另一种适合大型 NUMA 多处理器，还有一种适合更大的网络机器集合。

本节描述了针对 Google 广泛使用的计算环境的实现：通过交换式以太网连接在一起的大型普通商用 PC 集群。在我们的环境中：

1.  机器通常是运行 Linux 的双处理器 x86 处理器，每台机器有 2-4 GB 内存。
2.  使用普通网络硬件，机器层面通常为 100 Mb/s 或 1 Gb/s，但整体二分带宽（bisection bandwidth）平均要低得多。
3.  一个集群由数百或数千台机器组成，因此机器故障很常见。
4.  存储由直接连接到各个机器的廉价 IDE 磁盘提供。内部开发的分布式文件系统（GFS）用于管理存储在这些磁盘上的数据。该文件系统使用复制在不可靠的硬件之上提供可用性和可靠性。
5.  用户将作业提交给调度系统。每个作业由一组任务组成，由调度程序映射到集群内的一组可用机器上。

### 3.1 执行概览 (Execution Overview)

Map 调用通过自动将输入数据划分为 $M$ 个拆分（split）分布在多台机器上。输入拆分可以由不同的机器并行处理。Reduce 调用通过使用分区函数（例如 `hash(key) mod R`）将中间键空间划分为 $R$ 个片段来分布。分区数量 ($R$) 和分区函数由用户指定。

*图 1：执行概览*

图 1 显示了我们的实现中 MapReduce 操作的整体流程。当用户程序调用 MapReduce 函数时，会发生以下操作序列（图 1 中的数字标签对应于下面的列表）：

1.  用户程序中的 MapReduce 库首先将输入文件拆分为 $M$ 个片段，通常每个片段 16 MB 到 64 MB（用户可通过可选参数控制）。然后它在集群的一组机器上启动程序的许多副本。
2.  程序副本中有一个是特殊的——**Master（主节点）**。其余的是由 Master 分配工作的 **Worker（工作节点）**。有 $M$ 个 Map 任务和 $R$ 个 Reduce 任务需要分配。Master 选择空闲的 Worker 并为每个 Worker 分配一个 Map 任务或 Reduce 任务。
3.  被分配了 Map 任务的 Worker 读取相应输入拆分的内容。它从输入数据中解析出键/值对，并将每一对传递给用户定义的 Map 函数。Map 函数产生的中间键/值对缓存在内存中。
4.  定期地，缓冲的对被写入本地磁盘，并由分区函数划分为 $R$ 个区域。这些缓冲对在本地磁盘上的位置被传回给 Master，Master 负责将这些位置转发给 Reduce Worker。
5.  当 Reduce Worker 收到 Master 关于这些位置的通知时，它使用远程过程调用（RPC）从 Map Worker 的本地磁盘读取缓冲数据。当 Reduce Worker 读取了所有中间数据后，它会按中间键对其进行排序，以便将所有相同键的出现组合在一起。排序是必需的，因为通常许多不同的键映射到同一个 Reduce 任务。如果中间数据量太大无法放入内存，则使用外部排序。
6.  Reduce Worker 迭代排序后的中间数据，并且对于遇到的每个唯一中间键，它将键和相应的中间值集传递给用户的 Reduce 函数。Reduce 函数的输出被追加到该 Reduce 分区的最终输出文件中。
7.  当所有 Map 任务和 Reduce 任务完成后，Master 唤醒用户程序。此时，用户程序中的 MapReduce 调用返回到用户代码。

成功完成后，MapReduce 执行的输出可在 $R$ 个输出文件中获得（每个 Reduce 任务一个，文件名由用户指定）。通常，用户不需要将这 $R$ 个输出文件合并为一个文件——他们经常将这些文件作为输入传递给另一个 MapReduce 调用，或者从另一个能够处理划分为多个文件的输入的分布式应用程序中使用它们。

### 3.2 Master 数据结构 (Master Data Structures)

Master 维护几个数据结构。对于每个 Map 任务和 Reduce 任务，它存储状态（空闲、进行中或已完成）以及 Worker 机器的标识（对于非空闲任务）。

Master 是中间文件区域位置信息从 Map 任务传播到 Reduce 任务的管道。因此，对于每个已完成的 Map 任务，Master 存储该 Map 任务产生的 $R$ 个中间文件区域的位置和大小。当 Map 任务完成时，会接收到对此位置和大小信息的更新。这些信息被增量推送到具有正在进行的 Reduce 任务的 Worker。

### 3.3 容错 (Fault Tolerance)

由于 MapReduce 库旨在帮助使用成百上千台机器处理海量数据，因此该库必须能够优雅地容忍机器故障。

**Worker 故障 (Worker Failure)**

Master 定期 Ping 每个 Worker。如果在一定时间内没有收到 Worker 的响应，Master 将该 Worker 标记为已失败。该 Worker 完成的任何 Map 任务都会重置回其初始空闲状态，因此有资格在其他 Worker 上重新调度。同样，在失败的 Worker 上正在进行的任何 Map 任务或 Reduce 任务也会重置为空闲状态，并有资格重新调度。

已完成的 Map 任务在失败时需要重新执行，因为它们的输出存储在失败机器的本地磁盘上，因此无法访问。已完成的 Reduce 任务不需要重新执行，因为它们的输出存储在全局文件系统中。

当一个 Map 任务首先由 Worker A 执行，后来又由 Worker B 执行（因为 A 失败）时，所有执行 Reduce 任务的 Worker 都会收到重新执行的通知。任何尚未从 Worker A 读取数据的 Reduce 任务将从 Worker B 读取数据。

MapReduce 对大规模 Worker 故障具有弹性。例如，在一次 MapReduce 操作期间，正在运行的集群上的网络维护导致每组 80 台机器在几分钟内无法访问。MapReduce Master 只是重新执行了不可达 Worker 机器所做的工作，并继续取得进展，最终完成了 MapReduce 操作。

**Master 故障 (Master Failure)**

让 Master 写入上述 Master 数据结构的定期检查点（Checkpoints）很容易。如果 Master 任务死亡，可以从最后的检查点状态启动一个新的副本。然而，鉴于只有一个 Master，其发生故障的可能性不大；因此我们当前的实现如果 Master 失败则中止 MapReduce 计算。客户可以检查此情况并在需要时重试 MapReduce 操作。

**故障存在时的语义 (Semantics in the Presence of Failures)**

当用户提供的 Map 和 Reduce 算子是其输入值的确定性函数时，我们的分布式实现产生的输出与整个程序的无故障顺序执行产生的输出相同。

我们依靠 Map 和 Reduce 任务输出的原子提交（atomic commits）来实现这一属性。每个正在进行的任务将其输出写入私有临时文件。一个 Reduce 任务产生一个这样的文件，一个 Map 任务产生 $R$ 个这样的文件（每个 Reduce 任务一个）。当 Map 任务完成时，Worker 向 Master 发送一条消息，并在消息中包含 $R$ 个临时文件的名称。如果 Master 收到已完成 Map 任务的完成消息，它将忽略该消息。否则，它会在 Master 数据结构中记录 $R$ 个文件的名称。

当 Reduce 任务完成时，Reduce Worker 以原子方式将其临时输出文件重命名为最终输出文件。如果同一个 Reduce 任务在多台机器上执行，则将针对同一个最终输出文件执行多个重命名调用。我们依靠底层文件系统提供的原子重命名操作来保证最终文件系统状态仅包含一次 Reduce 任务执行所产生的数据。

我们绝大多数的 Map 和 Reduce 算子都是确定性的，在这种情况下，我们的语义等同于顺序执行的事实使得程序员很容易推断其程序的行为。当 Map 和/或 Reduce 算子是不确定的时候，我们提供较弱但仍然合理的语义。在存在不确定算子的情况下，特定 Reduce 任务 $R_{1}$ 的输出等同于不确定程序的顺序执行所产生的 $R_{1}$ 的输出。然而，不同 Reduce 任务 $R_{2}$ 的输出可能对应于该不确定程序的不同顺序执行所产生的 $R_{2}$ 的输出。

### 3.4 局部性 (Locality)

在我们的计算环境中，网络带宽是一种相对稀缺的资源。我们通过利用输入数据（由 GFS 管理）存储在组成集群的机器的本地磁盘上这一事实来节省网络带宽。GFS 将每个文件划分为 64 MB 的块，并在不同的机器上存储每个块的多个副本（通常是 3 个副本）。MapReduce Master 考虑输入文件的位置信息，并尝试在包含相应输入数据副本的机器上调度 Map 任务。如果做不到这一点，它会尝试在任务输入数据的副本附近（例如，在与包含数据的机器处于同一网络交换机的 Worker 机器上）调度 Map 任务。当在集群的大部分 Worker 上运行大型 MapReduce 操作时，大多数输入数据是在本地读取的，不消耗网络带宽。

### 3.5 任务粒度 (Task Granularity)

如上所述，我们将 Map 阶段细分为 $M$ 个片段，将 Reduce 阶段细分为 $R$ 个片段。理想情况下，$M$ 和 $R$ 应该远大于 Worker 机器的数量。让每个 Worker 执行许多不同的任务可以改善动态负载均衡，并且在 Worker 失败时也能加速恢复：它已完成的许多 Map 任务可以分布在所有其他 Worker 机器上。

在我们的实现中，$M$ 和 $R$ 的大小有实际限制，因为 Master 必须做出 $O(M+R)$ 次调度决策，并在内存中保留 $O(M*R)$ 的状态。（然而，内存使用的常数因子很小：状态的 $O(M*R)$ 部分包含每个 Map 任务/Reduce 任务对大约一个字节的数据。）

此外，$R$ 通常受到用户的限制，因为每个 Reduce 任务的输出最终都在一个单独的输出文件中。实际上，我们倾向于选择 $M$，使得每个单独的任务大约是 16 MB 到 64 MB 的输入数据（这样上述的局部性优化最有效），并且我们将 $R$ 设定为我们需要使用的 Worker 机器数量的小倍数。我们经常使用 $M=200,000$ 和 $R=5,000$ 执行 MapReduce 计算，使用 2,000 台 Worker 机器。

### 3.6 备份任务 (Backup Tasks)

延长 MapReduce 操作总时间的一个常见原因是“落后者（Straggler）”：一台机器花费异常长的时间来完成计算中最后几个 Map 或 Reduce 任务之一。落后者出现的原因有很多。例如，具有坏磁盘的机器可能会遇到频繁的可纠正错误，将其读取性能从 30 MB/s 降低到 1 MB/s。集群调度系统可能在该机器上调度了其他任务，由于竞争 CPU、内存、本地磁盘或网络带宽，导致 MapReduce 代码执行缓慢。

我们有一种通用机制来减轻落后者的问题。当 MapReduce 操作接近完成时，Master 会调度剩余正在进行的任务的备份执行（backup executions）。无论是主执行还是备份执行完成，该任务都被标记为完成。我们调整了这种机制，使其通常只会使操作使用的计算资源增加几个百分点。我们发现这显着减少了完成大型 MapReduce 操作的时间。例如，当禁用备份任务机制时，5.3 节中描述的排序程序完成时间增加了 44%。

-----

## 4\. 改进 (Refinements)

虽然简单地编写 Map 和 Reduce 函数提供的基本功能足以满足大多数需求，但我们发现一些扩展很有用。本节将描述这些扩展。

### 4.1 分区函数 (Partitioning Function)

MapReduce 的用户指定他们想要的 Reduce 任务/输出文件的数量 ($R$)。数据使用中间键上的分区函数在这些任务之间进行分区。提供了一个默认的分区函数，使用哈希（例如 `hash(key) mod R`）。这往往会导致相当均衡的分区。然而，在某些情况下，通过键的其他函数对数据进行分区是有用的。例如，有时输出键是 URL，我们希望来自单个主机的所有条目最终都在同一个输出文件中。为了支持这种情况，MapReduce 库的用户可以提供特殊的分区函数。例如，使用 `hash(Hostname(urlkey)) mod R` 作为分区函数会导致来自同一主机的所有 URL 最终都在同一个输出文件中。

### 4.2 排序保证 (Ordering Guarantees)

我们保证在给定的分区内，中间键/值对按键的递增顺序处理。这种排序保证使得每个分区生成一个排序的输出文件变得容易，这在输出文件格式需要支持按键的高效随机访问查找，或者输出用户发现数据排序很方便时非常有用。

### 4.3 Combiner 函数 (Combiner Function)

在某些情况下，每个 Map 任务产生的中间键存在显着的重复，并且用户指定的 Reduce 函数是可交换和可结合的。第 2.1 节中的单词计数示例就是一个很好的例子。由于单词频率倾向于遵循 Zipf 分布，每个 Map 任务将产生数百或数千个形式为 `<the, 1>` 的记录。所有这些计数都将通过网络发送到单个 Reduce 任务，然后由 Reduce 函数相加产生一个数字。我们允许用户指定一个可选的 **Combiner（组合器）** 函数，在通过网络发送数据之前对这些数据进行部分合并。

Combiner 函数在执行 Map 任务的每台机器上执行。通常，实现 Combiner 和 Reduce 函数使用相同的代码。Reduce 函数和 Combiner 函数之间的唯一区别是 MapReduce 库处理函数输出的方式。Reduce 函数的输出被写入最终输出文件。Combiner 函数的输出被写入中间文件，该文件将被发送到 Reduce 任务。

部分合并显着加速了某些类别的 MapReduce 操作。附录 A 包含一个使用 Combiner 的示例。

### 4.4 输入和输出类型 (Input and Output Types)

MapReduce 库支持以几种不同的格式读取输入数据。例如，“文本”模式输入将每一行视为一个键/值对：键是文件中的偏移量，值是行的内容。另一种常见的支持格式存储按键排序的键/值对序列。每个输入类型实现都知道如何将自己拆分为有意义的范围以作为单独的 Map 任务进行处理（例如，文本模式的范围拆分确保范围拆分仅发生在行边界处）。用户可以通过提供简单的读取器接口实现来添加对新输入类型的支持。

以类似的方式，我们支持一组输出类型，用于生成不同格式的数据，并且用户代码很容易添加对新输出类型的支持。

### 4.5 副作用 (Side-effects)

在某些情况下，MapReduce 的用户发现从他们的 Map 和/或 Reduce 算子生成辅助文件作为附加输出很方便。我们依靠应用程序编写者使这些副作用具有原子性和幂等性。通常，应用程序写入一个临时文件，并在完全生成后原子地重命名该文件。

我们不提供对单个任务生成的多个输出文件的原子两阶段提交的支持。因此，产生具有跨文件一致性要求的多个输出文件的任务应该是确定性的。这种限制在实践中从未成为问题。

### 4.6 跳过坏记录 (Skipping Bad Records)

有时用户代码中存在错误，导致 Map 或 Reduce 函数在某些记录上确定性地崩溃。此类错误会阻止 MapReduce 操作完成。通常的做法是修复错误，但有时这不可行；也许错误在于源代码不可用的第三方库中。此外，有时忽略一些记录是可以接受的，例如在对大数据集进行统计分析时。我们提供一种可选的执行模式，MapReduce 库会检测哪些记录导致确定性崩溃，并跳过这些记录以继续进行。

每个 Worker 进程都安装了一个信号处理程序，用于捕获分段违规（segmentation violations）和总线错误。在调用用户 Map 或 Reduce 操作之前，MapReduce 库将参数的序列号存储在全局变量中。如果用户代码生成信号，信号处理程序将向 MapReduce Master 发送包含序列号的“最后一口气” UDP 数据包。当 Master 在特定记录上看到不止一次失败时，它会在发出相应 Map 或 Reduce 任务的下一次重新执行时指示应跳过该记录。

### 4.7 本地执行 (Local Execution)

调试 Map 或 Reduce 函数中的问题可能很棘手，因为实际计算发生在分布式系统中，通常在数千台机器上，并且工作分配决策由 Master 动态做出。为了便于调试、分析和小规模测试，我们要开发了 MapReduce 库的替代实现，该实现在本地机器上顺序执行 MapReduce 操作的所有工作。向用户提供了控件，以便可以将计算限制为特定的 Map 任务。用户使用特殊标志调用他们的程序，然后可以轻松使用他们认为有用的任何调试或测试工具（例如 gdb）。

### 4.8 状态信息 (Status Information)

Master 运行一个内部 HTTP 服务器并导出一组状态页面供人查阅。状态页面显示计算的进度，例如已完成多少任务、正在进行多少任务、输入字节数、中间数据字节数、输出字节数、处理速率等。页面还包含指向每个任务生成的标准错误和标准输出文件的链接。用户可以使用这些数据来预测计算将花费多长时间，以及是否应该向计算添加更多资源。这些页面也可用于弄清楚计算何时比预期慢得多。此外，顶级状态页面显示哪些 Worker 失败了，以及它们失败时正在处理哪些 Map 和 Reduce 任务。在尝试诊断用户代码中的错误时，此信息很有用。

### 4.9 计数器 (Counters)

MapReduce 库提供了一个计数器工具来统计各种事件的发生次数。例如，用户代码可能想要统计处理的单词总数或索引的德语文档数量等。

为了使用此工具，用户代码创建一个命名的计数器对象，然后在 Map 和/或 Reduce 函数中适当地增加计数器。例如：

```c++
Counter* uppercase;
uppercase = GetCounter("uppercase");

map(String name, String contents):
    for each word w in contents:
        if (IsCapitalized(w)):
            uppercase->Increment();
        EmitIntermediate(w, "1");
```

来自各个 Worker 机器的计数器值定期传播到 Master（搭载在 Ping 响应上）。Master 聚合来自成功的 Map 和 Reduce 任务的计数器值，并在 MapReduce 操作完成时将它们返回给用户代码。当前的计数器值也显示在 Master 状态页面上，以便人类可以观察实时计算的进度。在聚合计数器值时，Master 消除同一 Map 或 Reduce 任务的重复执行的影响，以避免重复计数。（重复执行可能源于我们要使用的备份任务和由于故障导致的任务重新执行。）

MapReduce 库自动维护一些计数器值，例如处理的输入键/值对的数量和产生的输出键/值对的数量。

用户发现计数器工具对于检查 MapReduce 操作行为的健全性很有用。例如，在某些 MapReduce 操作中，用户代码可能希望确保产生的输出对的数量完全等于处理的输入对的数量，或者处理的德语文档的比例在处理的文档总数的某个可容忍比例范围内。

-----

## 5\. 性能 (Performance)

在本节中，我们测量 MapReduce 在大型机器集群上运行两个计算时的性能。一个计算在大约 1 TB 的数据中搜索特定模式。另一个计算对大约 1 TB 的数据进行排序。这两个程序代表了 MapReduce 用户编写的大部分实际程序——一类程序将数据从一种表示形式混洗（shuffle）到另一种表示形式，另一类程序从大数据集中提取少量有趣的数据。

### 5.1 集群配置 (Cluster Configuration)

所有程序都在由大约 1800 台机器组成的集群上执行。每台机器都有两个启用超线程的 2GHz Intel Xeon 处理器、4GB 内存、两个 160GB IDE 磁盘和一个千兆以太网链路。机器被安排在一个两级树形交换网络中，根部具有大约 100-200 Gbps 的聚合带宽。所有机器都在同一个托管设施中，因此任何一对机器之间的往返时间小于 1 毫秒。
![](/images/Figure-2.png)

在 4GB 内存中，大约 1-1.5GB 被运行在集群上的其他任务预留。程序是在周末下午执行的，当时 CPU、磁盘和网络大多处于空闲状态。

### 5.2 Grep

Grep 程序扫描 $10^{10}$ 个 100 字节的记录，搜索一个相对罕见的三个字符的模式（该模式出现在 92,337 个记录中）。输入被拆分为大约 64MB 的片段 ($M=15000$)，整个输出放在一个文件中 ($R=1$)。

*图 2：随时间变化的数据传输率*

图 2 显示了计算随时间推移的进度。Y 轴显示扫描输入数据的速率。随着更多机器被分配给此 MapReduce 计算，速率逐渐上升，并在分配了 1764 个 Worker 时达到超过 30 GB/s 的峰值。随着 Map 任务完成，速率开始下降，并在计算开始大约 80 秒后降为零。整个计算从开始到结束大约需要 150 秒。这包括大约一分钟的启动开销。开销是由于程序传播到所有 Worker 机器，以及与 GFS 交互以打开 1000 个输入文件集并获取局部性优化所需信息造成的延迟。

### 5.3 排序 (Sort)

排序程序对 $10^{10}$ 个 100 字节的记录（大约 1 TB 数据）进行排序。该程序模仿 TeraSort 基准测试。



排序程序包含不到 50 行的用户代码。三行的 Map 函数从文本行中提取 10 字节的排序键，并发出键和原始文本行作为中间键/值对。我们使用内置的 Identity 函数作为 Reduce 算子。此函数将中间键/值对原样作为输出键/值对传递。最终排序后的输出被写入一组 2 路复制的 GFS 文件（即，作为程序输出写入 2 TB）。
![](/images/Figure-3.png)

如前所述，输入数据被拆分为 64MB 的片段 ($M=15000$)。我们将排序后的输出划分为 4000 个文件 ($R=4000$)。分区函数使用键的初始字节将其隔离到 $R$ 个片段之一中。我们针对此基准测试的分区函数内置了键分布的知识。在通用的排序程序中，我们会添加一个预处理 MapReduce 操作，该操作将收集键的样本，并使用采样键的分布来计算最终排序过程的拆分点。

*图 3：排序程序不同执行过程中的数据传输率*

图 3 (a) 显示了排序程序正常执行的进度。左上图显示了读取输入的速率。速率峰值约为 13 GB/s，并且由于所有 Map 任务在 200 秒过去之前完成而迅速消退。注意输入速率低于 grep。这是因为排序 Map 任务花费大约一半的时间和 I/O 带宽将中间输出写入其本地磁盘。grep 的相应中间输出大小可以忽略不计。

左中图显示了数据从 Map 任务通过网络发送到 Reduce 任务的速率。这种混洗（shuffling）在第一个 Map 任务完成后立即开始。图中的第一个驼峰是针对第一批大约 1700 个 Reduce 任务的（整个 MapReduce 被分配了大约 1700 台机器，每台机器一次最多执行一个 Reduce 任务）。计算进行大约 300 秒后，第一批 Reduce 任务中的一些完成了，我们开始为剩余的 Reduce 任务混洗数据。所有的混洗在计算进行大约 600 秒后完成。

左下图显示了 Reduce 任务将排序后的数据写入最终输出文件的速率。在第一次混洗周期结束和写入周期开始之间存在延迟，因为机器正忙于对中间数据进行排序。写入持续了一段时间，速率约为 2-4 GB/s。所有写入在计算进行大约 850 秒后完成。包括启动开销在内，整个计算耗时 891 秒。这与 TeraSort 基准测试目前报告的最佳结果 1057 秒相似。

需要注意几点：输入速率高于混洗速率和输出速率，这是因为我们的局部性优化——大多数数据是从本地磁盘读取的，绕过了我们相对带宽受限的网络。混洗速率高于输出速率，因为输出阶段写入排序数据的两个副本（出于可靠性和可用性原因，我们要制作输出的两个副本）。如果是底层文件系统使用纠删码（erasure coding）而不是复制，则写入数据的网络带宽需求将减少。

### 5.4 备份任务的影响 (Effect of Backup Tasks)

在图 3 (b) 中，我们显示了禁用备份任务的排序程序的执行情况。执行流程与图 3 (a) 所示类似，只是有一个很长的尾部，几乎没有发生任何写入活动。960 秒后，除 5 个 Reduce 任务外，所有任务都完成了。然而，这最后几个落后者直到 300 秒后才完成。整个计算耗时 1283 秒，耗时增加了 44%。

### 5.5 机器故障 (Machine Failures)

在图 3 (c) 中，我们显示了排序程序的执行情况，其中我们在计算几分钟后故意杀死了 1746 个 Worker 进程中的 200 个。底层集群调度程序立即在这些机器上重新启动了新的 Worker 进程（因为只是进程被杀死，机器仍然正常运行）。

Worker 的死亡显示为负输入速率，因为一些先前完成的 Map 工作消失了（因为相应的 Map Worker 被杀死）并且需要重做。此 Map 工作的重新执行发生得相对较快。整个计算在 933 秒内完成，包括启动开销（仅比正常执行时间增加 5%）。

-----

## 6\. 经验 (Experience)

我们在 2003 年 2 月编写了 MapReduce 库的第一个版本，并在 2003 年 8 月对其进行了重大增强，包括局部性优化、跨 Worker 机器的任务执行动态负载均衡等。自那时起，我们惊喜地发现 MapReduce 库对我们处理的问题类型的适用性非常广泛。它已在 Google 内部广泛用于各种领域，包括：

  * 大规模机器学习问题；
  * Google News 和 Froogle 产品的聚类问题；
  * 提取用于生成热门查询报告的数据（例如 Google Zeitgeist）；
  * 为新实验和产品提取网页属性（例如，从大量网页语料库中提取地理位置以进行本地化搜索）；以及
  * 大规模图计算。

*图 4：随时间变化的 MapReduce 实例数*

**表 1：2004 年 8 月运行的 MapReduce 作业**

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
![](/images/Table-1.png)

图 4 显示了随着时间的推移，检入我们要主源代码管理系统的独立 MapReduce 程序的数量显着增长，从 2003 年初的 0 增长到 2004 年 9 月下旬的近 900 个独立实例。MapReduce 如此成功是因为它使得编写一个简单的程序并在半小时内在数千台机器上高效运行成为可能，极大地加快了开发和原型设计周期。此外，它允许没有分布式和/或并行系统经验的程序员轻松利用大量资源。

在每个作业结束时，MapReduce 库会记录有关该作业使用的计算资源的统计信息。在表 1 中，我们显示了 2004 年 8 月在 Google 运行的 MapReduce 作业子集的一些统计信息。

### 6.1 大规模索引 (Large-Scale Indexing)

迄今为止，我们对 MapReduce 最重要的用途之一是完全重写了生产索引系统，该系统生成用于 Google Web 搜索服务的数据结构。索引系统将爬虫系统检索到的、存储为一组 GFS 文件的大量文档作为输入。这些文档的原始内容超过 20 TB。索引过程作为 5 到 10 个 MapReduce 操作的序列运行。使用 MapReduce（而不是索引系统先前版本中的临时分布式传递）提供了几个好处：

  * 索引代码更简单、更小、更容易理解，因为处理容错、分发和并行化的代码隐藏在 MapReduce 库中。例如，当使用 MapReduce 表达时，计算的一个阶段的大小从大约 3800 行 C++ 代码下降到大约 700 行。
  * MapReduce 库的性能足够好，以至于我们可以将概念上不相关的计算分开，而不是为了避免额外的数据传递而将它们混合在一起。这使得更改索引过程变得容易。例如，在我们的旧索引系统中需要几个月才能完成的一项更改，在新系统中只需几天即可实现。
  * 索引过程变得更容易操作，因为由机器故障、慢速机器和网络中断引起的大多数问题都由 MapReduce 库自动处理，无需操作员干预。此外，通过向索引集群添加新机器，很容易提高索引过程的性能。

-----

## 7\. 相关工作 (Related Work)

许多系统提供了受限的编程模型，并利用这些限制来自动并行化计算。例如，可以使用并行前缀计算在 $N$ 个处理器上以 $\log N$ 的时间计算 $N$ 元素数组的所有前缀的关联函数。MapReduce 可以被视为基于我们对大型现实世界计算的经验，对其中一些模型的简化和提炼。更重要的是，我们提供了一个可扩展到数千个处理器的容错实现。相比之下，大多数并行处理系统仅在较小的规模上实现，并将处理机器故障的细节留给程序员。

Bulk Synchronous Programming 和一些 MPI 原语提供了更高级别的抽象，使程序员更容易编写并行程序。这些系统与 MapReduce 的一个关键区别在于，MapReduce 利用受限的编程模型来自动并行化用户程序并提供透明的容错功能。

我们的局部性优化灵感来自诸如 active disks 等技术，这些技术将计算推送到靠近本地磁盘的处理元件中，以减少通过 I/O 子系统或网络发送的数据量。我们在直接连接少量磁盘的普通商用处理器上运行，而不是直接在磁盘控制器处理器上运行，但一般方法是相似的。

我们的备份任务机制类似于 Charlotte 系统中使用的 eager scheduling 机制。简单的 eager scheduling 的缺点之一是，如果给定的任务导致重复失败，则整个计算无法完成。我们通过跳过坏记录的机制修复了此问题的一些实例。

MapReduce 实现依赖于内部集群管理系统，该系统负责在大量共享机器上分发和运行用户任务。虽然不是本文的重点，但集群管理系统在精神上类似于 Condor 等其他系统。

MapReduce 库中的排序工具在操作上类似于 NOW-Sort。源机器（Map Worker）将被排序的数据分区并将其发送到 $R$ 个 Reduce Worker 中的一个。每个 Reduce Worker 在本地对其数据进行排序（如果可能的话在内存中）。当然，NOW-Sort 没有使用户库广泛适用的用户可定义的 Map 和 Reduce 函数。

River 提供了一种编程模型，其中进程通过分布式队列发送数据来相互通信。与 MapReduce 一样，River 系统试图即使在异构硬件或系统扰动引入非均匀性的情况下也能提供良好的平均情况性能。River 通过仔细调度磁盘和网络传输来实现平衡的完成时间。MapReduce 采用了不同的方法。通过限制编程模型，MapReduce 框架能够将问题划分为大量细粒度的任务。这些任务在可用的 Worker 上动态调度，以便更快的 Worker 处理更多任务。受限的编程模型还允许我们在作业接近尾声时调度任务的冗余执行，这极大地减少了在存在非均匀性（如慢速或卡住的 Worker）的情况下的完成时间。

BAD-FS 具有与 MapReduce 非常不同的编程模型，并且与 MapReduce 不同，它针对的是跨广域网的作业执行。然而，有两个基本的相似之处。(1) 两个系统都使用冗余执行来从故障引起的数据丢失中恢复。(2) 两者都使用感知局部性的调度来减少通过拥塞网络链路发送的数据量。

TACC 是一个旨在简化高可用性网络服务构建的系统。与 MapReduce 一样，它依赖于重新执行作为实现容错的机制。

-----

## 8\. 结论 (Conclusions)

MapReduce 编程模型已在 Google 成功用于许多不同的目的。我们将此成功归因于几个原因。首先，该模型易于使用，即使对于没有并行和分布式系统经验的程序员也是如此，因为它隐藏了并行化、容错、局部性优化和负载均衡的细节。其次，各种各样的问题都可以轻松地表达为 MapReduce 计算。例如，MapReduce 用于为 Google 的生产网络搜索服务生成数据、用于排序、用于数据挖掘、用于机器学习以及许多其他系统。第三，我们开发了一个 MapReduce 实现，可以扩展到包含数千台机器的大型机器集群。该实现有效地利用了这些机器资源，因此适用于 Google 遇到的许多大型计算问题。

我们从这项工作中学到了几件事。首先，限制编程模型使得并行化和分发计算以及使此类计算具有容错性变得容易。其次，网络带宽是一种稀缺资源。因此，我们系统中的许多优化都针对减少通过网络发送的数据量：局部性优化允许我们要从本地磁盘读取数据，将中间数据的单个副本写入本地磁盘可以节省网络带宽。第三，冗余执行可用于减少慢速机器的影响，并处理机器故障和数据丢失。

-----

## 附录 A：单词频率 (Word Frequency)

本节包含一个程序，用于统计在命令行指定的输入文件集中每个唯一单词的出现次数。

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