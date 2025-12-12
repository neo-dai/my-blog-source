+++
date = '2025-12-12T13:26:36+08:00'
draft = false
title = 'LeetCode128最长连续序列'
categories = ["LeetCode"]
tags = ["哈希表", "数组"]
series = ["LeetCodeHot100"]
math = true
+++

### 一、题目描述

[题目链接](https://leetcode.cn/problems/longest-consecutive-sequence/description/?envType=study-plan-v2&envId=top-100-liked)

给定一个未排序的整数数组 `nums` ，找出数字连续的最长序列（不要求序列元素在原数组中连续）的长度。

请你设计并实现时间复杂度为 `O(n)` 的算法解决此问题。

**示例 1：**

**输入：**nums = [100,4,200,1,3,2]
**输出：**4
**解释：**最长数字连续序列是 [1, 2, 3, 4]。它的长度为 4。

**示例 2：**

**输入：**nums = [0,3,7,2,5,8,4,6,0,1]
**输出：**9

**示例 3：**

**输入：**nums = [1,0,1,2]
**输出：**3

**提示：**

- `0 <= nums.length <= 105`
- `-109 <= nums[i] <= 109`

### 二、解题思路

1. 核心思想
	💡利用hash表查找时间复杂度为$O(1)$的特性来快速找到当前元素+1 
2. 算法步骤
	1. 将列表填入hash表（自动去重）
	2. 遍历hash表，
		1. 如果当前元素不是序列的开始则跳过，避免重复查找 
		2. 反之则从当前元素开始不断的查找下一个`curr_nums+1`
		3. 每论查找结束后更新当前最长连续序列 
3. 思路 
	一开始看到求最长连续序列时就想到了直接`std::sort`后一轮循环搞定，但题目要求在$O(n)$的时间复杂内搞定，这套显然不行。遂思考其他方法。
	发现问题的本质实际上是需要快速的查找的当前数字的+1，于是就只能使用哈希表了，且可以利用当前元素是否为序列起始数字来避免重复查找


### 三、 复杂度分析
- **时间复杂度**: O(n)
- **空间复杂度**: O(n)

### 四、代码实现

1. C++实现

```cpp
class Solution {
public:
    // 方法一：哈希表 
    int longestConsecutive(vector<int>& nums) {
        if (nums.size() == 0) 
            return 0;
        
        unordered_set<int> st;
        for (int num : nums)
            st.insert(num);

        int max_len = 0;
        for (int num : st)
        {
            // 只从连续序列的起点开始计算
            if (st.count(num - 1))
                continue;

            // 从起点开始向后扩展
            int current_len = 1;
            int current_num = num;
            while (st.count(current_num + 1))
            {
                current_len++;
                current_num++;
            }
            max_len = max(max_len, current_len);
        }
        return max_len;
    }

    // 方法二：排序法 
    int longestConsecutive2(vector<int>& nums) {
        if (nums.size() == 0) 
            return 0;

        // 排序 
        sort(nums.begin(),nums.end());
        // 去重
        nums.erase(std::unique(nums.begin(), nums.end()), nums.end());

        int max_len = 1;
        int tmp_len = 1;
        for(int i = 1; i< nums.size(); ++i )
        {
            if (nums[i-1] + 1 == nums[i])
            {
                tmp_len++;
                if (tmp_len > max_len)
                {
                    max_len = tmp_len;    
                }
            }
            else 
            {
                tmp_len = 1;
            }
        }
        return max_len;
    }
};

int main()
{
    Solution solution;
    vector<int> nums = {9,1,4,7,3,-1,0,5,8,-1,6};
    int result = solution.longestConsecutive(nums);
    cout << result << endl;
    return 0;
}
```
2. golang 实现 
```go
func longestConsecutive(nums []int) int {
	if len(nums) == 0 {
		return 0
	}

	// 构建哈希表
	mp := make(map[int]bool)
	for _, num := range nums {
		mp[num] = true
	}

	// 找出最长的连续字段
	maxLen := 0
	for num := range mp {
		// 避免重复遍历: 如果num-1存在，则num不是连续字段的起点，跳过
		if mp[num-1] {
			continue
		}

		// 以num为起点，计算连续字段的长度
		curNum := num
		curLen := 1
		for mp[curNum+1] {
			curNum++
			curLen++
		}
		if curLen > maxLen {
			maxLen = curLen
		}
	}

	return maxLen
}

func longestConsecutive2(nums []int) int {
	if len(nums) <= 0 {
		return 0
	}

	// 1. 排序
	sort.Ints(nums)

	// 2. 找出最长的连续字段
	tmp_len := 1
	max_len := 1
	for i := 1; i < len(nums); i++ {
		if nums[i] == nums[i-1] {
			continue
		} else if nums[i] == nums[i-1]+1 {
			tmp_len++
			if tmp_len > max_len {
				max_len = tmp_len
			}
		} else {
			tmp_len = 1
		}
	}

	return max_len
}

func main() {
	nums := []int{9, 1, 4, 7, 3, -1, 0, 5, 8, -1, 6}
	result := longestConsecutive(nums)
	println(result)
}
```

### 五、 总结

利用哈希表实现 $O(1)$ 时间复杂度的查找，通过只从序列起点开始计算避免重复遍历。