問題リンク: https://leetcode.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/description/

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
- inorder: 左 -> 親 -> 右
- preorder: 親 -> 左 -> 右
- postorder: 左 -> 右 -> 親
- 使った性質
    - inorderは前から順に[左サブツリーの要素, 根, 右サブツリーの要素]
    と分解できる
    - preorderにおいて、若いインデックスの要素は
    遅いインデックスの要素より上に来る
- 問題文で全ての要素がユニークであることが保証されているが、
この条件がないと木は一つに定まらない
    - ex) preorder = [1,1,1], inorder = [1,1,1]
- 要素数をnとすると、
    - 時間計算量: O(n^3)
        - ちょっと自信がない
        - inorderの中から目当てのものが見つかるまで
        slices.Indexを呼ぶので、buildTree一回の計算量はO(n^2)。
        buildTreeは再帰的にn回呼び出されるのでO(n^3)。
    - 空間計算量: O(log n)。最悪でO(n)
        - 1スタックフレームサイズはO(1)でそれがlog n個、
        最悪の場合n個積まれるから
    - 再帰の深さ: log n。最悪でn

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	if len(inorder) == 0 {
		return nil
	}
	var (
		root              *TreeNode
		rootIndexPreorder int
		rootIndexInorder  int
	)
	for iPreorder, vPreorder := range preorder {
		iInorder := slices.Index(inorder, vPreorder)
		if iInorder == -1 {
			continue
		}
		root = &TreeNode{Val: vPreorder}
		rootIndexPreorder = iPreorder
		rootIndexInorder = iInorder
		break
	}
	root.Left = buildTree(preorder[rootIndexPreorder+1:], inorder[:rootIndexInorder])
	root.Right = buildTree(preorder[rootIndexPreorder+1:], inorder[rootIndexInorder+1:])
	return root
}
```

- どういうユースケースでこのようなコードを書くことになるのか気になった
    - マシンAに二分木がある。
    この二分木と同じものをマシンBで構築したい。
    rootのポインタを送るわけにはいかない(マシンAのメモリアドレスなどについて知っていないといけないから)。
    そこで、二分木を構築するためのヒントとしてpreorderとinorderをマシンBに送る。
    マシンB上でbuildTree関数を呼び、二分木を構築する。
    - この時、[3,9,20,null,null,15,7]のような形式で送れば一つのリストで済むのになぜpreorderとinorderに分けるのか？
    preorderとinorderはいずれもnull要素がない。
    つまり、一つのリストで二分木データを送る場合、
    [1,2,null,3,null,null,null,4,null,null,null,null,null,null,null,5]のように平衡でない二分木だとスパースなデータを送ることになり、データサイズが無駄に大きくなる。
    一方、preorder+inorderだと伝送データはスパースにならない。
    - 式を使って評価する。
    一つのリストだと、最良と最悪の場合のデータサイズはそれぞれO(n)とO(n^2)。
    preorder+inorderだと、最良と最悪はともにO(2n)
- マシンAから送られてきたデータが間違っていそうな場合をマシンBが検知できた方が良さそう


### Step 2
#### 2a
- 参考: https://github.com/hayashi-ay/leetcode/blob/e71eb4b97ac9b6c1b882689ca1f1bcfc02a3a495/105.%20Construct%20Binary%20Tree%20from%20Preorder%20and%20Inorder%20Traversal.md
- step1で気づかなかった性質
    - preorder[1:]は前からa個の要素が左サブツリーの要素、
    後ろからb個の要素が右サブツリーの要素。
    aは左サブツリーの要素数。bは右
- n: 木の要素数
    - 再帰の深さ: log n。最悪の場合、木が直線だとn
    - 時間計算量: O(n^2)
        - slices.Index -> O(n), buildTreeがn回呼ばれる
    - 空間計算量: O(nlogn)
        - スタックフレームがlogn個積まれ、
        一つのスタックフレームの大きさは引数の大きさよりO(n)だから

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	if len(inorder) == 0 {
		return nil
	}
	rootValue := preorder[0]
	root := &TreeNode{Val: rootValue}
	rootIndexInorder := slices.Index(inorder, rootValue)
	leftNodeCount := rootIndexInorder
	rightNodeCount := len(inorder) - leftNodeCount - 1
	root.Left = buildTree(preorder[1:leftNodeCount+1], inorder[:rootIndexInorder])
	root.Right = buildTree(preorder[len(preorder)-rightNodeCount:], inorder[rootIndexInorder+1:])
	return root
}
```

#### 2b
- inorderスライスの値とインデックスの組みをmap化する処理を最初に入れることによって、
時間計算量をO(n)に改善。
いちいちinorderを走査してインデックスを調べる必要がなくなった
- 再帰関数に渡す引数をpreorder&inorderの部分sliceではなく、
preorder&inorderの参照したい区間のstart indexと区間の長さに変えた
- Pythonのようにリストが関数に値渡しされるような言語だとリストのコピーをなくせるので空間計算量の改善効果もある。
Goは参照渡しであり、2a, 2bのコードでもpreorderとinorderにappendなどの拡張の操作をしていないので、
スライスのコピーは作られない
- n: 要素数
    - 時間計算量: O(n)
    - 空間計算量: O(n)
    - 再帰の深さ: logn ~ n

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	valueToInorderIndex := make(map[int]int, len(inorder))
	for i, v := range inorder {
		valueToInorderIndex[v] = i
	}

	var buildTreeRecursive func(int, int, int) *TreeNode
	buildTreeRecursive = func(preorderStartIndex, inorderStartIndex, nodeCount int) *TreeNode {
		if nodeCount <= 0 {
			return nil
		}
		rootValue := preorder[preorderStartIndex]
		root := &TreeNode{Val: rootValue}
		rootInorderIndex, ok := valueToInorderIndex[rootValue]
		if !ok {
			return nil // preorderとinorderに誤りがあるときにここに到達するので本当はエラーを返したい
		}
		leftNodeCount := rootInorderIndex - inorderStartIndex
		root.Left = buildTreeRecursive(preorderStartIndex+1, inorderStartIndex, leftNodeCount)
		root.Right = buildTreeRecursive(preorderStartIndex+leftNodeCount+1, rootInorderIndex+1, nodeCount-leftNodeCount-1)
		return root
	}

	return buildTreeRecursive(0, 0, len(preorder))
}
```

#### 2c
- スタックを用いた方法
- 2bについて、スタックフレーム100Bで見積もると、len(preorder) > 1e7
でスタックオーバーフローが生じるのでそれくらいデータサイズが大きいのならこちらの方がいい
- 構造体nodeInfoの命名に迷った
- n: preorder, inorderの要素数
	- 時間計算量: O(n)
	- 空間計算量: O(n)
- 参考: https://github.com/fhiyo/leetcode/pull/31/files#diff-588e20b8d5d13270d9f58e900c601cc9e72e7aa9c9d083442b5e0334dcbee61aR106

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	valueToInorderIndex := make(map[int]int, len(inorder))
	for i, v := range inorder {
		valueToInorderIndex[v] = i
	}

	if len(preorder) == 0 {
		return nil
	}
	root := &TreeNode{Val: preorder[0]}

	type nodeInfo struct {
		node               *TreeNode
		preorderStartIndex int
		inorderStartIndex  int
		nodeCount          int
	}
	stack := []nodeInfo{{root, 0, 0, len(preorder)}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		topInorderIndex := valueToInorderIndex[top.node.Val]
		leftChildCount := topInorderIndex - top.inorderStartIndex
		rightChildCount := top.nodeCount - leftChildCount - 1
		if leftChildCount > 0 {
			leftPreorderStartIndex := top.preorderStartIndex + 1
			top.node.Left = &TreeNode{Val: preorder[leftPreorderStartIndex]}
			stack = append(stack, nodeInfo{top.node.Left, leftPreorderStartIndex, top.inorderStartIndex, leftChildCount})
		}
		if rightChildCount > 0 {
			rightPreorderStartIndex := top.preorderStartIndex + leftChildCount + 1
			top.node.Right = &TreeNode{Val: preorder[rightPreorderStartIndex]}
			stack = append(stack, nodeInfo{top.node.Right, rightPreorderStartIndex, topInorderIndex + 1, rightChildCount})
		}
	}
	return root
}
```

#### 2d
- inorderを手掛かりにpreorder順にノードを繋いでいく方法
- preorderとinorderのインデックスを管理する変数が両方単調増加するのが特徴
- 参考: https://github.com/seal-azarashi/leetcode/pull/29/files#diff-73696500ced0485cecebb638161302c2cffe248c6e8330eeee54cb97e8c95328R101
- 理解するのにかなり時間がかかった
- 言語化してみたいけどうまくできないので、断片的に色々書いてみる
	- preorder順にノードを繋いでいく
	- スタックには、木に繋がれたノードのうち、左の子を持つ可能性のあるものが入っている
	- `inorderIndex`はinorder[inorderIndex]の値のノードが木に繋がれたことを確認できたらインクリメントされる。
	- `peek(stack).Val == inorder[inorderIndex]`とは、
	peek(stack)のノードは左の子を持たないということ
- 時間計算量: O(n)
- 空間計算量: O(n)
	- 最悪の場合は、木が左側一直線になっている時

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	if len(preorder) == 0 {
		return nil
	}
	root := &TreeNode{Val: preorder[0]}
	stack := []*TreeNode{root} // 既に繋がれたノードのうち左の子を持つ可能性のあるものが積まれる
	inorderIndex := 0
	for i := 1; i < len(preorder); i++ {
		top := peek(stack)
		if top.Val != inorder[inorderIndex] {
			top.Left = &TreeNode{Val: preorder[i]}
			push(&stack, top.Left)
			continue
		}
		for len(stack) > 0 && peek(stack).Val == inorder[inorderIndex] {
			top = pop(&stack)
			inorderIndex++
		}
		top.Right = &TreeNode{Val: preorder[i]}
		push(&stack, top.Right)
	}
	return root
}

func peek[E any](stack []E) E {
	return stack[len(stack)-1]
}

func pop[E any](stack *[]E) E {
	top := (*stack)[len(*stack)-1]
	*stack = (*stack)[:len(*stack)-1]
	return top
}

func push[E any](stack *[]E, elem E) {
	*stack = append(*stack, elem)
}
```

### Step 3

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	valueToInorderIndex := make(map[int]int, len(inorder))
	for i, v := range inorder {
		valueToInorderIndex[v] = i
	}

	var buildTreeHelper func(int, int, int) *TreeNode
	buildTreeHelper = func(preorderStartIndex, inorderStartIndex, nodeCount int) *TreeNode {
		if nodeCount <= 0 {
			return nil
		}
		rootValue := preorder[preorderStartIndex]
		root := &TreeNode{Val: rootValue}
		rootInorderIndex, ok := valueToInorderIndex[rootValue]
		if !ok {
			return nil // errorを返したいところ
		}
		leftNodeCount := rootInorderIndex - inorderStartIndex
		root.Left = buildTreeHelper(preorderStartIndex+1, inorderStartIndex, leftNodeCount)
		root.Right = buildTreeHelper(preorderStartIndex+leftNodeCount+1, rootInorderIndex+1, nodeCount-leftNodeCount-1)
		return root
	}

	return buildTreeHelper(0, 0, len(preorder))
}
```

### CS
- auxiliary space
    - 参考: https://www.geeksforgeeks.org/what-is-the-difference-between-auxiliary-space-and-space-complexity/
    - auxiliary: (和)補助
    - auxiliary space: アルゴリズムを実行するために補助的に必要となるメモリサイズ
    - space complexity = input space + auxiliary space
    - ヒープソートの空間計算量はO(n)だが、auxiliary spaceはO(1)
- thread safe
    - あるコードを複数のスレッドで実行しても問題が発生しない、
    つまり、競合が発生せず、単一スレッドで実行した時と同じ結果が得られること
    - プロセスは、それぞれが独立したメモリ領域を持ち、
    異なるプロセスのメモリ領域にアクセスすることはできない
    - 一方、スレッドはプロセス内で実行され、
    同じプロセス内のスレッドで同じメモリ領域を共有する
    - 参考: https://zenn.dev/hikapoppin/articles/76d3df2edebcb3
    - 参考: https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%AC%E3%83%83%E3%83%89%E3%82%BB%E3%83%BC%E3%83%95
- parser: 構文解析器、解析器