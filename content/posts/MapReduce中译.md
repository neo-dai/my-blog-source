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
Consider the problem of counting the number of oc- currences of each word in a large collection of docu- ments. The user would write code similar to the follow- ing pseudo-code:

>考虑在海量文档集合中统计每个单词出现次数的问题。用户会编写类似如下的伪代码：

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

The mapfunction emits each word plus an associated count of occurrences (just ‘1’ in this simple example).  The reducefunction sums together all counts emitted for a particular word.

>Map函数会输出每个单词以及对应的出现次数（在此简单示例中固定为“1”），Reduce函数则把针对同一单词输出的所有计数相加。

In addition, the user writes code to fill in a mapreduce specification object with the names of the input and out-put files, and optional tuning parameters. The user then invokes the MapReduce function, passing it the specifi-cation object. The user’s code is linked together with the MapReduce library (implemented in C++). Appendix A contains the full program text for this example.

>此外，用户还需编写代码来填充一个MapReduce规范对象，指定输入输出文件名及可选的调优参数。随后调用MapReduce函数并传入该规范对象。用户代码会与用C++实现的MapReduce库链接，附录A给出了该示例的完整程序。

### 2.2 类型 (Types)

Even though the previous pseudo-code is written in terms of string inputs and outputs, conceptually the map and reduce functions supplied by the user have associated
types:

>尽管上述伪代码以字符串作为输入输出，但从概念上讲，用户提供的Map和Reduce函数各自都具有明确的类型：

```text
map     (k1, v1)       ->  list(k2, v2)
reduce  (k2, list(v2)) ->  list(v2)
```
I.e., the input keys and values are drawn from a different domain than the output keys and values. Furthermore, the intermediate keys and values are from the same do-main as the output keys and values.

>也就是说，输入的键和值所属的域与输出的键和值不同；同时，中间结果中的键和值与输出端处在同一域。

Our C++ implementation passes strings to and from the user-defined functions and leaves it to the user code to convert between strings and appropriate types.

>我们的C++实现会向用户自定义函数传入字符串并接收其返回字符串，至于如何在字符串与具体类型之间转换则留给用户代码自行处理。

### 2.3 更多示例 (More Examples)

Here are a few simple examples of interesting programs that can be easily expressed as MapReduce computa-tions.

>下面列出几类有趣的程序，它们都能轻松用MapReduce范式来表达：

**Distributed Grep:** The map function emits a line if it matches a supplied pattern. The reduce function is an identity function that just copies the supplied intermedi-ate data to the output.

>**分布式 Grep (Distributed Grep)：** map函数在文本行匹配指定模式时输出该行，reduce函数作为恒等函数仅将收到的中间数据原样写出。

**Count of URL Access Frequency:** The map func-tion processes logs of web page requests and outputs ⟨URL, 1⟩. The reduce function adds together all values for the same URL and emits a ⟨URL, total count⟩ pair.

>**URL访问频率统计(Count of URL Access Frequency)：** map函数读取网页访问日志并输出⟨URL,1⟩；reduce函数对同一URL的所有值求和并给出⟨URL,访问总数⟩。

Reverse Web-Link Graph: The map function outputs ⟨target, source⟩ pairs for each link to a target URL found in a page named source. The reduce function concatenates the list of all source URLs as-sociated with a given target URL and emits the pair: ⟨target, list(source)⟩

>**反向Web链接图(Reverse Web-Link Graph)：** map函数在名为source的页面中发现指向target的每个链接时输出⟨target,source⟩；reduce函数将指向同一target的所有source URL拼接成列表，最终产出⟨target,list(source)⟩。

Term-Vector per Host: A term vector summarizes the most important words that occur in a document or a set of documents as a list of ⟨word, frequency⟩ pairs. The map function emits a ⟨hostname, term vector⟩ pair for each input document (where the hostname is extracted from the URL of the document). The re-duce function is passed all per-document term vectors for a given host. It adds these term vectors together, throwing away infrequent terms, and then emits a final ⟨hostname, term vector⟩ pair.

>**每个主机的term vector(Term-Vector per Host)：** term vector以⟨word,frequency⟩列表总结文档或文档集合中最重要的词。map函数为每个输入文档输出⟨hostname,term vector⟩，其中hostname取自文档URL；reduce函数汇总该主机下所有文档的term vector，丢弃低频词后给出最终的⟨hostname,term vector⟩。

![](/images/Figure-1.png)

Inverted Index: The map function parses each docu-ment, and emits a sequence of ⟨word, document ID⟩ pairs. The reduce function accepts all pairs for a given word, sorts the corresponding document IDs and emits a ⟨word, list(document ID)⟩ pair. The set of all output pairs forms a simple inverted index. It is easy to augment this computation to keep track of word positions.

>**倒排索引 (Inverted Index)：** map函数解析每个文档并输出一系列`⟨word,document ID⟩`；reduce函数接收同一单词的所有pair，按document ID排序后产出`⟨word,list(document ID)⟩`。汇总所有输出即可得到一个基础倒排索引，如需记录词位信息也能轻松扩展。

Distributed Sort: The map function extracts the key from each record, and emits a ⟨key, record⟩ pair. The reduce function emits all pairs unchanged. This compu-tation depends on the partitioning facilities described in Section 4.1 and the ordering properties described in Sec- tion 4.2.

>**分布式排序 (Distributed Sort)：** map函数从每条记录提取key并输出`⟨key,record⟩`，`reduce`函数原样输出所有pair。该计算依赖4.1节描述的分区机制和4.2节讲述的排序特性。

-----

## 3\. 实现 (Implementation)

Many different implementations of the MapReduce in-terface are possible. The right choice depends on the environment. For example, one implementation may be suitable for a small shared-memory machine, another for a large **NUMA** multi-processor, and yet another for an even larger collection of networked machines.

>MapReduce接口有多种实现方式，具体选型取决于运行环境：小型共享内存机器需要一种实现，大型**NUMA**多处理器适合另一种，而规模更大的网络化集群则需要再不同的方案。

This section describes an implementation targeted to the computing environment in wide use at Google: large clusters of commodity PCs connected together with switched Ethernet [4]. In our environment:

>本节介绍的实现面向Google广泛使用的计算环境：由以太网交换机互连的大规模商用PC集群[4]。在这一环境中：

(1) Machines are typically dual-processor x86 processors running Linux, with 2-4 GB of memory per machine.

>(1)集群中的机器通常是运行Linux的双处理器x86主机，每台具备2–4GB内存。

(2) Commodity networking hardware is used – typically either 100 megabits/second or 1 gigabit/second at the machine level, but averaging considerably less in over-all bisection bandwidth.

>(2) 使用的是商品化网络硬件——通常在单机层面是100Mb/s或1Gb/s，但整体二分带宽（bisection bandwidth）平均远低于此值。

(3) A cluster consists of hundreds or thousands of ma-chines, and therefore machine failures are common.

>(3) 一个集群由数百台甚至数千台机器组成，因此**机器故障是常态**（非常常见）。

(4) Storage is provided by inexpensive IDE disks at-tached directly to individual machines. A distributed file system [8] developed in-house is used to manage the data stored on these disks. The file system uses replication to provide availability and reliability on top of unreliable hardware.

>(4) 存储由直接连接到各个机器的廉价 IDE 磁盘提供。系统使用内部开发的一种分布式文件系统(GFS)[8]来管理这些磁盘上的数据。该文件系统通过**数据多副本复制（replication）**的方式，在不可靠的硬件之上提供高可用性和可靠性。

(5) Users submit jobs to a scheduling system. Each job consists of a set of tasks, and is mapped by the scheduler to a set of available machines within a cluster.

>(5) 用户将作业（jobs）提交给调度系统。每个作业由一组任务（tasks）组成，调度器会将这些任务映射到集群内的一组可用机器上执行。

### 3.1 执行概览 (Execution Overview)

The Map invocations are distributed across multiple machines by automatically partitioning the input data into a set of $M splits$. The input splits can be pro-cessed in parallel by different machines. $Reduce$ invoca-tions are distributed by partitioning the intermediate key space into $R$ pieces using a partitioning function (e.g., $hash(key)$ mod $R$). The number of partitions ($R$) and the partitioning function are specified by the user.

>Map 调用通过将输入数据自动划分为 **M 个 split** 来实现在多台机器上的并行执行。这些输入 split 可以被不同的机器并行处理。 $Reduce$ 调用则通过使用分区函数（例如 $hash(key)$ mod $R$）将中间键（intermediate key）的键空间划分为 **R 份** 来实现分布。分区数量（$R$）以及具体的分区函数由用户指定。 （简单说：Map 的并行度由 M 决定，Reduce 的并行度由 R 决定，用户可以自行设置这两个值。）

>**【笔记】：** M：数据的分片 R:基于分片上的分组。

Figure 1 shows the overall flow of a **MapReduce** op-eration in our implementation. When the user program calls the $MapReduce$ function, the following sequence of actions occurs (the numbered labels in Figure 1 corre-spond to the numbers in the list below):

>图1展示了我们实现中的 MapReduce 操作的整体执行流程。当用户程序调用 MapReduce 函数时，会按以下顺序执行一系列动作（图1中的编号与下文列表的编号一一对应）：

1. The MapReduce library in the user program first splits the input files into M pieces of typically 16 megabytes to 64 megabytes (**MB**) per piece (con-trollable by the user via an optional parameter). It then starts up many copies of the program on a clus- ter of machines.

>1. 用户程序中的 MapReduce 库首先将输入文件划分为 **M** 片，通常每个片段 16 MB 到 64 MB（用户可通过可选参数控制）。随后，系统在机群上启动该程序的多个副本（即启动大量 worker 进程/实例）。

2. One of the copies of the program is special – the master. The rest are workers that are assigned work by the master. There are M map tasks and R reduce tasks to assign. The master picks idle workers and assigns each one a map task or a reduce task.

>2. 程序的众多副本中有一个是特殊的——**master**（主控节点）。其余的都是 **worker**（工作节点），由 master 负责给它们分配任务。总共有 **M 个 map 任务**和 **R 个 reduce 任务**需要分配。master 会挑选空闲的 worker，为每个空闲 worker 分配一个 map 任务或一个 reduce 任务。

3. A worker who is assigned a map task reads the contents of the corresponding input split. It parses key/value pairs out of the input data and passes each pair to the user-defined Map function. The interme-diate key/value pairs produced by the Map function are buffered in memory.

>3. 被分配到 map 任务的 worker 会读取对应输入分片（input split）的全部内容。它从输入数据中解析出键/值对（key/value pairs），然后将每一对键/值传递给用户自定义的 Map 函数。Map 函数产生的**中间键/值对**会被暂时缓冲在内存中。

4. Periodically, the buffered pairs are written to local disk, partitioned into R regions by the partitioning function. The locations of these buffered pairs on the local disk are passed back to the master, who is responsible for forwarding these locations to the reduce workers.

>4. 这些缓冲在内存中的中间键/值对会**定期**被写入本地磁盘，并通过分区函数（$partitioning$ function）划分为 **R 个区域**。这些缓冲数据在本地磁盘上的存储位置会被回传给 master，master 负责将这些位置信息转发给对应的 reduce worker。

5. When a reduce worker is notified by the master about these locations, it uses remote procedure calls to read the buffered data from the local disks of the map workers. When a reduce worker has read all in-termediate data, it sorts it by the intermediate keys so that all occurrences of the same key are grouped together. The sorting is needed because typically many different keys map to the same reduce task. If the amount of intermediate data is too large to fit in memory, an external sort is used.

>5. 当 reduce worker 收到 master 发来的位置通知后，它会通过远程过程调用（RPC）从各个 map worker 的本地磁盘读取这些缓冲的中间数据。reduce worker 读完所有中间数据后，会按照**中间键（intermediate key）**对其进行排序，使得相同 key 的所有记录都被归并到一起。排序是必须的，因为通常会有很多不同的 key 被哈希到同一个 reduce 任务中。如果中间数据量太大、无法完全放入内存，则会使用**外部排序（external sort）**。

6. The reduce worker iterates over the sorted interme-diate data and for each unique intermediate key en-countered, it passes the key and the corresponding set of intermediate values to the user’s Reduce func-tion. The output of the Reduce function is appended to a final output file for this reduce partition.

>6. reduce worker 会遍历已经排序好的中间数据，对于遇到的每一个**唯一的中间键（unique intermediate key）**，它会将该 key 以及对应的所有中间值（一组值）一起传递给用户自定义的 Reduce 函数。Reduce 函数的输出会被**追加**到一个属于该 reduce 分区的最终输出文件中。


7. When all map tasks and reduce tasks have been completed, the master wakes up the user program.  At this point, the MapReducecall in the user pro-gram returns back to the user code.

>7. 当所有的 map 任务和 reduce 任务都执行完毕后，master 会唤醒用户程序。此时，用户程序中的 MapReduce 调用返回，控制权重新交回给用户代码。

After successful completion, the output of the mapre-duce execution is available in the R output files (one per reduce task, with file names as specified by the user).  Typically, users do not need to combine these R output files into one file – they often pass these files as input to another MapReduce call, or use them from another dis- tributed application that is able to deal with input that is partitioned into multiple files.

>执行成功完成后，MapReduce 的输出结果存放在 **R 个输出文件**中（每个 reduce 任务对应生成一个文件，文件名由用户指定）。  通常，用户**不需要**手动将这 R 个输出文件合并成一个文件——他们往往直接将这 R 个文件作为下一个 MapReduce 作业的输入，或者交给另一个能够处理“多文件分区输入”的分布式应用程序使用。

### 3.2 Master 数据结构 (Master Data Structures)

The master keeps several data structures. For each map task and reduce task, it stores the state (idle, in-progress, or completed), and the identity of the worker machine (for non-idle tasks).

>master 会维护若干数据结构。对于每一个 map 任务和 reduce 任务，它都会记录以下信息：
>- **状态**（idle：空闲、in-progress：正在进行、completed：已完成）
>- **执行该任务的 worker 机器标识**（对于非空闲状态的任务）

The master is the conduit through which the location of intermediate file regions is propagated from map tasks to reduce tasks. Therefore, for each completed map task, the master stores the locations and sizes of the R inter-mediate file regions produced by the map task. Updates to this location and size information are received as map tasks are completed. The information is pushed incre-mentally to workers that have $in-progress$ reduce tasks.

>master 是中间文件区域位置信息从 map 任务传递到 reduce 任务的**唯一通道**。因此，对于每一个已经完成的 map 任务，master 都会存储该 map 任务产生的 **R 个中间文件区域**的位置（location）和大小（size）信息。
>这些位置和大小信息会随着 map 任务的完成**逐步更新**到 master 中。master 会**增量地**（incrementally）将这些信息推送给当前处于 **in-progress**（正在执行）状态的 reduce worker，以便它们及时拉取所需的数据。

### 3.3 容错 (Fault Tolerance)

Since the MapReduce library is designed to help process very large amounts of data using hundreds or thousands of machines, the library must tolerate machine failures gracefully.

>由于 MapReduce 库的设计目标是帮助使用**数百台甚至数千台**机器来处理**海量数据**，因此该库必须能够**优雅地容忍机器故障**（gracefully tolerate machine failures）。

**Worker 故障 (Worker Failure)**

The master pings every worker periodically. If no re-sponse is received from a worker in a certain amount of time, the master marks the worker as failed. Any map tasks completed by the worker are reset back to their ini-tial idle state, and therefore become eligible for schedul-ing on other workers. Similarly, any map task or reduce task in progress on a failed worker is also reset to idle and becomes eligible for rescheduling.

>master 会**定期**向每个 worker 发送 ping 检测。如果在一定时间内没有收到某个 worker 的响应，master 就会将该 worker 标记为**已失效（failed）**。
>- 该 worker 上已经**完成**的 map 任务会被重置回初始的 **idle** 状态，从而可以重新被调度到其他机器上执行。
>- 该 worker 上正在执行（in-progress）的 map 任务或 reduce 任务，也同样会被重置为 **idle** 状态，变得可以重新调度。
>
>（简单说：一旦机器挂了，它干过的和正在干的活儿全部作废，都重新排队等着别的机器来干。）

Completed map tasks are re-executed on a failure be-cause their output is stored on the local disk(s) of the failed machine and is therefore inaccessible. Completed reduce tasks do not need to be re-executed since their output is stored in a global file system.

>已完成的 **map 任务** 在机器失效后必须重新执行，因为它们的输出存储在失效机器的**本地磁盘**上，因此变得**不可访问**。  
>而已完成的 **reduce 任务** 则**不需要重新执行**，因为它们的输出存储在**全局文件系统**（如 GFS）中，仍然可以被正常访问。

When a map task is executed first by worker A and then later executed by worker B (because A failed), all workers executing reduce tasks are notified of the re- execution. Any reduce task that has not already read the data from worker A will read the data from worker B.

>当一个 map 任务先由 worker A 执行，随后因 A 失效而改由 worker B 重新执行时，master 会通知所有正在执行 reduce 任务的 worker 发生了**重新执行**。
>
>那些还没有从 worker A 读取过数据的 reduce worker，将会改为从 worker B 读取该 map 任务的输出数据。（已经从 A 读过的则不需要再读，以避免重复。）

MapReduce is resilient to large-scale worker failures.  For example, during one MapReduce operation, network maintenance on a running cluster was causing groups of 80 machines at a time to become unreachable for sev-eral minutes. The MapReduce master simply re-executed the work done by the unreachable worker machines, and continued to make forward progress, eventually complet-ing the MapReduce operation.

>MapReduce 对大规模 worker 失效具有很强的**容错能力**。  
>举例来说，在一次 MapReduce 操作执行过程中，集群正在进行网络维护，导致一次有 **80 台机器**成批地断连数分钟，变得不可访问。  
>MapReduce master 只是简单地将这些不可达机器上已经完成的工作重新执行一遍，系统就能继续向前推进，最终顺利完成整个 MapReduce 操作。

**Master 故障 (Master Failure)**

It is easy to make the master write periodic checkpoints of the master data structures described above. If the mas-ter task dies, a new copy can be started from the last checkpointed state. However, given that there is only a single master, its failure is unlikely; therefore our cur-rent implementation aborts the MapReduce computation if the master fails. Clients can check for this condition and retry the MapReduce operation if they desire.

>让 master 定期对其上述数据结构进行**检查点（checkpoint）**写入是非常容易实现的。如果 master 任务挂掉，就可以从最近一次的检查点状态启动一个新的 master 副本。
>不过，由于整个系统只有一个 master，**它的失效概率极低**；因此我们当前的实现采取了更简单的策略：**一旦 master 失效，就直接中止整个 MapReduce 计算**。客户端可以检测到这种情况，如果需要的话，可以自行重试整个 MapReduce 操作。


**故障存在时的语义 (Semantics in the Presence of Failures)**

When the user-supplied map and reduce operators are de-terministic functions of their input values, our distributed implementation produces the same output as would have been produced by a non-faulting sequential execution of the entire program.

>当用户提供的 **map** 和 **reduce** 函数对其输入是**确定性**的（即同样的输入总是产生完全相同的输出）时，我们的分布式实现所产生的最终结果，将与**在无故障的单机顺序执行**整个程序所得到的结果**完全一致**。

We rely on atomic commits of map and reduce task outputs to achieve this property. Each in-progress task writes its output to private temporary files. A reduce task produces one such file, and a map task produces R such files (one per reduce task). When a map task completes, the worker sends a message to the master and includes the names of the R temporary files in the message. If the master receives a completion message for an already completed map task, it ignores the message. Otherwise, it records the names of R files in a master data structure.

>为了实现这一特性，我们依赖 Map 和 Reduce 任务输出的原子提交 (Atomic Commits)。
>每个正在运行的任务都把自己的输出写入**私有的临时文件**。
> *一个 reduce 任务只产生一个这样的临时文件。
> *一个 map 任务会产生 R 个这样的临时文件（对应 R 个 reduce 任务，每个 reduce 一个）。
>当一个 map 任务完成时，worker 会向 master 发送一条完成消息，并在消息中附带这 R 个临时文件的文件名。
>如果 master 收到的是某个**已经标记为已完成**的 map 任务的完成消息，它会直接忽略这条消息（这是为了应对 worker 崩溃后重试导致的重复通知）。 否则，master 会在自己的主数据结构中记录下这 R 个文件的名字和位置。 （reduce 任务完成时同理，只是只有一个文件，也会原子性地让 master 知道最终文件名。）

>**【笔记】：** 
>1. 为什么要写“私有临时文件”？
> * 避免读到脏数据：如果 Worker 直接往最终文件里写，万一写到一半机器挂了，读文件的人就会读到只有一半的数据。
> * 做法：先写到 temp_file，等全部写完且校验无误后，再由 Master 协调或者通过文件系统操作（如 rename）瞬间变成正式文件。这就是所谓的原子提交——要么完全成功，要么完全不存在，不会有“半成功”的状态。
>2. 为什么 Map 产生 R 个文件？
> * Map 需要把数据提前分好类（Partitioning）：
>   * 给 Reduce 1 的数据放入 temp_file_1
>   * 给 Reduce 2 的数据放入 temp_file_2
>   * ...
>   * 给 Reduce R 的数据放入 temp_file_R
> * 这样 Reduce 任务启动时，只需要去拉取属于自己的那一份文件即可。
>
> **MapReduce 通过“先写本地临时文件 + 任务完成时向 master 原子注册文件名”的方式，把可能重复执行的任务输出，变成了对外部只出现一次的最终结果。** 这就是exactly-once 的核心技巧。

When a reduce task completes, the reduce worker atomically renames its temporary output file to the final output file. If the same reduce task is executed on multi-ple machines, multiple rename calls will be executed for the same final output file. We rely on the atomic rename operation provided by the underlying file system to guar-antee that the final file system state contains just the data produced by one execution of the reduce task.

>当一个 reduce 任务完成时，reduce worker 会将它的临时输出文件**原子性地重命名 （atomic rename）** 为最终输出文件名。 如果同一个 reduce 任务在多台机器上被重复执行（例如由于前面某台 worker 崩溃导致任务被重新调度），就会对同一个最终输出文件名执行多次 rename 操作。 我们依靠底层文件系统提供的原子 rename 操作来保证：最终文件系统的状态中，只会保留某一次 reduce 任务执行所产生的数据（其他几次的临时文件要么改名失败，要么被覆盖），绝不会出现多个版本并存或内容混合的情况。

The vast majority of our $map$ and $reduce$ operators are deterministic, and the fact that our semantics are equiv- alent to a sequential execution in this case makes it very easy for programmers to reason about their program’s be-havior. When the $map$ and/or $reduce$ operators are non-deterministic, we provide weaker but still reasonable se-mantics. In the presence of non-deterministic operators, the output of a particular reduce task $R_{1}$ is equivalent to the output for $R_{1}$ produced by a sequential execution of the non-deterministic program. However, the output for a different reduce task $R_{2}$ may correspond to the output for $R_{2}$ produced by a different sequential execution of the non-deterministic program.

>我们编写的绝大多数 **map** 和 **reduce** 函数都是**确定性**的（即相同的输入永远产生相同的输出）。正因为如此，MapReduce 的执行语义在这种情况下**等价于一次顺序执行**，这让程序员**极易推理**程序的行为，调试和验证都非常简单。
>当 **map 和/或 reduce 函数是非确定性**的（即相同输入可能产生不同输出）时，我们提供的是**稍弱但仍然合理**的语义保证，具体如下：
> - 对于某个特定的 reduce 任务 **R₁**，它的最终输出等价于**某一次**非确定性程序的顺序执行所产生的 R₁ 的输出。
> - 但对于另一个不同的 reduce 任务 **R₂**，它的输出可能对应于**另一次**非确定性程序的顺序执行所产生的 R₂ 的输出。
>换句话说：
> - 每个 reduce 分区内部是一致的（相当于某一次完整的顺序执行在该分区上的结果）；
> - 但不同 reduce 分区之间可能来自程序**不同的运行路径**，因此整体输出不一定等价于单次顺序执行的完整结果。

>**【笔记】：**  “只要你的函数是确定性的，MapReduce 就给你完美的顺序执行假象；如果你写了非确定性函数，我们至少保证每个 reduce 分区内部是一致的，跨分区可能不一致——这已经是分布式系统能给的最好保证了。”
>这就是 Google MapReduce 论文对**确定性与非确定性函数语义**的经典描述，也是很多程序员误以为 MapReduce  “一定 exactly-once 且顺序一致”  的根源——其实** 只有在确定性函数下才完全成立**。

Consider map task $M$ and reduce tasks $R_{1}$ and $R_{2}$.
Let $e(R_{i})$ be the execution of Ri that committed (there
is exactly one such execution). The weaker semantics
arise because $e(R_{1})$ may have read the output produced
by one execution of $M$ and $e(R_{2})$ may have read the
output produced by a different execution of $M$.


>考虑一个 map 任务 **M**，以及两个 reduce 任务 **R₁** 和 **R₂**。
>用 **e(Rᵢ)** 表示最终真正提交（committed）的那个 Rᵢ 的执行实例（有且仅有一次这样的执行是生效的）。
>所谓“较弱的语义”产生的原因在于：
>- 提交的 **e(R₁)** 可能读取的是 **M 的某一次执行**产生的中间数据；
>- 而提交的 **e(R₂)** 可能读取的是 **M 的另一次执行**产生的中间数据（两次执行的输出内容可能不同）。

>**【笔记】：**
>即使整个作业最终只保留了一次 map 任务 M 的输出被“正式提交”，但不同的 reduce 任务在执行过程中，可能实际看到并消费了 M 的**不同次重试执行**所产生的中间数据，从而导致即使 map/reduce 函数是非确定性的，不同 reduce 分区的最终结果也可能基于 map 任务的不同运行结果。
```
【笔记】：
场景假设：map 任务 M 因为 worker 崩溃被执行了两次
          M 执行第1次 → 产生中间数据 A
          worker 崩溃
          M 被重新调度执行第2次 → 产生中间数据 B（内容与 A 不同）

最终只有第2次执行的完成消息被 master 接受，所以：
    正式提交的中间数据 = B（即只有 B 会被记录到 master 数据结构）

但是，在实际执行过程中可能发生：
    R₁ 在很早的时候就已经从崩溃前的 worker 拉取到了中间数据 A 并完成了计算
    R₂ 只能等到 M 重做完成后，拉取中间数据 B 再完成计算

结果：
    e(R₁) 读的是 A 的输出
    e(R₂) 读的是 B 的输出
    → 两个 reduce 看到的是 map 任务“不同版本”的结果 → 弱语义的来源
```

>**【笔记】：即使 master 保证了“只有一个 map 执行的结果被正式提交”，但在非确定性情况下，不同的 reduce 任务在运行时可能已经消费了该 map 任务先前失败重试版本的输出，从而破坏了“所有 reduce 都基于完全相同的中间数据”这一强一致性假设。**
>这正是 MapReduce 在非确定性函数下只能提供“每个 reduce 内部一致、但跨 reduce 不一定全局一致”的根本原因。



### 3.4 局部性 (Locality)
Network bandwidth is a relatively scarce resource in our computing environment. We conserve network band-width by taking advantage of the fact that the input data (managed by GFS [8]) is stored on the local disks of the machines that make up our cluster. GFS divides each file into 64 MB blocks, and stores several copies of each block (typically 3 copies) on different machines. The MapReduce master takes the location information of the input files into account and attempts to schedule a map task on a machine that contains a replica of the corre- sponding input data. Failing that, it attempts to schedule a map task near a replica of that task’s input data (e.g., on a worker machine that is on the same network switch as the machine containing the data). When running large MapReduce operations on a significant fraction of the workers in a cluster, most input data is read locally and consumes no network bandwidth.

>在我们的计算环境中，**网络带宽是一种相对稀缺的资源**。  为了尽量节省网络带宽，我们充分利用了这样一个事实：**输入数据（由 GFS 管理[8]）本来就存储在构成集群的机器的本地磁盘上**。
>GFS 会把每个文件切分为 **64 MB** 的块（block），并在不同机器上保存每个块的多个副本（通常是 3 个副本）。
>MapReduce 的 master 在调度 map 任务时，会**优先考虑输入数据的位置信息**，尽量做到：
>1. 首选：把 map 任务调度到**正好存放着该任务输入数据某个副本的机器**上（即本地磁盘读取）。
>2. 次选：如果做不到，就尽量调度到**与数据副本在同一个网络交换机下的机器**上（近距离网络传输）。
>当在一个集群的相当一部分 worker 上运行大规模 MapReduce 作业时，**绝大部分输入数据都能够实现本地读取，几乎不消耗网络带宽**。


> **【笔记】: MapReduce 最省带宽的秘密武器 = GFS 把数据存在本地磁盘 + master 尽量把 map 任务调度到数据所在机器 → 实现“计算向数据移动，而不是数据向计算移动”（move computation to the data）。** 
>这也是 Google 能在上千台机器上跑 MapReduce 却不把网络打爆的核心原因之一。

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