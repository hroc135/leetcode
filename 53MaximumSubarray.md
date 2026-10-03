問題: https://leetcode.com/problems/maximum-subarray/description/

### Step 1

- DPの典型問題のはず？
- 二次元DPテーブルを作ってsubarrayの開始点と終了点を管理(閉区間)
- out of memory エラーが出た
    - 小さいテストケースは通ったので、正しい出力は得られるコードになっている
- 以下、通らなかったコード

```Go
func maxSubArray(nums []int) int {
	subarraySumTable := make([][]int, len(nums))
	for i := range nums {
		subarraySumTable[i] = make([]int, len(nums))
	}

	res := math.MinInt
	for i := 0; i < len(nums); i++ {
		for j := i; j < len(nums); j++ {
			if i == j {
				subarraySumTable[i][j] = nums[i]
				res = max(res, subarraySumTable[i][j])
				continue
			}
			subarraySumTable[i][j] = subarraySumTable[i][j-1] + nums[j]
			res = max(res, subarraySumTable[i][j])
		}
	}
	return res
}
```

- DPの大きさを半分のO(n^2 / 2)にしたコード
- これでもout of memory
- ということは空間計算量がO(n^2)より効率的な方法があるっぽい

```Go
func maxSubArray(nums []int) int {
	subarraySumTable := make([][]int, len(nums))
	for i := range nums {
		subarraySumTable[i] = make([]int, len(nums)-i)
	}

	res := math.MinInt
	for i := 0; i < len(nums); i++ {
		for j := i; j < len(nums); j++ {
			if i == j {
				subarraySumTable[i][j-i] = nums[i]
				res = max(res, subarraySumTable[i][j-i])
				continue
			}
			subarraySumTable[i][j-i] = subarraySumTable[i][j-i-1] + nums[j]
			res = max(res, subarraySumTable[i][j-i])
		}
	}
	return res
}
```

- ひとまず、O(n^2)で使用しているヒープメモリの大きさを見積もってみる
    - int型は64bitマシンで64bit=8B
    - leetcodeの制約より、len(nums) <= 1e5
    - 1e5^2 * 8 = 8e10B = 80GB
    - 自分のMacのメインメモリは16GBなので、たしかにこの大きさならいくら定数倍削ってもダメそう
    - O(n logn)であれば、
    1e5 * log1e5 * 8 ≒ 1e5 * log(2^10 * 100) * 8 ≒ 1e5 * (10 + 7) * 8 ≒ 1.4e7B = 14MB
        - これならL3キャッシュには乗るくらい
        - https://github.com/rihib/leetcode/pull/17/files#diff-61aa55f84f7e470f84d072a38f16df4de11a2618b46af59b2da9bd246df41d88R72
- よく考えたらDPテーブルを作っても、
一個前の値しか参照していないのでその値だけ変数に格納して随時変更していけばいいだけ
- 空間計算量をO(1)にできた
- しかし今度はTLE

```Go
func maxSubArray(nums []int) int {
	if len(nums) == 0 {
		return 0 // 本当は return 0, errorMsg としたい
	}
	res := math.MinInt
	previousSum := math.MinInt
	for i := 0; i < len(nums); i++ {
		for j := i; j < len(nums); j++ {
			if i == j {
				previousSum = nums[j]
				res = max(res, nums[j])
				continue
			}
			currentSum := previousSum + nums[j]
			res = max(res, currentSum)
			previousSum = currentSum
		}
	}
	return res
}
```

- より速いアルゴリズムを思いつかなかったので他の方の回答を見ることに
- 参考: https://github.com/hayashi-ay/leetcode/pull/36/files#diff-a6956948eb5bc3137495f6d70424f00900c8ba03395ebacccf937a76b9a4d988R88
- Kadane's Algorithm というらしい
    - https://www.geeksforgeeks.org/largest-sum-contiguous-subarray/
- 時間計算量: O(n)
- 空間計算量: O(1)

```Go
func maxSubArray(nums []int) int {
	if len(nums) == 0 {
		return 0 // 本当は return 0, err としたい
	}
	maxSum := nums[0]
	tailFixedMaxSum := nums[0] // 調べている要素が尻となる部分配列の最大累積和
	for i := 1; i < len(nums); i++ {
		tailFixedMaxSum = max(nums[i], tailFixedMaxSum+nums[i])
		maxSum = max(maxSum, tailFixedMaxSum)
	}
	return maxSum
}
```

- 気にした制約
    - 空配列の入力があり得るか。
    あり得るなら何を返すべきか
        - leetcodeの制約的にはありえないことになっている。
        - 自分の書いたコードだとmath.MinIntが返るが、それよりはエラーが出たほうが良さそう
    - 負の数が要素に含まれるか。
    含まれないなら全要素の合計値が返すべき値になる
    - integer overflow の可能性
        - leetcodeの制約より、1 <= nums.length <= 10^5, -10^4 <= nums[i] <= 10^4 なので、
        最大累積和は 10^4 * 10^5 = 10^9。
        - 32bitマシンだと、int型は32bit。
        2^32 > 10^9 より、大丈夫そう


### Step 2

#### 2a
- Divide and Conquer
- Leetcodeの問題説明の末尾に、
"Follow up: If you have figured out the O(n) solution, 
try coding another solution using the divide and conquer approach, which is more subtle."
とあった
- 時間計算量: O(n logn)
- 時間計算量: O(n)
- 参考: https://github.com/hayashi-ay/leetcode/pull/36/files#diff-a6956948eb5bc3137495f6d70424f00900c8ba03395ebacccf937a76b9a4d988R60

```Go
func maxSubArray(nums []int) int {
	prefixSums := make([]int, len(nums)+1)
	for i := 0; i < len(nums); i++ {
		prefixSums[i+1] = prefixSums[i] + nums[i]
	}

	var maxSubArrayHelper func(left, right int) int
	maxSubArrayHelper = func(left, right int) int {
		if left > right {
			return math.MinInt
		}
		middle := (left + right) / 2
		maxMiddlePrefix := 0
		for i := left; i < middle; i++ {
			maxMiddlePrefix = max(maxMiddlePrefix, prefixSums[middle]-prefixSums[i])
		}
		maxMiddleSuffix := 0
		for i := middle + 2; i <= right+1; i++ {
			maxMiddleSuffix = max(maxMiddleSuffix, prefixSums[i]-prefixSums[middle+1])
		}
		middleIncluded := maxMiddlePrefix + nums[middle] + maxMiddleSuffix
		leftMax := maxSubArrayHelper(left, middle-1)
		rightMax := maxSubArrayHelper(middle+1, right)
		return max(leftMax, middleIncluded, rightMax)
	}

	return maxSubArrayHelper(0, len(nums)-1)
}
```

### Step 3

#### Kadane's Algorithm
```Go
func maxSubArray(nums []int) int {
	if len(nums) == 0 {
		return 0 // 本当は return 0, err としたい
	}
	maxSum := nums[0]
	tempMaxSum := nums[0] // 走査中の要素が末尾となるような部分配列のうちの最大累積和
	for i := 1; i < len(nums); i++ {
		tempMaxSum = max(tempMaxSum+nums[i], nums[i])
		maxSum = max(maxSum, tempMaxSum)
	}
	return maxSum
}
```

### CS
- スタック領域
    - 関数呼び出し、ローカル変数の割り当て
    - 関数呼び出し時に自動的に確保され、関数終了時に自動的に解放
- ヒープ領域
    - プログラム実行中に必要になったメモリを動的に割り当て・解放
    - ガベージコレクションで解放されるのはこの領域