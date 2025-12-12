+++
date = '2025-12-12T14:31:34+08:00'
draft = false
title = 'LeetCode283 移动零'
categories = ["LeetCode"]
tags = ["双指针"]
series = ["LeetCodeHot100"]
math=true
+++

### 一、题目描述

[题目链接](https://leetcode.cn/problems/move-zeroes?envType=study-plan-v2&envId=top-100-liked)


给定一个数组 `nums`，编写一个函数将所有 `0` 移动到数组的末尾，同时保持非零元素的相对顺序。

**请注意** ，必须在不复制数组的情况下原地对数组进行操作。

**示例 1:**

**输入:** nums = `[0,1,0,3,12]`
**输出:** `[1,3,12,0,0]`

**示例 2:**

**输入:** nums = `[0]`
**输出:** `[0]`

**提示**:

- `1 <= nums.length <= 104`
- `-231 <= nums[i] <= 231 - 1`

### 二、解题思路

1. 核心思想
	💡 双指针：慢指针记录最左边0的位置，快指针遍历 遇到非0元素且快慢指针不同时与慢指针交换，同时慢指针前进一步 
	
### 三、 复杂度分析
- **时间复杂度**: $O(n)$
- **空间复杂度**: $O(1)$

### 四、代码实现

1. C++实现

```cpp
void moveZeroes(std::vector<int>& nums) {
	// slow 保存最左边0的位置
	// fast 遍历数组
	size_t slow = 0;
	for (size_t fast = 0; fast < nums.size(); ++fast) {
		if (nums[fast] != 0) {
			if (slow != fast) {  // 避免自己和自己交换
				swap(nums[slow], nums[fast]);
			}
			slow++;
		}
	}
}
```
2. golang 实现 
```go
func moveZeroes(nums []int) {
	slow := 0
	for fast := 0; fast < len(nums); fast++ {
		if nums[fast] != 0 {
			if slow != fast {
				nums[slow], nums[fast] = nums[fast], nums[slow]
			}
			slow++
		}
	}
}
```


