問題: https://leetcode.com/problems/validate-binary-search-tree/description/

以下のコードは全てGoのデフォルトフォーマッターgofmtにかけてあります。

```Go
type TreeNode struct {
	Val   int
	Left  *TreeNode
	Right *TreeNode
}
```

### Step 1
- 方針: サブツリーがそれぞれvalidであるかどうかを調べる。
一つでもinvalidであれば全体もinvalid。
任意のノードに対して、左側の子が根となるサブツリーの最大要素がノードの値より大きかったらinvalid。
同様に、右側の子が根となるサブツリーの最小要素がノードの値より小さかったらinvalid。
- n: 木のノード数
    - 時間計算量: O(n)
    - 空間計算量: O(n)
        - 一つのスタックフレームの大きさはO(1)であり、
        最悪の場合、木が一直線になっていると、
        スタックフレームがn個積まれることになるから
        - balancedな木であればO(log n)
    - 上記より、再帰の回数は最大n回。
    1スタックフレームの大きさは高々100Bで、
    Goのスタックサイズは1GBなので1e7回分くらいまで耐えられる

```Go
type subtree struct {
	valid    bool
	maxValue int
	minValue int
}

func isValidBST(root *TreeNode) bool {
	tree := isValidBSTRecursively(root)
	return tree.valid
}

func isValidBSTRecursively(root *TreeNode) subtree {
	if root == nil {
		return subtree{valid: true, maxValue: math.MinInt, minValue: math.MaxInt}
	}
	leftSubtree := isValidBSTRecursively(root.Left)
	isLeftSubtreeValid := leftSubtree.valid && leftSubtree.maxValue < root.Val
	rightSubtree := isValidBSTRecursively(root.Right)
	isRightSubtreeValid := rightSubtree.valid && rightSubtree.minValue > root.Val
	return subtree{
		valid:    isLeftSubtreeValid && isRightSubtreeValid,
		maxValue: max(root.Val, rightSubtree.maxValue),
		minValue: min(root.Val, leftSubtree.minValue),
	}
}
```

### Step 2
#### 2a
- step1の修正
- step1のコードはleetcodeのテストは通ってしまったが、
以下のvalidなBSTに対してinvalidと判定してしまう
    ```Go
    root := &TreeNode{2, &TreeNode{Val: math.MinInt}, &TreeNode{Val: 3}}
    ```
- 原因は、再帰関数にnilノードが渡された時の返り値が、
    ```Go
    return subtree{valid: true, maxValue: math.MinInt, minValue: math.MaxInt}
    ```
    になっており、
    ```Go
    isLeftSubtreeValid := leftSubtree.valid && leftSubtree.maxValue < root.Val
    ```
    のときにroot.Valがmath.MinIntと等しい値だとfalseとして判定されてしまうからである
- 修正方法として考えたのは、再帰関数にnilノードが渡された時にnilノードであった旨が返り値を見てわかるようにすること。
そのために、subtree構造体のフィールドであるmaxValue, minValueをそれぞれint型へのポインタとし、nilポインタを返せるようにした。
- n: 木のノード数
    - 時間計算量: O(n)
    - 空間計算量: O(n)


```Go
type subtree struct {
	valid    bool
	maxValue *int
	minValue *int
}

func isValidBST(root *TreeNode) bool {
	tree := isValidBSTRecursively(root)
	return tree.valid
}

func isValidBSTRecursively(root *TreeNode) subtree {
	if root == nil {
		return subtree{valid: true, maxValue: nil, minValue: nil}
	}
	leftSubtree := isValidBSTRecursively(root.Left)
	isLeftSubtreeValid := leftSubtree.valid && (leftSubtree.maxValue == nil || *leftSubtree.maxValue < root.Val)
	rightSubtree := isValidBSTRecursively(root.Right)
	isRightSubtreeValid := rightSubtree.valid && (rightSubtree.minValue == nil || *rightSubtree.minValue > root.Val)
	return subtree{
		valid:    isLeftSubtreeValid && isRightSubtreeValid,
		maxValue: pointerToMaxValue(root.Val, rightSubtree.maxValue),
		minValue: pointerToMinValue(root.Val, leftSubtree.minValue),
	}
}

func pointerToMaxValue(rootValue int, rightSubtreeMaxValue *int) *int {
	if rightSubtreeMaxValue == nil || rootValue > *rightSubtreeMaxValue {
		return &rootValue
	} else {
		return rightSubtreeMaxValue
	}
}

func pointerToMinValue(rootValue int, leftSubtreeMinValue *int) *int {
	if leftSubtreeMinValue == nil || rootValue < *leftSubtreeMinValue {
		return &rootValue
	} else {
		return leftSubtreeMinValue
	}
}
```

#### 2b
- in-orderに調べていく方法
- 参考: https://github.com/hayashi-ay/leetcode/pull/38/files
- n: 木のノード数
    - 時間計算量: O(n)
    - 空間計算量: O(n)

```Go
func isValidBST(root *TreeNode) bool {
	var previousValue *int = nil
	stack := []*TreeNode{}
	node := root
	for node != nil {
		stack = append(stack, node)
		node = node.Left
	}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if previousValue != nil && *previousValue >= top.Val {
			return false
		}
		previousValue = &top.Val
		node = top.Right
		for node != nil {
			stack = append(stack, node)
			node = node.Left
		}
	}
	return true
}
```

#### 2c
- inorderに値を入れたリストを作り、最後にstrictな昇順になっているかどうかを確かめる
- 標準ライブラリslicesのIsSortedFuncの第二引数の関数の引数が、
a = s[i], b = s[i+1]の順に並んでいると思ったら逆だった。
なぜ逆順なのだろう？
pkg.go.devのドキュメントに特に何も注意書きがなく、内部実装を見て初めて気がついた
- n: 木のノード数
    - 時間計算量: O(n)
        - 他の解法はinvalidな部分を見つけ次第returnできるが、
        valuesInorderを作りきるまで待って最後に検証するので、
        効率が悪い
        - 改善方法として、valuesInorderの要素数が100とか任意の値になった時に逐次IsSortedFuncをかけて確かめ、okだったらclearすればよし、という策が挙げられる
    - 空間計算量: O(n)
        - 要素がO(n)入るスライスが2つあることと、
        valuesInorderに必ずn個要素が入ることから、
        他の解法と比べると同じO(n)でも少し効率が悪い

```Go
func isValidBST(root *TreeNode) bool {
	valuesInorder := []int{}
	stack := []*TreeNode{}
	node := root
	for node != nil {
		stack = append(stack, node)
		node = node.Left
	}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		valuesInorder = append(valuesInorder, top.Val)
		node = top.Right
		for node != nil {
			stack = append(stack, node)
			node = node.Left
		}
	}
	return slices.IsSortedFunc(valuesInorder, func(a, b int) int {
		return a - b - 1
	})
}
```

#### 2d
- 末尾再帰
- 参考: https://github.com/hayashi-ay/leetcode/pull/38/files
- step1の再帰より簡潔
- odaさんが何度もいろんなところで再帰の考え方を説明していて、
役割分担をどう定義するかなんだな、と頭でわかっているつもりだが、
いまだに実装の苦手意識がある。
今Haskellを使う授業を受けているので再帰のいい訓練になることを願う
- 一般的に、末尾再帰はコンパイラの最適化がかかることが多いので、
そうでない再帰より望ましいが、
Goコンパイラは末尾再帰に対する最適化をかけないので、
あまりパフォーマンスに影響はない
- 時間・空間: O(n)

```Go
func isValidBST(root *TreeNode) bool {
	return isValidBSTRecursively(root, nil, nil)
}

func isValidBSTRecursively(node *TreeNode, lowerBound, upperBound *int) bool {
	if node == nil {
		return true
	}
	if lowerBound != nil && node.Val <= *lowerBound {
		return false
	}
	if upperBound != nil && node.Val >= *upperBound {
		return false
	}
	return isValidBSTRecursively(node.Left, lowerBound, &node.Val) && isValidBSTRecursively(node.Right, &node.Val, upperBound)
}
```

### Step 3
- inorderにチェック

```Go
func isValidBST(root *TreeNode) bool {
	var previousValue *int
	node := root
	stack := []*TreeNode{}
	for node != nil {
		stack = append(stack, node)
		node = node.Left
	}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if previousValue != nil && top.Val <= *previousValue {
			return false
		}
		previousValue = &top.Val
		node = top.Right
		for node != nil {
			stack = append(stack, node)
			node = node.Left
		}
	}
	return true
}
```

- 末尾再帰

```Go
func isValidBST(root *TreeNode) bool {
	return isValidBSTRecursive(root, nil, nil)
}

func isValidBSTRecursive(node *TreeNode, lowerBound, upperBound *int) bool {
	if node == nil {
		return true
	}
	if lowerBound != nil && node.Val <= *lowerBound {
		return false
	}
	if upperBound != nil && node.Val >= *upperBound {
		return false
	}
	return isValidBSTRecursive(node.Left, lowerBound, &node.Val) &&
		isValidBSTRecursive(node.Right, &node.Val, upperBound)
}
```

### Step 4
#### 4a
- 再帰inorderを実装
- 経緯
	- https://github.com/hroc135/leetcode/pull/27#issuecomment-2462253173
	- https://github.com/hroc135/leetcode/pull/27#issuecomment-2462311329
	- https://github.com/hroc135/leetcode/pull/27#issuecomment-2465026481
	- https://github.com/hroc135/leetcode/pull/27#issuecomment-2465128526

```Go
type optionalInt struct {
	hasValue bool
	value    int
}

func isValidBST(root *TreeNode) bool {
	previousValue := &optionalInt{hasValue: false, value: 0}
	return isValidBSTHelper(root, previousValue)
}

func isValidBSTHelper(node *TreeNode, previousValue *optionalInt) bool {
	if node == nil {
		return true
	}
	if !isValidBSTHelper(node.Left, previousValue) {
		return false
	}
	if previousValue.hasValue && node.Val <= previousValue.value {
		return false
	}
	previousValue.hasValue = true
	previousValue.value = node.Val
	return isValidBSTHelper(node.Right, previousValue)
}
```

#### 4b
- goroutine
- マルチスレッドを使える
- 参考: https://github.com/hroc135/leetcode/pull/27#discussion_r1828839054

```Go
func isValidBST(root *TreeNode) bool {
	var previousValue *int
	c := make(chan *TreeNode)
	go traverseInorder(root, c)
	for {
		node, ok := <-c
		if !ok {
			return true
		}
		if previousValue != nil && node.Val <= *previousValue {
			return false
		}
		previousValue = &node.Val
	}
}

func traverseInorder(node *TreeNode, c chan *TreeNode) {
	traverseInorderHelper(node, c)
	close(c)
}

func traverseInorderHelper(node *TreeNode, c chan *TreeNode) {
	if node.Left != nil {
		traverseInorderHelper(node.Left, c)
	}
	c <- node
	if node.Right != nil {
		traverseInorderHelper(node.Right, c)
	}
}
```
