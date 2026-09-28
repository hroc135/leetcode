問題: https://leetcode.com/problems/house-robber/description/

### Step 1
- 紙に書いてアルゴリズムを考える
- 考えたテストケース: [1], [1,1], [1,1,1]
- nums[i]が尻になる配列での最大値 =
 max(nums[i-2]が尻になる配列での最大値 + nums[i], nums[i-1]が尻になる配列での最大値)
 と思った
- しかし、入力[2,1,1,2]でWA
- 2個飛ばしの場合を想定できていなかった
- よく考えたらテストケースが少なすぎる。手抜きしない
- テストケースを考える時にパターンをすべて網羅できているかよく考えたほうがいい

- 以下でWA
```Go
func rob(nums []int) int {
	if len(nums) == 1 {
		return nums[0]
	}
	if len(nums) == 2 {
		return max(nums[0], nums[1])
	}
	maxTwoBefore := nums[0]
	maxOneBefore := nums[1]
	for i := 2; i < len(nums); i++ {
		currentMax := max(maxTwoBefore+nums[i], maxOneBefore)
		maxOneBefore, maxTwoBefore = currentMax, maxOneBefore
	}
	return maxOneBefore
}
```

- 修正後
- 最初の3つの条件分岐をループにまとめる方法もあるが、
個人的には最初に特殊ケースを弾いた方が直感的にわかりやすかった
- n = len(nums)として、時間計算量はO(n), 空間計算量はO(1)
```Go
func rob(nums []int) int {
	if len(nums) == 1 {
		return nums[0]
	}
	if len(nums) == 2 {
		return max(nums[0], nums[1])
	}
	if len(nums) == 3 {
		return max(nums[0]+nums[2], nums[1])
	}
	maxThreeBefore := nums[0]
	maxTwoBefore := nums[1]
	maxOneBefore := max(nums[0]+nums[2], nums[1])
	for i := 3; i < len(nums); i++ {
		n := nums[i]
		currentMax := max(maxThreeBefore+n, maxTwoBefore+n, maxOneBefore)
		maxThreeBefore, maxTwoBefore, maxOneBefore = maxTwoBefore, maxOneBefore, currentMax
	}
	return maxOneBefore
}
```

### Step 2

#### 2a
- step1の修正
- 他の方のコードを見てstep1のように3つ先まで参照する必要はないことに気づいた
- numsの長さ1,2,3の場合もループの中に入れた
	- 書いてみたら思ったよりすっきりになった

```Go
func rob(nums []int) int {
	twoBefore := 0
	oneBefore := 0
	for i, n := range nums {
		if i == 0 {
			oneBefore = n
			continue
		}
		if i == 1 {
			twoBefore, oneBefore = oneBefore, max(oneBefore, n)
			continue
		}
		currentMax := max(twoBefore+n, oneBefore)
		twoBefore, oneBefore = oneBefore, currentMax
	}
	return oneBefore
}
```

#### 2b
- メモ付き再帰
- 時間・空間計算量はともにO(n)
- ??メモがないとO(2^n)時間になる??
- ↑ここ自信ないです！！
	- 紙に書いていくと高さ2nの二分木が出来上がりそうな感じになった

```Go
func rob(nums []int) int {
	memo := make(map[int]int, len(nums))

	var robHelper func(tailIndex int) int
	robHelper = func(tailIndex int) int {
		if v, found := memo[tailIndex]; found {
			return v
		}
		if tailIndex == 0 {
			return nums[0]
		}
		if tailIndex == 1 {
			return max(nums[0], nums[1])
		}
		twoBefore := robHelper(tailIndex - 2)
		memo[tailIndex-2] = twoBefore
		oneBefore := robHelper(tailIndex - 1)
		memo[tailIndex-1] = oneBefore
		return max(twoBefore+nums[tailIndex], oneBefore)
	}

	return robHelper(len(nums) - 1)
}
```

#### 2c
- 末尾要素を盗んだか盗まなかったかの2パターンの値を保持する方法
- 参考: https://github.com/TORUS0818/leetcode/pull/37/files#diff-83c62c4ad09009d4bd113ed1c717a697821ba57360e7b4fc2cfcdc8848add9a3R139

```Go
func rob(nums []int) int {
	skippedLast := 0
	robbedLast := nums[0]
	for i := 1; i < len(nums); i++ {
		skippedLast, robbedLast = max(skippedLast, robbedLast), skippedLast+nums[i]
	}
	return max(skippedLast, robbedLast)
}
```

### Step 3
```Go
func rob(nums []int) int {
	skippedLast := 0
	robbedLast := nums[0]
	for i := 1; i < len(nums); i++ {
		skippedLast, robbedLast = max(skippedLast, robbedLast), skippedLast+nums[i]
	}
	return max(skippedLast, robbedLast)
}
```