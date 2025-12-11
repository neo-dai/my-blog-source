+++
date = '2025-12-10T17:51:34+08:00'
draft = false
title = 'LeetCode49 字母异位词分组'
categories = ["LeetCode"]
tags = ["哈希表", "数组"]
series = ["LeetCodeHot100"]
math = true
+++

### 一、题目描述

[leetcode链接](https://leetcode.cn/problems/group-anagrams?envType=study-plan-v2&envId=top-100-liked)

给你一个字符串数组，请你将 字母异位词 组合在一起。可以按任意顺序返回结果列表。

字母异位词 : 字母异位词是通过重新排列不同单词或短语的字母而形成的单词或短语，并使用所有原字母一次。

**示例 1:**

**输入:** strs = `["eat", "tea", "tan", "ate", "nat", "bat"]`

**输出:** "`[["bat"],["nat","tan"],["ate","eat","tea"]]`"

**解释：**

- 在 strs 中没有字符串可以通过重新排列来形成 `"bat"`。
- 字符串 `"nat"` 和 `"tan"` 是字母异位词，因为它们可以重新排列以形成彼此。
- 字符串 `"ate"` ，`"eat"` 和 `"tea"` 是字母异位词，因为它们可以重新排列以形成彼此。

**示例 2:**

**输入:** strs = `[""]`

**输出:** [[""]]

**示例 3:**

**输入:** strs = `["a"]`

**输出:** [["a"]]

**提示：**

- `1 <= strs.length <= 104`
- `0 <= strs[i].length <= 100`
- `strs[i]` 仅包含小写字母

### 二、解题思路

1. 核心思想
		同类型的字符串仅仅字母顺序不同，意味着将其排序后就可以作为hash表索引，实现快速找到自己的分组
2. 算法步骤
	1. 构建索引：遍历一遍`strs`将字符串排序后拿到索引，并使用索引找到hash表中分组的位置实现插入 
	2. 构建结果：将hash表以题目要求的方式返回
3. 优化
	1. 既然是以字符串为索引 且`小写字母`只有26个， 那就可以使用字母出现的次数作为索引，这样就不用给每个字符串排序了，在单个字符串非常长的情况下效果显著

### 三、 复杂度分析

#### 排序法
- **时间复杂度**: $O(n \times k \log k)$，n 是数组长度，k 是字符串长度 
- **空间复杂度**: $O(n \times k)$，存储 n 个字符串作为 value，最多 n 个 key（每个 key 长度为 k） 

#### 计数法
- **时间复杂度**：$O(n \times k)$
- **空间复杂度**：$O(n \times k)$

### 四、代码实现

1. C++实现 （耗时：1h20min）
```cpp
class Solution {
    public:
        // 计数法
        vector<vector<string>> groupAnagrams(vector<string>& strs) {
            // 1. 构建索引
            unordered_map<string,vector<string>> tmp;
            for (const auto& str : strs)
            {
                string key(26,'0');
                for (const char& c : str )
                {
                    key[c-'a']++;
                }
                tmp[key].push_back(str);
            }

            // 2. 构建结果
            vector<vector<string>> result;
            result.reserve(tmp.size());
            for (auto& it : tmp)
            {
                result.push_back(std::move(it.second));
            }

            // 3. 返回结果
            return result;
        }

    // 排序法
    vector<vector<string>> groupAnagrams2(vector<string>& strs) {
        // 1. 构建索引
        unordered_map<string,vector<string>> tmp;
        for (const auto& str : strs)
        {
            string key = str;
            sort(key.begin(),key.end());
            tmp[key].push_back(str);
        }

        // 2. 构建结果
        vector<vector<string>> result;
        result.reserve(tmp.size());
        for (auto& it : tmp)
        {
	        // tips： 使用 std::move 来避免大量字符串 vector 的深拷贝
            result.push_back(std::move(it.second));
        }

        // 3. 返回结果
        return result;
    }
};
```

2. go 实现 
```go
// 排序法
func groupAnagrams(strs []string) [][]string {
	// 1. 构建索引（排序法）
	// 由于 sort 无法直接排序 string，需要转换为 []byte
	mp := make(map[string][]string)
	for _, str := range strs {
		b := []byte(str)
		sort.Slice(b, func(i, j int) bool { return b[i] < b[j] })
		key := string(b)
		mp[key] = append(mp[key], str)
	}

	// 2. 构建结果
	result := make([][]string, 0, len(mp))
	for _, v := range mp {
		result = append(result, v)
	}

	return result
}

// 计数法
func groupAnagrams2(strs []string) [][]string {
	// 1. 构建索引
	mp := make(map[[26]int][]string)
	for _, str := range strs { // tips: 需要注意的是str仅仅为值拷贝，并非引用 如果需要修改数组元素需要访问strs[i]
		var count [26]int
		for _, c := range str {
			count[c-'a']++
		}
		mp[count] = append(mp[count], str)
	}

	// 2. 构建结果
	// tips: 使用make提前预分配容量可以显著减少内存分配和数据复制
	result := make([][]string, 0, len(mp))
	for _, v := range mp {
		result = append(result, v)
	}

	return result
}


```


### 五、 总结

1. **核心逻辑：映射（Mapping）**
	- 这道题本质上是在问：**如何将“外表不同”但“本质相同”的数据，映射到同一个“唯一标识符” (Key) 上**
	
2. **工程启示**
	- **哈希表设计**：当标准库的 Hash Key 不满足需求时，可以尝试将复杂对象序列化为 String（如 C++ 解法）。
	- **内存优化**：在已知数据规模时，使用 `reserve` (C++) 或 `make` (Go) 预分配内存，以及使用 `std::move` 避免拷贝，能显著提升运行效率。