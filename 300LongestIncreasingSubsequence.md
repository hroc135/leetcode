問題: https://leetcode.com/problems/longest-increasing-subsequence/description/
### Step 1
- nums[i:j]について調べるときにnums[i:j-1]の情報が使えそうということでDPを使おうと思った
- DPといったら二次元テーブルと思ってしまい、苦戦した
- わかったつもり -> 実装 -> WA を三度くらい繰り返したので諦めて答えを見に行った
- わかったつもりのコードを一応一つ貼っておく
- WAの理由はlastSmallerNumberIndex関数で、
自分より小さい値のうち一番最後に出現したものが必ずしもlongest increasing subsequenceとは限らない

```Go
func lengthOfLIS(nums []int) int {
	n := len(nums)
	subsequenceLengthTable := make([][]int, n)
	for i := range subsequenceLengthTable {
		s := make([]int, n)
		subsequenceLengthTable[i] = s
	}

	longestSubsequence := 0
	for i := 0; i < n; i++ {
		startNumber := nums[i]
		for j := i; j < n; j++ {
			if i == j {
				subsequenceLengthTable[i][j] = 1
				longestSubsequence = max(longestSubsequence, subsequenceLengthTable[i][j])
				continue
			}
			if nums[j] <= startNumber {
				subsequenceLengthTable[i][j] = subsequenceLengthTable[i][j-1]
				continue
			}
			k := lastSmallerNumberIndex(nums, j)
			subsequenceLengthTable[i][j] = subsequenceLengthTable[i][k] + 1
			longestSubsequence = max(longestSubsequence, subsequenceLengthTable[i][j])
		}
	}
	fmt.Println(subsequenceLengthTable)
	return longestSubsequence
}

func lastSmallerNumberIndex(nums []int, j int) int {
	for i := j - 1; i >= 0; i-- {
		if nums[i] >= nums[j] {
			continue
		}
		return i
	}
	return -1
}
```

- 正答コード
- 参考: https://github.com/hayashi-ay/leetcode/pull/27/files
- n: numsの要素数
    - 時間計算量: O(n^2)
    - 空間計算量: O(n)

```Go
func lengthOfLIS(nums []int) int {
	subsequenceLengths := make([]int, len(nums))
	maxLength := 0
	for i := range nums {
		subsequenceLengths[i] = 1
		for j := i - 1; j >= 0; j-- {
			if nums[j] >= nums[i] {
				continue
			}
			subsequenceLengths[i] = max(subsequenceLengths[i], subsequenceLengths[j]+1)
		}
		maxLength = max(maxLength, subsequenceLengths[i])
	}
	return maxLength
}
```

### Step 2
#### 2a
- 参考: https://discord.com/channels/1084280443945353267/1200089668901937312/1209563502407065602
- step1の`subsequenceLengths`の中身は
「subsequenceLengths[i]はnums[i]をシーケンスの末尾としたときの最大LIS」であるが、
それがパッと見で分からず読み手にパズルを解かせてしまっている、という指摘。たしかに、、
- ということで内側のループを関数として切り出して、中身のわかる関数名をつける

```Go
func lengthOfLIS(nums []int) int {
	lisLengths := make([]int, len(nums))
	maxLength := 0
	for i := range nums {
		lisLengths[i] = maxLISLengthBeforeIndex(i, lisLengths, nums) + 1
		maxLength = max(maxLength, lisLengths[i])
	}
	return maxLength
}

func maxLISLengthBeforeIndex(index int, lisLengths []int, nums []int) int {
	res := 0
	for i := 0; i < index; i++ {
		if nums[i] >= nums[index] {
			continue
		}
		res = max(res, lisLengths[i])
	}
	return res
}
```

#### 2b
- 参考
    - https://github.com/hayashi-ay/leetcode/pull/27/files#diff-b7fbb0dce1473afc0264185268f1a1ef6d682a3a8c997d43bc8bdd636a66ce4aR87
    - https://github.com/fhiyo/leetcode/pull/32/files
- nums=[3,4,0]とする。
    - 長さ1のシーケンスのうち、末尾が最も小さいものは[0]
    - 長さ2のシーケンスのうち、末尾が最も小さいものは[3,4]
    - 長さ3のシーケンスは、ない
    - なので、最終的に[0,4]を作りたい
- nums=[3,4,0,5,2]とする。
    - 長さ1のシーケンスのうち、末尾が最も小さいものは[0]
    - 長さ2のシーケンスのうち、末尾が最も小さいものは[0,2]
    - 長さ3のシーケンスのうち、末尾が最も小さいものは[3,4,5]
    - 長さ4のシーケンスは、ない
    - なので、最終的に[0,2,5]を作りたい
- 時間計算量: O(nlogn)
- 空間計算量: O(n)

```Go
func lengthOfLIS(nums []int) int {
	minimumTailsOfSubsequenceLengths := []int{}
	for _, n := range nums {
		position, _ := slices.BinarySearch(minimumTailsOfSubsequenceLengths, n)
		if position == len(minimumTailsOfSubsequenceLengths) {
			minimumTailsOfSubsequenceLengths = append(minimumTailsOfSubsequenceLengths, n)
			continue
		}
		minimumTailsOfSubsequenceLengths[position] = n
	}
	return len(minimumTailsOfSubsequenceLengths)
}
```

#### 2c
- BIT (Binary Indexed Tree)
- 知らないデータ構造だったので一番下に自分の言葉でまとめてみた
- n: numsの要素数、m: nums[i]のあり得る値のパターン数
    - 時間計算量: O(n logm)
        - leetcodeの制約より、n<=2500, m<=2e4なので、
        2500 * 2e4 = 5e7。1秒間に1e8ステップの命令を実行できるとすると、0.5sでできそう
    - 空間計算量: O(m)
        - leetcodeの制約より、n:m = 2500:2e4 = 1:8
        - つまり、割り当てられたメモリの10%強しか使っていない
- 参考
    - https://leetcode.com/problems/longest-increasing-subsequence/
    - https://github.com/fhiyo/leetcode/pull/32/files#diff-c3956ddb663527250d29d4deb34f80770992fa1ac0063b42f34147932f2df3d4R98
    - https://discord.com/channels/1084280443945353267/1200089668901937312/1209563502407065602

```Go
type MaxBIT struct {
	slice []int
}

func InitMaxBIT(length int) MaxBIT {
	return MaxBIT{make([]int, length+1)}
}

// Get gets the max value stored in the path from idx to the root.
func (bit MaxBIT) Get(idx int) int {
	res := 0
	for idx > 0 {
		res = max(res, bit.slice[idx])
		idx -= idx & (-idx) // parent index
	}
	return res
}

// Update updates the value of idx and its next nodes
// if the original values were smaller than the given val.
func (bit MaxBIT) Update(idx, val int) {
	for idx < len(bit.slice) {
		bit.slice[idx] = max(bit.slice[idx], val)
		idx += idx & (-idx) // next index
	}
}

func lengthOfLIS(nums []int) int {
	const (
		base   = 10001
		length = 20001
	)
	bit := InitMaxBIT(length)
	for _, n := range nums {
		n += base
		lisBefore := bit.Get(n - 1)
		bit.Update(n, lisBefore+1)
	}
	return bit.Get(length)
}
```

#### 2d
- 座標圧縮 + BIT
- 2cで議論したように、-1e4 <= nums[i] <= 1e4 に従ってノード数2e4のBITを作るのはメモリが無駄。
ましてや、nums[i]がfloat型などだったらとても使えない
- そこで使うのが座標圧縮
    - nums=[-1,2,4,2,-5]のときに、[2,3,4,3,1]に変換したい
    - つまり、numsの要素を大きさ順の値に変換したい
    (※BITの0ノードはダミーとして使われるので1-indexedにする)
    - ここで前提となるのは、numsが[1,2,3]でも[2,4,6]でも[-30,-20,-10]でも、
    大小関係の順番さえ同じなら答えは同じになるということ
- n: numsの要素数, m: numsのユニークな要素数
    - 時間計算量: O(n logn)
    - 空間計算量: O(m)
- 参考
    - https://github.com/fhiyo/leetcode/pull/32/files#diff-c3956ddb663527250d29d4deb34f80770992fa1ac0063b42f34147932f2df3d4R98
    - https://discord.com/channels/1084280443945353267/1200089668901937312/1209563502407065602

```Go
type MaxBIT struct {
	slice []int
}

func InitMaxBIT(length int) MaxBIT {
	return MaxBIT{make([]int, length+1)}
}

// Get gets the max value stored in the path from idx to the root.
func (bit MaxBIT) Get(idx int) int {
	res := 0
	for idx > 0 {
		res = max(res, bit.slice[idx])
		idx -= idx & (-idx) // parent index
	}
	return res
}

// Update updates the value of idx and its next nodes
// if the original values were smaller than the given val.
func (bit MaxBIT) Update(idx, val int) {
	for idx < len(bit.slice) {
		bit.slice[idx] = max(bit.slice[idx], val)
		idx += idx & (-idx) // next index
	}
}

func lengthOfLIS(nums []int) int {
	compressedNums, maxCompressedValue := compressCoordinates(nums)
	bit := InitMaxBIT(maxCompressedValue)
	for _, n := range compressedNums {
		lisBefore := bit.Get(n - 1)
		bit.Update(n, lisBefore+1)
	}
	return bit.Get(maxCompressedValue)
}

// compressCoordinates returns new slice of 1-indexed size orders
// and the max value in the compressed slice.
// ex) When nums=[-1,2,4,2,-5], the output is compressed=[2,3,4,3,1], maxCompressedValue=4.
func compressCoordinates(nums []int) (compressed []int, maxCompressedValue int) {
	sortedUniqueNums := []int{}
	for _, n := range nums {
		_, found := slices.BinarySearch(sortedUniqueNums, n)
		if found {
			continue
		}
		sortedUniqueNums = append(sortedUniqueNums, n)
	}
	slices.Sort(sortedUniqueNums)
	maxCompressedValue = len(sortedUniqueNums)

	numToOrder := make(map[int]int)
	for i, n := range sortedUniqueNums {
		numToOrder[n] = i
	}

	compressed = make([]int, len(nums))
	for i, n := range nums {
		compressed[i] = numToOrder[n] + 1 // because compressed is 1-indexed
	}
	return compressed, maxCompressedValue
}
```

#### 2e
- segment tree + 座標圧縮
- 以下参考資料を真似てなんとかAC
    - ACすることが目的ではないのでまだ不十分だが、
    いつまでも一人で躓いていたくないので一旦動いたコードを貼る
- 参考
    - https://github.com/fhiyo/leetcode/pull/32/files#diff-c3956ddb663527250d29d4deb34f80770992fa1ac0063b42f34147932f2df3d4R146
    - https://www.youtube.com/watch?v=ZBHKZF5w4YU&t=702s
    - https://leetcode.com/problems/longest-increasing-subsequence/
- 躓いた箇所
    - segment tree(二次元) -> slice(一次元) への変換。
    segment treeの葉が6個あるときに、総ノード数は11(=6*2-1)だが、
    sliceのサイズを11にしてはいけない。
    slice上はあくまでもleftChildIndex=2i+1みたいな感じで飛ぶので、
    完全二分木を用意してやらないといけない。ただし、これはダミーノードを含むのでややこしい。
    [0,0,0,0,0,0,0,0,0,dummy,dummy,0,0,dummy,dummy]みたいな感じ
    - updateの二分探索的な細かい境界条件の理解が不十分

```Go
type MaxSegmentTree struct {
	tree      []int
	leafCount int
}

func InitSegmentTree(leafCount int) MaxSegmentTree {
	if leafCount == 0 {
		return MaxSegmentTree{[]int{}, 0}
	}
	return MaxSegmentTree{make([]int, 4*leafCount), leafCount}
}

func (st MaxSegmentTree) Query(left, right int) int {
	var queryHelper func(nodeIndex, nodeLeftRange, nodeRightRange int) int
	queryHelper = func(nodeIndex, nodeLeftRange, nodeRightRange int) int {
		if nodeRightRange < left || right < nodeLeftRange {
			return 0
		}
		if left <= nodeLeftRange && nodeRightRange <= right {
			return st.tree[nodeIndex]
		}
		middle := (nodeLeftRange + nodeRightRange) / 2
		leftMax := queryHelper(nodeIndex*2+1, nodeLeftRange, middle)
		rightMax := queryHelper(nodeIndex*2+2, middle+1, nodeRightRange)
		return max(leftMax, rightMax)
	}

	return queryHelper(0, 0, st.leafCount-1)
}

func (st MaxSegmentTree) Update(targetIndex, value int) {
	var updateHelper func(index, left, right int)
	updateHelper = func(index, left, right int) {
		if targetIndex == left && targetIndex == right {
			st.tree[index] = max(st.tree[index], value)
			return
		}
		middle := (left + right) / 2
		if targetIndex <= middle {
			updateHelper(index*2+1, left, middle)
		} else {
			updateHelper(index*2+2, middle+1, right)
		}
		if index*2+1 < len(st.tree) {
			st.tree[index] = max(st.tree[index*2+1], st.tree[index*2+2])
		}
	}

	updateHelper(0, 0, st.leafCount-1)
}

func lengthOfLIS(nums []int) int {
	compressed, maxCompressedValue := compressCoordinates(nums)
	st := InitSegmentTree(maxCompressedValue)
	for _, n := range compressed {
		lisBefore := st.Query(0, n-1)
		st.Update(n, lisBefore+1)
	}
	fmt.Println(st.tree)
	return st.tree[0]
}

func compressCoordinates(nums []int) (compressed []int, uniqueNumCount int) {
	numsCopy := make([]int, len(nums))
	copy(numsCopy, nums)
	slices.Sort(numsCopy)
	numToOrder := make(map[int]int)
	uniqueNumCount = 0
	for _, n := range numsCopy {
		if _, found := numToOrder[n]; found {
			continue
		}
		numToOrder[n] = uniqueNumCount
		uniqueNumCount++
	}
	compressed = []int{}
	for _, n := range nums {
		compressed = append(compressed, numToOrder[n])
	}
	return compressed, uniqueNumCount
}
```

### Step 3

```Go
func lengthOfLIS(nums []int) int {
	smallestTailOfSubsequenceLengths := []int{}
	for _, n := range nums {
		position, found := slices.BinarySearch(smallestTailOfSubsequenceLengths, n)
		if found {
			continue
		}
		if position == len(smallestTailOfSubsequenceLengths) {
			smallestTailOfSubsequenceLengths = append(smallestTailOfSubsequenceLengths, n)
			continue
		}
		smallestTailOfSubsequenceLengths[position] = n
	}
	return len(smallestTailOfSubsequenceLengths)
}
```

### Step 4
- セグ木再挑戦
- slicesのBinarySearch, Sortを実装してみる

### CS
- BIT (Binary Indexed Tree, Fenwick Tree)
    - https://discord.com/channels/1084280443945353267/1084283898617417748/1295302973186117684
    の「道具なので目的を持って作られているものです。だから、用途とその限界が初めに来ると思います。」に則って整理してみる
    - 目的: 配列について、部分配列に対する任意の計算と要素の変更を高速に行いたい（両立したい）
    - 用途: 部分配列の和、積、max/min、その他結合即の成り立つ演算と要素の変更
    - 限界: 最大公約数を求めるなど、結合即の成り立たない演算は行えない
    - 内部実装: リスト。メソッド: get, update
    - O(1)で行える演算におけるBITだとすると、getはO(logn)時間, updateはO(logn)時間、メモリ使用量はO(n)。
    (nはノード数)
    - 参考
        - https://www.youtube.com/watch?v=CWDQJGaN1gY
        - https://www.geeksforgeeks.org/binary-indexed-tree-or-fenwick-tree-2/
        - https://www.hackerearth.com/practice/notes/binary-indexed-tree-or-fenwick-tree/
- Segment Tree
    - 目的: 配列について、部分配列に対する任意の計算と要素の変更を高速に行いたい(BITと同じ？)
    - 用途: 配列について、部分配列の合計値、最大値/最小値、積などの計算
    - 限界: 要素のクエリは遅い
    - 内部実装: 配列。メソッド: query, update
    - パフォーマンス
        - メモリ使用量: O(n)
        - query: O(logn)
        - update: O(logn)
- BIT vs Segment Tree
    - 実装上の違い
        - BITは二分木ではない。
        根はダミー。
        ノード間の移動はビット計算で行われ、parentとnext(横移動)ができる
        - Segment Treeは二分木。
        元の配列の要素は葉ノードになる(うまく言語化できない、、)。
        ノード間の移動は親と左右の子
    - pros and cons
        - セグ木の方ができることが多い。
        BITは逆元がない演算はできないので累積和くらいにしか使えないと書いてあったが、
        逆元のないmaxを実装できてしまったのでよくわからない。
        今回の問題だとセグ木の方が素直ということ？
        - BITの方がパフォーマンスが良い。
        時間・空間ともに同じO(logn)でも定数倍でBITの方が良い
        - 参考: https://stackoverflow.com/questions/64190332/fenwick-tree-vs-segment-tree
- Complete Binary Tree
    - 完全二分木
    - 曖昧な定義
        - 綺麗な二分木
    - 定義
        - すべての葉でないノードはちょうど2個のノードを持つ
        - すべての葉は深さが等しい
    - 性質
        - ノード数は2^i - 1 (i: 深さ)