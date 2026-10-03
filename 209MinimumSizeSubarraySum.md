問題: https://leetcode.com/problems/minimum-size-subarray-sum/description/

### Step 1
- 大まかな方針はすぐに立ったが仕事の引き継ぎのイメージが甘くて詰まった
- 時間計算量: O(2n) = O(n)
- 空間計算量: O(1)
- target 以上の subarray が存在しない場合の処理をどうしようか迷った。
下記の方法以外には、result の他に found のようなフラグを用意する方法もある

```Go
func minSubArrayLen(target int, nums []int) int {
	result := math.MaxInt
	subarraySum := 0
	left := 0
	for right := range len(nums) {
		subarraySum += nums[right]
		if subarraySum < target {
			continue
		}
		for ; target <= subarraySum && left <= right; left++ {
			subarraySum -= nums[left]
			result = min(result, right-left+1)
		}
	}
	if result == math.MaxInt {
		return 0
	}
	return result
}
```

### Step 2
#### 2a
- step1 の修正
- 答え(result)の初期値について
    - https://github.com/olsen-blue/Arai60/pull/50/files#r2005904280
        - 確かに答えの最大値は len(nums) なので初期値を len(nums) + 1 としても動く
    - https://github.com/Yoshiki-Iwasa/Arai60/pull/43/files#r1709694524
        - 定数を宣言すると丁寧
- https://github.com/olsen-blue/Arai60/pull/50/files#diff-6d4eb2707ed57d8037bfa2e5985424b237a407741a7602ba92b31e090d1cb096R163
    - left == right であれば subarraySum は 0 になり、target <= subarraySum でなくなるので
    `&& left <= right` のチェックは不要
- https://github.com/olsen-blue/Arai60/pull/50/files#diff-6d4eb2707ed57d8037bfa2e5985424b237a407741a7602ba92b31e090d1cb096R164-R165
    - `min_length` と `prefix_sum` の更新順が自分のとは逆
    - リンク先の方がしっくりくる。
    というか自分が step1 でつまずいていたのは処理の理解が自然でなかったことが伺える
- https://github.com/olsen-blue/Arai60/pull/50/files#r2008742099
    - nums に 0 が含まれる場合の挙動について

```Go
func minSubArrayLen(target int, nums []int) int {
	const notFound = 0
	result := notFound
	subarraySum := 0
	left := 0
	for right := range len(nums) {
		subarraySum += nums[right]
		if subarraySum < target {
			continue
		}
		for target <= subarraySum {
			if result == notFound {
				result = right - left + 1
			} else {
				result = min(result, right-left+1)
			}
			subarraySum -= nums[left]
			left++
		}
	}
	return result
}
```

#### 2b
- 二分探索を用いた解法
1. nums の累積和配列を作る
2. nums[i] が先頭となる部分配列で総和が target 以上となるものの中で最も要素数の少ないものを探せば良い
3. そこで登場するのが二分探索。(0~nums[i-1]の累積和) + target の insert position を探せば良い
- 時間計算量: O(n logn)
- 空間計算量: O(n)
- https://github.com/Yoshiki-Iwasa/Arai60/pull/43/files#r1712678111
    - not found の場合の判定を prefixSums を作り終わった時にできる
    - (追記) https://github.com/fhiyo/leetcode/pull/49/files#r1685369428
        - 関数の一番最初に `sum(nums) < target` でも判定できるので 2d で実装
- https://github.com/Yoshiki-Iwasa/Arai60/pull/43/files#r1709772635
    - この指摘の「prefix_sum の要素を詰め終わったら、nums は役割を全うして prefix_sum が代わりに進む準備ができたような気持ちになりました」に納得
    - 「変数のスコープはできたら短くしたい」の部分についてはそこまで考慮できていなかった

```Go
func minSubArrayLen(target int, nums []int) int {
	// prefixSums[0] = 0
	// prefixSums[i] = nums[0] + ... + nums[i-1]
	prefixSums := make([]int, len(nums)+1)
	for i := range nums {
		prefixSums[i+1] = prefixSums[i] + nums[i]
	}
	if prefixSums[len(prefixSums)-1] < target {
		return 0
	}
	result := len(prefixSums)
	for left := range nums {
		right, _ := slices.BinarySearch(prefixSums, prefixSums[left]+target)
		if right == len(prefixSums) {
			break
		}
		result = min(result, right-left)
	}
	return result
}
```

#### 2c
- 2b の二分探索の区間を (left, len(prefixSums)) の開区間にしてみた
- `if left+right == len(prefixSums) { break }` の部分で可読性が下がったような気がする

```Go
func minSubArrayLen(target int, nums []int) int {
	// prefixSums[0] = 0
	// prefixSums[i] = nums[0] + ... + nums[i-1]
	prefixSums := make([]int, len(nums)+1)
	for i := range nums {
		prefixSums[i+1] = prefixSums[i] + nums[i]
	}
	if prefixSums[len(prefixSums)-1] < target {
		return 0
	}
	result := math.MaxInt
	for left := range nums {
		right, _ := slices.BinarySearch(prefixSums[left:], prefixSums[left]+target)
		if left+right == len(prefixSums) {
			break
		}
		result = min(result, right)
	}
	return result
}
```

#### 2d
- https://github.com/fhiyo/leetcode/pull/49/files#diff-b4505bb135c82fffdf6750131a4227b712965b52787f0d78ace5983440d8b88aR139
    - 左半開区間でやってみる
- 一番最初に not found の場合を処理する

```Go
func SumInt(nums []int) int {
	sum := 0
	for _, n := range nums {
		sum += n
	}
	return sum
}

func minSubArrayLen(target int, nums []int) int {
	if SumInt(nums) < target {
		return 0
	}
	result := math.MaxInt
	subarraySum := 0
	left := -1
	for right := range nums {
		subarraySum += nums[right]
		for target <= subarraySum {
			result = min(result, right-left)
			left++
			subarraySum -= nums[left]
		}
	}
	return result
}
```

### Step 3
- left を含めない subarray を考えた方が left が right を追い越す瞬間がなくてわかりやすかった

```Go
func minSubArrayLen(target int, nums []int) int {
	const notFound = math.MaxInt
	minLength := notFound
	subarraySum := 0
	left := -1
	for right := range nums {
		subarraySum += nums[right]
		if subarraySum < target {
			continue
		}
		for subarraySum >= target {
			minLength = min(minLength, right-left)
			left++
			subarraySum -= nums[left]
		}
	}
	if minLength == notFound {
		return 0
	}
	return minLength
}
```

### CS