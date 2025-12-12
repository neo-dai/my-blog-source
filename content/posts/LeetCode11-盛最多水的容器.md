+++
date = '2025-12-12T14:31:34+08:00'
draft = false
title = 'LeetCode11 盛最多水的容器'
categories = ["LeetCode"]
tags = ["双指针"]
series = ["LeetCodeHot100"]
math=true
+++

### 一、题目描述

[题目链接](https://leetcode.cn/problems/longest-consecutive-sequence/description/?envType=study-plan-v2&envId=top-100-liked)

给定一个长度为 `n` 的整数数组 `height` 。有 `n` 条垂线，第 `i` 条线的两个端点是 `(i, 0)` 和 `(i, height[i])` 。

找出其中的两条线，使得它们与 `x` 轴共同构成的容器可以容纳最多的水。

返回容器可以储存的最大水量。
		
**说明：你不能倾斜容器。
![](/images/file-20251212142458583.png)
提示

- `n == height.length`
- `2 <= n <= 105`
- `0 <= height[i] <= 104`
### 二、解题思路

1. 思路 
	题目本质上是从数组选出A、B两个元素使得这个公式的值最大 $(min(A,B)*distance(A,B))$ 
	直接使用双指针，从两端往中间遍历数组，每伦循环计算一下公式的值，如果左边比右边的元素大则左边右移，反之则右边左移


### 三、 复杂度分析
- **时间复杂度**: $O(n)$
- **空间复杂度**: $O(1)$

### 四、代码实现

1. C++实现

```cpp
int maxArea(vector<int>& height) {
	struct MaxPoint
	{
		int Area = 0;
		int Point1 = 0; 
		int Point2 = 0;
	}maxPoint;

	int left = 0;
	int right = height.size() - 1;
	while (left < right)
	{
		// 1. 计算面积 
		int Area = (right - left) * min(height[left],height[right]);
		if (Area > maxPoint.Area)
		{
			maxPoint.Area = Area;
			maxPoint.Point1 = left;
			maxPoint.Point2 = right;
		}

		// 2. 更新坐标
		if (height[left] > height[right] )
		{
			right--;
		}
		else 
		{
			left++;
		}
	}
	return maxPoint.Area;
}
```
2. golang 实现 
```go
func maxArea(height []int) int {
	type MaxArea struct {
		Area   int
		Point1 int
		Point2 int
	}
	maxArea := MaxArea{
		Area:   0,
		Point1: 0,
		Point2: 0,
	}

	left := 0
	right := len(height) - 1
	for left < right {
		// 1. 计算面积
		tmpArea := (right - left) * min(height[left], height[right])
		if tmpArea > maxArea.Area {
			maxArea.Area = tmpArea
		}

		// 2. 移动“指针”
		if height[left] > height[right] {
			right--
		} else {
			left++
		}
	}

	return maxArea.Area
}

func main() {
	height := []int{1, 8, 6, 2, 5, 4, 8, 3, 7}
	result := maxArea(height)
	fmt.Println(result)
}
```


