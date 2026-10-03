以下のコードは全てGoのデフォルトフォーマッターgofmtにかけてあります。

```Go
// Definition for a binary tree node.
type TreeNode struct {
	Val   int
	Left  *TreeNode
	Right *TreeNode
}
```

### Step 1
- まず、同じ値のノードが複数存在しうるかどうかが気になった
- 配列がソート済みであるという特徴を使って、配列を根と左右のサブツリーに分け、再帰的に二分木を構築する方法を思いついた
- 再帰なのでスタックサイズを気にしてみるが、ノード数が最大1e4で再帰の深さはlog1e4 ≒ 13、Goのスタックサイズ1GBなら余裕
- 実装に結構時間がかかった（1時間くらい？）
- 再帰のヘルパー関数の役割を定めるところで悩んだが、根ノード、根ノードを含む分割前の配列、配列中の根ノードのインデックスを引数として、根ノードと左右の子ノードを結ぶ関数として設計
- インデックスの決め方周りでバグがあり、何度もテストケースで弾かれた
- デバッガーを使う練習にはなった
- n: numsの要素数として、
    - 時間計算量: O(n)
    - 空間計算量: O(n)
        - 1スタックフレームサイズはsortedArrayToBSTRecursiveの引数numsによりO(n)で、再帰関数がn回呼び出されるからO(n^2)である、と最初は思った
        - しかし、リスライス`leftTree := nums[:subRootIndex]`で、スライスがコピーされるわけではなく、
        `leftTree`はオリジナルのnumsへのポインタを持つので、空間計算量はO(n)で合っている
        - 空間計算量について色々考えをめぐらせたついでに、最悪ケースのメモリ使用量を見積もってみる。
        int型は64bitマシンで8Bで、numsの最大要素数は1e4。よって、8B * 1e4 = 80KB。
        こんな単純じゃなくてフレームサイズを考慮したり、numsの要素数だけ`*TreeNode`が作成されるのだから更に 8B * 1e4 = 80KB を足してやらないといけないなど、
        もっと複雑になるのだろう。

```Go
func sortedArrayToBST(nums []int) *TreeNode {
	if len(nums) == 0 {
		return nil
	}
	rootIndex := len(nums) / 2
	root := &TreeNode{Val: nums[rootIndex]}
	sortedArrayToBSTRecursive(nums, root, rootIndex)
	return root
}

// sortedArrayToBSTRecursive connects given root of the subtree to its children.
func sortedArrayToBSTRecursive(nums []int, subRoot *TreeNode, subRootIndex int) {
	if len(nums) <= 1 {
		return
	}
	leftTree := nums[:subRootIndex]
	leftTreeRootIndex := len(leftTree) / 2
	subRoot.Left = &TreeNode{Val: leftTree[leftTreeRootIndex]}
	sortedArrayToBSTRecursive(leftTree, subRoot.Left, leftTreeRootIndex)

	if subRootIndex == len(nums)-1 {
		return
	}
	rightTree := nums[subRootIndex+1:]
	rightTreeRootIndex := len(rightTree) / 2
	subRoot.Right = &TreeNode{Val: rightTree[rightTreeRootIndex]}
	sortedArrayToBSTRecursive(rightTree, subRoot.Right, rightTreeRootIndex)
}
```

### Step 2
#### 2a スタックDFSぽいやり方
- スタックDFSみたいに、深さ優先的にノードを繋げていく方法（searchではないのでDFSとは言えない）
- 英語でsubという接頭辞が付くときに、sub-treeとなると思っていたら、subtreeで一単語となるようなので、変数名も`subTree`から`subtree`へ変更
- 時間計算量: O(n)
- 空間計算量: O(n)

```Go
type subTree struct {
	values    []int
	root      *TreeNode
	rootIndex int
}

func sortedArrayToBST(nums []int) *TreeNode {
	if len(nums) == 0 {
		return nil
	}
	rootIndex := len(nums) / 2
	root := &TreeNode{Val: nums[rootIndex]}
	stack := []subTree{{nums, root, rootIndex}}

	for len(stack) > 0 {
		top := stack[len(stack)-1]
		subtreeValues, subtreeRoot, subtreeRootIndex := top.values, top.root, top.rootIndex
		stack = stack[:len(stack)-1]

		leftTreeValues := subtreeValues[:subtreeRootIndex]
		if len(leftTreeValues) == 0 {
			continue
		}
		leftTreeRootIndex := len(leftTreeValues) / 2
		subtreeRoot.Left = &TreeNode{Val: leftTreeValues[leftTreeRootIndex]}
		stack = append(stack, subTree{leftTreeValues, subtreeRoot.Left, leftTreeRootIndex})

		rightTreeValues := subtreeValues[subtreeRootIndex+1:]
		if len(rightTreeValues) == 0 {
			continue
		}
		rightTreeRootIndex := len(rightTreeValues) / 2
		subtreeRoot.Right = &TreeNode{Val: rightTreeValues[rightTreeRootIndex]}
		stack = append(stack, subTree{rightTreeValues, subtreeRoot.Right, rightTreeRootIndex})
	}

	return root
}
```

#### 2b numsのリスライスをしない
- numsのリスライスをせず、numsの部分スライスの両端インデックスを使うやり方
- step1の空間計算量の議論で、
> O(n^2)である、と最初は思った

とあるように、空間計算量を勘違いしており、O(n)に改善しようと思って思いついた方法

```Go
type subTree struct {
	numsInterval [2]int // half-open interval such that [leftIndex, rightIndex)
	root         *TreeNode
	rootIndex    int
}

func sortedArrayToBST(nums []int) *TreeNode {
	if len(nums) == 0 {
		return nil
	}
	rootIndex := len(nums) / 2
	root := &TreeNode{Val: nums[rootIndex]}
	stack := []subTree{{[2]int{0, len(nums)}, root, rootIndex}}

	for len(stack) > 0 {
		top := stack[len(stack)-1]
		numsInterval, subtreeRoot, subtreeRootIndex := top.numsInterval, top.root, top.rootIndex
		stack = stack[:len(stack)-1]

		if numsInterval[0] == subtreeRootIndex {
			continue
		}
		leftTreeRootIndex := (numsInterval[0] + subtreeRootIndex) / 2
		subtreeRoot.Left = &TreeNode{Val: nums[leftTreeRootIndex]}
		stack = append(stack, subTree{[2]int{numsInterval[0], subtreeRootIndex}, subtreeRoot.Left, leftTreeRootIndex})

		if numsInterval[1] == subtreeRootIndex+1 {
			continue
		}
		rightTreeRootIndex := (subtreeRootIndex + 1 + numsInterval[1]) / 2
		subtreeRoot.Right = &TreeNode{Val: nums[rightTreeRootIndex]}
		stack = append(stack, subTree{[2]int{subtreeRootIndex + 1, numsInterval[1]}, subtreeRoot.Right, rightTreeRootIndex})
	}

	return root
}
```

#### 2c ヘルパーなし再帰
- 参考: https://github.com/SuperHotDogCat/coding-interview/pull/40/files#diff-1018f02b072a5def763a050d7e7a2d269bddcf6a7e6fb830d1fd1f768e7a1f61R8
- なんだそれでできるのかと感動。自分で思いつきたかった
- 時間・空間計算量ともにO(n)

```Go
func sortedArrayToBST(nums []int) *TreeNode {
	if len(nums) == 0 {
		return nil
	}
	if len(nums) == 1 {
		return &TreeNode{Val: nums[0]}
	}
	middleIndex := len(nums) / 2
	middleNode := &TreeNode{Val: nums[middleIndex]}
	middleNode.Left = sortedArrayToBST(nums[:middleIndex])
	middleNode.Right = sortedArrayToBST(nums[middleIndex+1:])
	return middleNode
}
```

#### 2d 区間インデックスを使った再帰
- Goはリスライス時にスライスをコピーしないので2cで問題ないが、一応やってみる
    - Pythonだとコピーが作成されてしまうので注意が必要
- 参考: https://github.com/SuperHotDogCat/coding-interview/pull/40/files#diff-222b78bf9ba0826dbcf0edb9f3c9603dd584003d0f62786874681ae6e701d76aR2
- `middleIndex := (leftIndex + rightIndex) / 2` でinteger overflowに注意して
`middleIndex := leftIndex + (rightIndex - leftIndex)/2` とする書き方もあるが、
要素数が高々 1e4 < 2 ** 14 で、int型は32bitマシンで32bitなので、そこまで気にする必要はなさそう

```Go
func sortedArrayToBST(nums []int) *TreeNode {
	// arguments denotes half-open interval such that [leftIndex, rightIndex)
	var buildBSTRecursively func(leftIndex, rightIndex int) *TreeNode
	buildBSTRecursively = func(leftIndex, rightIndex int) *TreeNode {
		if leftIndex == rightIndex {
			return nil
		}
		middleIndex := (leftIndex + rightIndex) / 2
		middleNode := &TreeNode{Val: nums[middleIndex]}
		middleNode.Left = buildBSTRecursively(leftIndex, middleIndex)
		middleNode.Right = buildBSTRecursively(middleIndex+1, rightIndex)
		return middleNode
	}

	return buildBSTRecursively(0, len(nums))
}
```

### Step 3
- 一番シンプルにかけてパフォーマンスも良い再帰を選択

```Go
func sortedArrayToBST(nums []int) *TreeNode {
	if len(nums) == 0 {
		return nil
	}
	if len(nums) == 1 {
		return &TreeNode{Val: nums[0]}
	}
	middleIndex := len(nums) / 2
	middle := &TreeNode{Val: nums[middleIndex]}
	middle.Left = sortedArrayToBST(nums[:middleIndex])
	middle.Right = sortedArrayToBST(nums[middleIndex+1:])
	return middle
}
```

### Step 4
#### 4a in-order
- https://github.com/hroc135/leetcode/pull/23#issuecomment-2418322326 を受けて
- アルゴリズムの言語化
	- (buildCBT関数)numsの要素数だけ左詰めのバイナリーツリーを空ノードで構成。
	- (setValues関数)buildCBTで作ったツリーに値をin-orderで当てはめていく。
	この際、任意のサブツリーの根は左側の子より大きい値で、右側の子より小さい値であるので、
	左側の子 -> 根 -> 右側の子 の順にnumsの前から値を取り出して当てはめていけば良い

```Go
func sortedArrayToBST(nums []int) *TreeNode {
	cbtRoot := buildCBT(0, len(nums))
	setValues(cbtRoot, &nums)
	return cbtRoot
}

// buildCBT returns the root of the complete binary tree.
func buildCBT(index int, numsLen int) *TreeNode {
	if index >= numsLen {
		return nil
	}
	node := &TreeNode{}
	node.Left = buildCBT(index*2+1, numsLen)
	node.Right = buildCBT(index*2+2, numsLen)
	return node
}

func setValues(root *TreeNode, nums *[]int) {
	if root == nil {
		return
	}
	setValues(root.Left, nums)
	root.Val = (*nums)[0]
	*nums = (*nums)[1:]
	setValues(root.Right, nums)
}
```