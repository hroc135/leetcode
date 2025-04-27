問題: https://leetcode.com/problems/next-permutation/description/

### Step 1
- 尻から見ていって一番最初に隣り合う要素が昇順になっているところ以降をいじれば next permutation になる。
それより前はいじる必要なし
    - nums=[1,4,0,5,3,2] で一番最初に隣り合う要素が昇順になっているところは、0 と 3。
    - 0 より右にある 0 より大きい要素のうち、最も小さいものを見つける（ここでは 2）。
    - 0 の位置に 2 を置く（0 を失いたくはないので、swap する）。
    - 2 より右をソートする
    - nums=[1,4,2,0,3,5]
- 上記をやろうとすると、nums が降順の場合になにも起きずに終わってしまうので、関数の頭で別途処理する
    - nums を昇順にしたものを返せばいいのだが、降順を昇順にするには単に反転すればいいので、slices.Reverse を使った
    - t_wada さんがコメントには why not を書こうとつぶやいていたのを思い出し、コメントに書くことに
        - https://x.com/t_wada/status/904916106153828352
- 時間計算量: O(n logn)
    - 最悪の場合は、先頭が最小要素でその他は降順にソートされているとき
- 空間計算量: O(1)
- テストケース
    - nums=[] -> []
    - nums=[0] -> [0]
    - nums=[0,1] -> [1,0]
    - nums=[0,0,0] -> [0,0,0]
    - nums=[0,1,2] -> [0,2,1]
    - nums=[1,2,0] -> [2,0,1]
    - nums=[2,1,0] -> [0,1,2]
    - nums=[1,4,0,5,3,2] -> [1,4,2,0,3,5]
    - nums=[0,1,2,1] -> [0,2,1,1]
    - nums=[0,0,5,0,0] -> [0,5,0,0,0]

```Go
func nextPermutation(nums []int) {
    // slices.IsSortedFunc returns true when nums is an empty slice.
	if slices.IsSortedFunc(nums, func(a, b int) int { return b - a }) {
		// Reversing sorts nums in ascending order because nums was in descending order.
		// slices.Reverse takes O(n) time while pdqsort in slices.Sort takes O(n logn) time.
        // pdqsort would terminate in O(n) time when its in strictly descending order.
		slices.Reverse(nums)
		return
	}
	for i := len(nums) - 2; i >= 0; i-- {
		if nums[i] < nums[i+1] {
			// a is the smallest element of nums[i+1:] that is larger than nums[i].
			a := math.MaxInt
			// ai is the index of a in nums.
			var ai int
			for j := i + 1; j < len(nums); j++ {
				if nums[j] > nums[i] && nums[j] < a {
					a = nums[j]
					ai = j
				}
			}
			nums[i], nums[ai] = nums[ai], nums[i]
			slices.Sort(nums[i+1:])
			return
		}
	}
}
```

### Step 2
#### 2a
- step1 の改善
- ライブラリ関数を使って簡潔に書ける気がする
- と思ったら、そもそもアルゴリズムをもっと簡単にできた
    - https://github.com/olsen-blue/Arai60/pull/59/files#diff-ee8de8f68c4ae03917be0fa643c8defc8592e248688aed43937777d663dbfccdR168
    - 「一番最初に隣り合う要素が昇順になっているところ」より右は降順であることを利用する
    - i: 「一番最初に隣り合う要素が昇順になっているところ」とする
    - nums[i+1:] は降順
    - nums を尻から見て、一番最初に nums[i] より大きい要素になるところを j とする
    - nums[j] は step1 で探した「nums[i] より右にある nums[i] より大きい要素のうち、最も小さいもの」である
    - なぜなら、nums[j-1] >= nums[j] >= nums[j+1] >= ... >= 末尾 だから。
    - nums[j] > nums[i] >= nums[j+1] なので、nums[i] と nums[j] を swap しても、nums[i+1:] は降順
    - nums[i+1:] を reverse すればよい

```Go
func nextPermutation(nums []int) {
	for i := len(nums) - 2; i >= 0; i-- {
		if nums[i] < nums[i+1] {
			for j := len(nums) - 1; j > i; j-- {
				if nums[j] > nums[i] {
					nums[i], nums[j] = nums[j], nums[i]
					slices.Reverse(nums[i+1:])
					return
				}
			}
		}
	}
	slices.Reverse(nums)
}
```

#### 2b
- 2a はさすがにネストが深いと思うので、改善

```Go
func nextPermutation(nums []int)  {
    // left is the first index from the end such that nums[left] < nums[left+1]
    left := len(nums) - 2
    for left >= -1 && nums[left] >= nums[left+1] {
        left--
    }
    if left < 0 {
        slices.Reverse(nums)
        return
    }

    // right is the smallest number > nums[left] from right to left
    right := len(nums) - 1
    for nums[right] <= nums[left] {
        right--
    }

    nums[left], nums[right] = nums[right], nums[left]
    slices.Reverse(nums[left+1:])
}
```

#### 2c
- 2b を関数に切り出して改善
    - https://github.com/hayashi-ay/leetcode/pull/67/files#diff-ee8de8f68c4ae03917be0fa643c8defc8592e248688aed43937777d663dbfccdR119
    - 関数名の参考に
- 時間計算量: O(3n) = O(n)

```Go
func nextPermutation(nums []int) {
	findFirstDecreasingIndexFromTail := func() int {
		for i := len(nums) - 2; i >= 0; i-- {
			if nums[i] < nums[i+1] {
				return i
			}
		}
		return -1
	}

	findNextGreaterNumIndex := func(pivot int) int {
		for i := len(nums) - 1; i > pivot; i-- {
			if nums[i] > nums[pivot] {
				return i
			}
		}
		// This line is unreachable because nums[pivot] < nums[pivot+1]
		panic("unreachable")
	}

	pivot := findFirstDecreasingIndexFromTail()
	if pivot < 0 {
		slices.Reverse(nums)
		return
	}
	nextNumIndex := findNextGreaterNumIndex(pivot)
	nums[pivot], nums[nextNumIndex] = nums[nextNumIndex], nums[pivot]
	slices.Reverse(nums[pivot+1:])
}
```

#### 2d
- https://github.com/usatie/leetcode/pull/2/files#diff-6df63844477a509737ffe87b2dcf17e6b85aaae820bbffe395d625625549a4ddR50
    - nums[pivot] より大きい最小のインデックスを nums[pivot+1:] から探す部分は二分探索でできるじゃんと気が付いた
    - successor という命名もいいと思った
- 時間計算量: O(2n + logn)
    - O(3n) より若干改善

```Go
func nextPermutation(nums []int) {
	pivot := len(nums) - 2
	for ; pivot >= 0; pivot-- {
		if nums[pivot] < nums[pivot+1] {
			break
		}
	}
	if pivot < 0 {
		slices.Reverse(nums)
		return
	}

	successorIndex := UpperBoundRight(nums[pivot+1:], nums[pivot]) + pivot + 1
	nums[pivot], nums[successorIndex] = nums[successorIndex], nums[pivot]
	slices.Reverse(nums[pivot+1:])
}

// UpperBoundRight finds the largest index i such that nums[i] > target.
// nums is sorted in descending order.
func UpperBoundRight(nums []int, target int) int {
	left := -1
	right := len(nums) - 1
	for left < right {
		middle := left + (right-left+1)/2
		if nums[middle] > target {
			left = middle
		} else {
			right = middle - 1
		}
	}
	return right
}
```

### Step 3
- パフォーマンスが微妙に一番いい方法を採用

```Go
func nextPermutation(nums []int) {
	pivotIndex := len(nums) - 2
	for ; pivotIndex >= 0; pivotIndex-- {
		if nums[pivotIndex] < nums[pivotIndex+1] {
			break
		}
	}
	if pivotIndex < 0 {
		slices.Reverse(nums)
		return
	}

	successorIndex := UpperBoundRightDesc(nums[pivotIndex+1:], nums[pivotIndex]) + pivotIndex + 1
	nums[pivotIndex], nums[successorIndex] = nums[successorIndex], nums[pivotIndex]
	slices.Reverse(nums[pivotIndex+1:])
}

// UpperBoundRightDesc returns the largest index such that nums[index] > target.
// nums is in descending order.
// Returns -1 when target is larger than s[0].
func UpperBoundRightDesc[S ~[]E, E cmp.Ordered](s S, target E) int {
	left := -1
	right := len(s) - 1
	for left < right {
		middle := int(uint(left+right+1) >> 1)
		if cmp.Less(target, s[middle]) {
			left = middle
		} else {
			right = middle - 1
		}
	}
	return right
}
```

- Reverse を自作
- https://cs.opensource.google/go/go/+/master:src/slices/slices.go;l=472?q=func%20Reverse&ss=go%2Fgo
- 可読性について突っ込まれそうだが、実際のソースコードとほぼ同じ
    - i, j -> l, r に変更しただけ

```Go
func Reverse[S ~[]E, E any](s S) {
	for l, r := 0, len(s)-1; l < r; l, r = l+1, r-1 {
		s[l], s[r] = s[r], s[l]
	}
}
```

### CS