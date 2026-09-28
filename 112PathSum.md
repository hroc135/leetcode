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
- 気にした制約条件: 二分木はバランスされているかどうか
- 方針: 各ノードについて、根からそのノードまでのパスの値の合計値を保持する構造体を作り、
DFSをして、葉ノードに到達したらパスの合計値がtargetSumと等しいか調べ、等しかったらtrueを返す。
等しくならないまま全探索を終えたらfalseを返す
- 実装: 実装はスムーズに進んだが、テストケースでnilポインタへのアクセスが生じてエラーが出た。
原因はスライス`stack`をmakeする際に`stack := make([]nodePathSum, 5000)`としてしまい、
キャパシティの値を間違って要素数として設定してしまっていたこと。
これによって、5000個のnil値が格納されてしまっていた。
- nをノード数とすると、計算量は以下の通り
    - 時間計算量: O(n)
    - 空間計算量: O(n)
- あるノードでpathSumがtargetSumを超えたらそのノードの子は探索する必要がなくなる（stackに入れなくて良い）と思ったが、
制約条件でノードの値は負の数もあるのでこの最適化手法は使えない
- ノード数が最大で5000で、各ノードの値の最大値が1000なので、pathSumは最大5e6になりうる。
2^10 ≒ 1e3 より、5e6 < 2^22。Goのint型は32bitマシンで32bitなので、integer overflowは起きない。

```Go
type nodePathSum struct {
	node    *TreeNode
	pathSum int
}

func hasPathSum(root *TreeNode, targetSum int) bool {
	if root == nil {
		return false
	}
	stack := make([]nodePathSum, 0, 5000)
	stack = append(stack, nodePathSum{root, root.Val})
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if top.node.Left == nil && top.node.Right == nil {
			if top.pathSum != targetSum {
				continue
			}
			return true
		}
		if top.node.Left != nil {
			stack = append(stack, nodePathSum{top.node.Left, top.pathSum + top.node.Left.Val})
		}
		if top.node.Right != nil {
			stack = append(stack, nodePathSum{top.node.Right, top.pathSum + top.node.Right.Val})
		}
	}
	return false
}
```

### Step 2
#### 2a 再帰
- 再帰による回答
- 再帰の深さは高々5000で、1スタックフレームの大きさを100Bとして考えると、500KBのスタックサイズが必要。
Goは1GBで1e7回再帰できるので大丈夫。
- 考え方: 再帰は役割分担の仕様書を考えるようにやると良いと以前どこかでodaさんが言っていた。
以下、`hasPathSumRecursive`の仕様書
1. 入力として現在地node、targetSum(不変)、現在地nodeの前までのパスの合計値、を取る
2. 現在地nodeがnilだったらfalseを返す
3. 現在地nodeが葉ノードだったら、パスの合計値がtargetSumと等しいかどうかを返す
4. それ以外の場合は、まず左側のノードに処理をさせる。
どこかで葉ノードが見つかったら3の結果が返ってくる。
trueだったらtrueを親ノードに渡す(return値trueとして関数から出ようとする)。
falseだったら右側のノードに処理を渡す。
同様に、どこかで葉ノードが見つかったら3の結果が返ってくるので、自身もその結果を返す。
- なんか複雑な仕様書になった気がする。よりシンプルな解法はないだろうか？

```Go
func hasPathSum(root *TreeNode, targetSum int) bool {
	return hasPathSumRecursive(root, targetSum, 0)
}

func hasPathSumRecursive(node *TreeNode, targetSum int, pathSumBeforeNode int) bool {
	if node == nil {
		return false
	}
	pathSum := pathSumBeforeNode + node.Val
	if node.Left == nil && node.Right == nil {
		return pathSum == targetSum
	}
	found := hasPathSumRecursive(node.Left, targetSum, pathSum)
	if found {
		return true
	}
	found = hasPathSumRecursive(node.Right, targetSum, pathSum)
	return found
}
```

#### 2b 再帰改良版
- https://github.com/hayashi-ay/leetcode/pull/30/files 
でシンプルな再帰の解答を発見
- targetSumを減らしていくという発想ができなかった。
これは再帰を書く時の基本的な発想の一つだという気がするので自分で思いつけるようになりたい
- あとは2aの最後の5行程度をorを使うことにより簡略化できることに気が付かなかった
- こちらの再帰も仕様書を書いてみる
1. 上から仕事が回ってきた時、入力rootがnilだったらfalseを返す。
葉ノードだったらroot.ValがtargetSumと等しいかどうかを返す
2. 1以外の場合、targetSumを更新して左ノードと右ノードにそれぞれ仕事を送る
3. 下から仕事の結果が返ってきたら上にそのまま届ける

```Go
func hasPathSum(root *TreeNode, targetSum int) bool {
	if root == nil {
		return false
	}
	if root.Left == nil && root.Right == nil {
		return root.Val == targetSum
	}
	remaining := targetSum - root.Val
	leftFound := hasPathSum(root.Left, remaining)
	rightFound := hasPathSum(root.Right, remaining)
	return leftFound || rightFound
}
```

#### 2c スタックDFS nilノードもスタックに入れる
- スタックDFSでnilノードもスタックに入れる方法。
これにより、条件分岐が少なくなる。
一方、nilノードもスタックに入れるので、最悪の場合、一本のパスだけからなる二分木だとスタックの要素数が木の要素数の倍になってしまう

```Go
type nodePathSum struct {
	node              *TreeNode
	pathSumBeforeNode int
}

func hasPathSum(root *TreeNode, targetSum int) bool {
	stack := make([]nodePathSum, 0, 10000)
	stack = append(stack, nodePathSum{root, 0})
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		node, pathSumBeforeNode := top.node, top.pathSumBeforeNode
		if node == nil {
			continue
		}
		pathSum := pathSumBeforeNode + node.Val
		if node.Left == nil && node.Right == nil && pathSum == targetSum {
			return true
		}
		stack = append(stack, nodePathSum{node.Left, pathSum})
		stack = append(stack, nodePathSum{node.Right, pathSum})
	}
	return false
}
```

### Step 3
```Go
func hasPathSum(root *TreeNode, targetSum int) bool {
	if root == nil {
		return false
	}
	if root.Left == nil && root.Right == nil {
		return root.Val == targetSum
	}
	remaining := targetSum - root.Val
	leftFound := hasPathSum(root.Left, remaining)
	rightFound := hasPathSum(root.Right, remaining)
	return leftFound || rightFound
}
```