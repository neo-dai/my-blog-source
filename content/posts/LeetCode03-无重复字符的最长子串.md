+++
date = '2025-12-16T18:31:42+08:00'
draft = false
title = 'LeetCode03 无重复字符的最长子串'
categories = ["LeetCode"]
tags = ["双指针"]
series = ["LeetCodeHot100"]
math=true
+++

### 一、题目描述

[题目链接](https://leetcode.cn/problems/longest-substring-without-repeating-characters/description/?envType=study-plan-v2&envId=top-100-liked)

给定一个字符串 `s` ，请你找出其中不含有重复字符的 **最长 子串** 的长度。

**示例 1:**

**输入:** s = "abcabcbb"
**输出:** 3 
**解释:** 因为无重复字符的最长子串是 `"abc"`，所以其长度为 3。注意 "bca" 和 "cab" 也是正确答案。

**示例 2:**

**输入:** s = "bbbbb"
**输出:** 1
**解释:** 因为无重复字符的最长子串是 `"b"`，所以其长度为 1。

**示例 3:**

**输入:** s = "pwwkew"
**输出:** 3
**解释:** 因为无重复字符的最长子串是 `"wke"`，所以其长度为 3。
     请注意，你的答案必须是 **子串** 的长度，`"pwke"` 是一个_子序列，_不是子串。

**提示：**

- `0 <= s.length <= 5 * 104`
- `s` 由英文字母、数字、符号和空格组成

### 二、解题思路


1. 核心思想
	- 💡 滑动窗口（本质上还是双指针）：维护一个区间 `[left, right]`，保证窗口内**没有重复字符**。

2. 数据结构
	- `lastPos[c]`：字符 `c` 最近一次出现的下标（没出现过记为 `-1`）。
	-  遍历到 `right` 时，窗口 `[left, right]` 始终是无重复的。

3. 算法步骤
	1) 从左到右枚举 `right`。
	2) 设当前字符为 `c = s[right]`：
		- 若 `c` 之前出现过，并且它的上次出现位置 `lastPos[c]` **在当前窗口内**（`lastPos[c] >= left`），说明把 `c` 加进窗口会造成重复；
		- 此时将 `left` 跳到 `lastPos[c] + 1`，把重复的那一次 `c` 排除掉。
	3) 更新 `lastPos[c] = right`。
	4) 用当前窗口长度更新答案：`maxLen = max(maxLen, right - left + 1)`。

4. 优化
	1) 当前字符集固定且较小（英文字母/数字/符号/空格，可按 ASCII 处理），可用数组替代哈希表：
		- `lastPos[256]`（或 `128`）直接按字符值索引，常数更小；
		- Tips: 在 C/C++ 中注意把 `char` 转为 `unsigned char` 再作为下标，避免负值导致越界。
		
	
### 三、 复杂度分析
- **时间复杂度**: $O(n)$
- **空间复杂度**: $O(1)$（若用固定大小数组按 ASCII 计数）；若使用哈希表则为 $O(\min(n, |\Sigma|))$。

### 四、代码实现

1. C++实现

```cpp
// 双指针+哈希表(array优化)
int lengthOfLongestSubstring(string s) {
	// 按字节处理，本题可视为 ASCII；用 256 更稳妥，且避免 char 为 signed 时出现负下标
	std::array<int, 256> lastPos;
	lastPos.fill(-1);
	int n = s.size();
	int maxLen = 0;
	int left = 0; // 窗口左边界

	for (int i = 0; i < n; ++i) {
		unsigned char currentChar = static_cast<unsigned char>(s[i]);
		
		// 如果当前字符之前出现过，并且出j现在当前窗口内（>= left）
		if (lastPos[currentChar] >= left) {
			// 直接跳到重复字符的下一位，避免了 while 循环的一步步 erase
			left = lastPos[currentChar] + 1;
		}
		
		// 更新当前字符的最新位置
		lastPos[currentChar] = i;
		maxLen = max(maxLen, i - left + 1);
	}
	return maxLen;
}

// 双指针+哈希表
int lengthOfLongestSubstring_v1(string s) {
	if (static_cast<int>(s.size()) <= 1) return static_cast<int>(s.size());
	
	unordered_map<char, int> window;
	int left = 0, maxLen = 0;
	int n = static_cast<int>(s.size());
	
	for (int right = 0; right < n; ++right) {
		if (window.find(s[right]) != window.end()) {
			left = max(left, window[s[right]] + 1);
		}
		// 将当前字符加入窗口
		window[s[right]] = right;
		// 更新最大长度
		maxLen = max(maxLen, right - left + 1);
	}
	
	return maxLen;
}
```
2. golang 实现 
```go
func lengthOfLongestSubstring(s string) int {
	left := 0
	mp := make(map[byte]int)
	max_len := 0
	// 本题可按 ASCII/字节处理：right 是字节下标，窗口长度也是字节长度
	for right := 0; right < len(s); right++ {
		c := s[right]
		if idx, found := mp[c]; found {
			if left < idx+1 {
				left = idx + 1
			}
		}
		mp[c] = right
		if max_len < right-left+1 {
			max_len = right - left + 1
		}
	}
	return max_len
}
```

