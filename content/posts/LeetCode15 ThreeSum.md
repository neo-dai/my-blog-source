+++
date = '2025-12-13T14:31:34+08:00'
draft = false
title = 'LeetCode15 ThreeSum'
categories = ["LeetCode"]
tags = ["双指针"]
series = ["LeetCodeHot100"]
math=true
+++

### 一、题目描述

[题目链接](https://leetcode.cn/problems/3sum?envType=study-plan-v2&envId=top-100-liked)

给你一个整数数组 `nums` ，判断是否存在三元组 `[nums[i], nums[j], nums[k]]` 满足 `i != j`、`i != k` 且 `j != k` ，同时还满足 `nums[i] + nums[j] + nums[k] == 0` 。请你返回所有和为 `0` 且不重复的三元组。

**注意：**答案中不可以包含重复的三元组。

**示例 1：**

**输入：**nums = [-1,0,1,2,-1,-4]
**输出：**[[-1,-1,2],[-1,0,1]]
**解释：**
nums[0] + nums[1] + nums[2] = (-1) + 0 + 1 = 0 。
nums[1] + nums[2] + nums[4] = 0 + 1 + (-1) = 0 。
nums[0] + nums[3] + nums[4] = (-1) + 2 + (-1) = 0 。
不同的三元组是 [-1,0,1] 和 [-1,-1,2] 。
注意，输出的顺序和三元组的顺序并不重要。

**示例 2：**

**输入：**nums = [0,1,1]
**输出：**[]
**解释：**唯一可能的三元组和不为 0 。

**示例 3：**

**输入：**nums = [0,0,0]
**输出：**[[0,0,0]]
**解释：**唯一可能的三元组和为 0 。

**提示：**

- `3 <= nums.length <= 3000`
- `-105 <= nums[i] <= 105`

### 二、解题思路

1. 核心思想
	排序，然后将问题简化为twoSum 
2. 算法步骤
	1. 排序 
	2. 枚举`nums[i]` 并跳过重复的 
	3. 用双指针在`nums[i]`右侧区间内找twoSun 
	4. 找到解后 
		1. 记录
		2. `nums[left]` 和 `nums[right]`去重 
		3. 移动 `left` `right`
	5. 返回结果
	
### 三、 复杂度分析
- **时间复杂度**:  $O(nlogn)+O(n^2) => O(n^2)$  
	- tips: $O(nlogn)$ 比 $O(n^2)$ 增长慢 所以直接取$O(n^2)$
- **空间复杂度**: $O(1)$

### 四、代码实现

1. C++实现

```cpp
class Solution {
public:
    // nums[i] + nums[j] + nums[k] == 0 
    // i != j != k 

    // shuang指针移动： 在已经排序的情况下 
    // 只会有三种情况 
    /*
        left + right > t 
        left + right < t 
        left + right = t  
    */
    vector<vector<int>> threeSum(vector<int>& nums) {
        const int n = nums.size();
        if(n < 2) 
            return {};

        //1. 排序 
        sort(nums.begin(), nums.end());

        //2. 降低为two sun 
        vector<vector<int>> result;
        for(int i = 0 ; i< n - 2; i++)
        {
            // 去重
            if (i > 0 && nums[i] == nums[i-1])
                continue;

            int left = i + 1;
            int right = n - 1;
            
            while (left < right)
            {
                int sum = nums[i] + nums[left] + nums[right];

                if ( sum > 0 )
                    right--;
                else if(sum < 0 )
                    left++;
                else 
                {
                    result.push_back({nums[i] , nums[left] , nums[right]});

                    while (left < right && nums[left] == nums[left+1]) left++;
                    while (left < right && nums[right] == nums[right-1]) right--;

                    left++;
                    right--;
                }
            }

        }
        return std::move(result);
    }
};
```
2. golang 实现 
```go
func threeSum(nums []int) [][]int {
	n := len(nums)
	if n < 3 {
		return [][]int{}
	}

	// 1. 排序
	sort.Ints(nums)

	// 2. 筛选结果
	result := make([][]int, 0)
	for i := 0; i < n-2; i++ {
		// 去重：跳过重复的 nums[i]
		if i > 0 && nums[i] == nums[i-1] {
			continue
		}

		left := i + 1
		right := n - 1

		for left < right {
			sum := nums[i] + nums[left] + nums[right]

			if sum < 0 {
				left++
			} else if sum > 0 {
				right--
			} else {
				// 找到一组解
				result = append(result, []int{nums[i], nums[left], nums[right]})

				// 跳过重复的 nums[left]
				for left < right && nums[left] == nums[left+1] {
					left++
				}
				// 跳过重复的 nums[right]
				for left < right && nums[right] == nums[right-1] {
					right--
				}

				// 移动指针继续寻找
				left++
				right--
			}
		}
	}

	return result
}
```


