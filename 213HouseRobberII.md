問題: https://leetcode.com/problems/house-robber-ii/description/

### Step 1
- あり得る解は以下の3通り
    - numsの長さが3以下の場合はその中の最大値(2軒以上強盗できないので)
    - nums[1:]以外の家から強盗する場合
    - nums[:len(nums)-1]以外の家から強盗する場合
- 円構造を直線構造の問題に帰着させられたので、あとは前問のHouse Robberのアルゴリズムを使う
- n: len(nums)
    - 時間計算量: O(n)
    - 空間計算量: O(1) (スライスのコピーは作成されないので)
- テストケース
    - [1] -> 1
    - [1,2] -> 2
    - [1,2,3] -> 3
    - [1,2,3,4] -> 6
    - [1,2,3,4,5] -> 8
    - [5,4,3,2,1] -> 8

```Go
func rob(nums []int) int {
	if len(nums) <= 3 {
		return slices.Max(nums)
	}
	return max(robHelper(nums[:len(nums)-1]), robHelper(nums[1:]))
}

func robHelper(nums []int) int {
	twoBefore := nums[0]
	oneBefore := max(nums[0], nums[1])
	for i := 2; i < len(nums); i++ {
		twoBefore, oneBefore = oneBefore, max(twoBefore+nums[i], oneBefore)
	}
	return oneBefore
}
```

### Step 2
#### 2a
- step1の修正
- 他の方のコードを読んで、 `len(nums) <= 3` で場合分けしている人は少ない
- `len(nums) < 3` だとそもそも円が出来上がらない
という意味で場合分けした方がわかりやすい気がした
- step1は1~k軒目までを物色した時の最大利益を1~k-2軒目までの利益と1~k-1軒目までの利益を元に計算するという方針
- それよりk-1軒目を物色したかしなかったかの２パターンで考えた方が想像しやすそう
	- https://github.com/hroc135/leetcode/pull/33#discussion_r1899010341
- robHelperをrobInLineに変更
- 参考
	- https://github.com/Ryotaro25/leetcode_first60/pull/38/files
	- https://github.com/fhiyo/leetcode/pull/37/files
	- https://github.com/TORUS0818/leetcode/blob/e5fd583fd551e713a7cf802a1d48a8eacbabd8c4/medium/213/answer.md

```Go
func rob(nums []int) int {
	if len(nums) < 3 {
		return slices.Max(nums)
	}
	return max(robInLine(nums[:len(nums)-1]), robInLine(nums[1:]))
}

// robInLine computes the max amount of money that can be robbed
// when the houses are placed in a line.
func robInLine(nums []int) int {
	robbedLast := 0
	skippedLast := 0
	for _, n := range nums {
		robbedTmp := skippedLast + n
		skippedTmp := max(robbedLast, skippedLast)
		robbedLast, skippedLast = robbedTmp, skippedTmp
	}
	return max(robbedLast, skippedLast)
}
```

#### 2b
- メモ付き再帰
- 時間計算量: O(n)
- 空間計算量: O(n)
- 再帰の深さ: O(n)
	- Goのスタックサイズはデフォルトで1GB(64bitマシンの場合)まで使えるので
	1スタックフレーム100Bとすると n <= 1e7 まで耐える
- 参考: https://github.com/Ryotaro25/leetcode_first60/pull/38/files

```Go
func rob(nums []int) int {
	if len(nums) <= 3 {
		return slices.Max(nums)
	}
	memoWithoutTail := make(map[int]int, len(nums))
	memoWithoutHead := make(map[int]int, len(nums))
	return max(robHelper(nums[:len(nums)-1], len(nums)-2, memoWithoutTail), robHelper(nums[1:], len(nums)-2, memoWithoutHead))
}

func robHelper(nums []int, tailIndex int, memo map[int]int) int {
	if v, found := memo[tailIndex]; found {
		return v
	}
	if tailIndex == 0 {
		return nums[0]
	}
	if tailIndex == 1 {
		return max(nums[0], nums[1])
	}
	twoBefore := robHelper(nums, tailIndex-2, memo)
	memo[tailIndex-2] = twoBefore
	oneBefore := robHelper(nums, tailIndex-1, memo)
	memo[tailIndex-1] = oneBefore
	return max(twoBefore+nums[tailIndex], oneBefore)
}
```

#### 2c
- ヘルパー関数の引数を部分配列ではなくインデックスにする方法
- Goのスライスは参照渡しでコピーされないので2aでも空間計算量的に問題ないが、
練習としてインデックスを渡す方法も書いてみる

```Go
func rob(nums []int) int {
	if len(nums) < 3 {
		return slices.Max(nums)
	}

	// robInLine takes start and end index of nums as a half-open range.
	robInLine := func(start, end int) int {
		robbedLast := 0
		skippedLast := 0
		for i := start; i < end; i++ {
			robbedTmp := skippedLast + nums[i]
			skippedTmp := max(robbedLast, skippedLast)
			robbedLast, skippedLast = robbedTmp, skippedTmp
		}
		return max(robbedLast, skippedLast)
	}

	return max(robInLine(0, len(nums)-1), robInLine(1, len(nums)))
}
```

### Step 3

```Go
func rob(nums []int) int {
	if len(nums) < 3 {
		return slices.Max(nums)
	}
	return max(robInLine(nums[:len(nums)-1]), robInLine(nums[1:]))
}

func robInLine(nums []int) int {
	robbedLast := 0
	skippedLast := 0
	for _, n := range nums {
		robCurrent := skippedLast + n
		skipCurrent := max(robbedLast, skippedLast)
		robbedLast = robCurrent
		skippedLast = skipCurrent
	}
	return max(robbedLast, skippedLast)
}
```

### CS
- slices.Maxの実装確認
    - https://cs.opensource.google/go/go/+/refs/tags/go1.23.4:src/slices/sort.go;l=95
    - 空リストの入力に対してpanicすることが意外だった。単にerrorを返すだけでもいい気がしたがなぜ??
		- [Effective Go](https://go.dev/doc/effective_go#panic)にも
		"library functions should avoid panic"と書いてある
	- "For floating-point E, Max propagates NaNs"
		- float型のスライスの中に一つでもNaNがあればNaNを結果として返す
- NaN
	- Not a Number の略
	- IEEE754で定義されている
	- quiet NaN と signaling NaN の2種類ある
	- quiet NaN: 例外を発生させずに伝播していく
	- signaling NaN: 不正演算例外を発生させる