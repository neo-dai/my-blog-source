+++
date = '2025-11-21T19:31:34+08:00'
draft = false
title = 'LeetCode01 两数之和'
categories = ["LeetCode"]
tags = ["哈希表", "数组"]
series = ["LeetCodeHot100"]
+++

## 题目描述

[链接](https://leetcode.cn/problems/two-sum/description/?envType=study-plan-v2&envId=top-100-liked)

给定一个整数数组 `nums` 和一个整数目标值`target`，请你在该数组中找出 和为目标值 `target`  的那 两个 整数，并返回它们的数组下标。

你可以假设每种输入只会对应一个答案，并且你不能使用两次相同的元素。

你可以按任意顺序返回答案。



 

**示例 1**：

输入：nums = [2,7,11,15], target = 9
输出：[0,1]
解释：因为 nums[0] + nums[1] == 9 ，返回 [0, 1] 。
**示例 2**：

输入：nums = [3,2,4], target = 6
输出：[1,2]
**示例 3**：

输入：nums = [3,3], target = 6
输出：[0,1]

## 解题思路

### 核心思想
使用哈希表来优化查找过程。对于当前遍历到的数`nums[i]`，我们需要找到`target - nums[i]`是否在数组中。

### 算法步骤
1. 创建一个哈希表`num_to_index`，用于存储数值到索引的映射
2. 遍历数组，对于每个元素`nums[i]`：
   - 计算补数`complement = target - nums[i]`
   - 在哈希表中查找`complement`是否存在
   - 如果存在，返回`[num_to_index[complement], i]`
   - 如果不存在，将当前数值和索引存入哈希表
3. 遍历结束后返回空数组（题目保证有解，不会执行到这里）

### 为什么不用暴力解法？
暴力解法需要两层循环，时间复杂度为O(n²)。而使用哈希表可以将查找时间从O(n)降到O(1)，总体时间复杂度优化到O(n)。

## 复杂度分析

- **时间复杂度**: O(n)，其中n是数组长度，我们只需要遍历一次数组
- **空间复杂度**: O(n)，哈希表最多需要存储n个元素

## 代码实现

### C++实现

```cpp
#include "leetcode.h"

class Solution {
  public:
    vector<int> twoSum(vector<int>& nums, int target) {
        unordered_map<int, int> num_to_index;
        for (int i = 0; i < nums.size(); ++i) {
            int complement = target - nums[i];
            // 查找补数是否存在
            if (num_to_index.find(complement) != num_to_index.end()) {
                return {num_to_index[complement], i};
            }
            // 存储当前数值和索引
            num_to_index[nums[i]] = i;
        }
        return {};
    }
};
```

### Go实现

```go
package main

func twoSum(nums []int, target int) []int {
	numToIndex := make(map[int]int)
	for i, num := range nums {
		complement := target - num
		// 查找补数是否存在
		if idx, found := numToIndex[complement]; found {
			return []int{idx, i}
		}
		// 存储当前数值和索引
		numToIndex[num] = i
	}
	return []int{}
}
```

### Python实现

```python 
class Solution(object):
    def twoSum(self, nums, target):
        """
        :type nums: List[int]
        :type target: int
        :rtype: List[int]
        """
        num_to_index = {}
        for i, num in enumerate(nums):
            complement = target - num
            # 查找补数是否存在
            if complement in num_to_index:
                return [num_to_index[complement], i]
            # 存储当前数值和索引
            num_to_index[num] = i
        return []
```

### Lua实现

```lua 
function twoSum(nums, target)
    local num_to_index = {}
    for i = 1, #nums do
        local num = nums[i]
        local complement = target - num
        -- 查找补数是否存在
        if num_to_index[complement] ~= nil then
            return {num_to_index[complement], i}
        end
        -- 存储当前数值和索引
        num_to_index[num] = i
    end
    return {}
end

-- 测试代码(LeetCode平台不支持Lua，需手动测试)
local nums = {2, 7, 11, 15}
local target = 9
local result = twoSum(nums, target)

print("输入数组:")
for i = 1, #nums do
    io.write(nums[i] .. " ")
end
print("\n目标值: " .. target)
print("结果索引: " .. result[1] .. ", " .. result[2])
print("验证: nums[" .. result[1] .. "] + nums[" .. result[2] .. "] = " .. nums[result[1]] .. " + " .. nums[result[2]] .. " = " .. (nums[result[1]] + nums[result[2]]))
```

## 总结

这道题是哈希表应用的经典例题，核心要点：
- 使用哈希表将查找时间从O(n)优化到O(1)
- 边遍历边查找，避免重复元素的问题
- 用空间换时间的典型思路 