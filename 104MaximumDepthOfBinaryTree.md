以下のコードは全てGoのデフォルトフォーマッターであるgofmtにかけてあります。

```Go
/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
```

### Step 1
- 解答時間：12分。Easy問題は大体このくらいの時間で解くことができるようになってきた。10分以内に収まるようにしたい
- DFS/BFSによる全探索で深さを調べるという方針
- スタックを使ったDFSだと深さを追うのが面倒なのでBFSを使うことに（再帰を使ったDFSはstep2-aで取り組みました）
- 時間計算量：O(n)（nはノードの数）
  - https://www.geeksforgeeks.org/level-order-tree-traversal/?ref=oin_asr3
  - 一般的なBFSはO(V+E)かかるが、二分木だとノードの数だけ探索するだけなのでO(V)になる
- 空間計算量：O(n)

```Go
func maxDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}
	maxDepth := 0
	nodeQueue := []*TreeNode{root}
	for len(nodeQueue) > 0 {
		maxDepth++
		nextLevelNodes := []*TreeNode{}
		for _, node := range nodeQueue {
			if node.Left != nil {
				nextLevelNodes = append(nextLevelNodes, node.Left)
			}
			if node.Right != nil {
				nextLevelNodes = append(nextLevelNodes, node.Right)
			}
		}
		nodeQueue = nextLevelNodes
	}
	return maxDepth
}
```

### Step 2
#### 2-a
- 再帰DFSで解いた。スタックを使って実装すると、深さを保持する構造体を定義する必要があり、少し面倒だが、再帰を使えば想像以上に少ないコード量で実装できた
- https://github.com/goto-untrapped/Arai60/pull/31/files#r1652993127 これを参考に再帰の深さについて見積もりしてみる
  - 64bitマシンのスタックメモリのサイズ上限は1GB（https://github.com/golang/go/blob/f296b7a6f045325a230f77e9bda1470b1270f817/src/runtime/proc.go#L120）
  - スタックフレームのサイズの見積もりは難しい（とgpt4に言われた）が、64bitマシンのアドレスは8バイト、Goのint型は4 or 8バイト。gpt4は大体スタックフレーム100バイトで見積もっていた
  - よって、(スタックメモリの大きさ)÷(関数呼び出しごとのスタックフレーム) = 10^9バイト ÷ 10^2バイト = 10^7回
  - したがって、Leetcodeの入力条件の ノード数<=10^4 程度なら余裕でできるはず
- 時間計算量：O(n)
- 空間計算量：O(n) （1回の関数呼び出しにO(1)でこれがn回あるのでO(n)という理解）

```Go
func maxDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}
  // このif文はいらないと以下リンク先を読んで気がついた
  // https://github.com/hayashi-ay/leetcode/pull/22/files#diff-8467ab6cc6ececb3404ca05d2600450ca5cada8cd06ac2add723c558b796275aR10-R15
	if root.Left == nil && root.Right == nil {
		return 1
	}
	return max(maxDepth(root.Left), maxDepth(root.Right)) + 1
}
```

#### 2-b
- スタックDFS

```Go
func maxDepth(root *TreeNode) int {
	type treeNodeAndLevel struct {
		node  *TreeNode
		level int
	}

	if root == nil {
		return 0
	}

	maxDepth := 0 // 被るので関数名をcomputeMaxDepthに変更したい
	nodeStack := []treeNodeAndLevel{{node: root, level: 1}}
	for len(nodeStack) > 0 {
		top := nodeStack[len(nodeStack)-1]
		nodeStack = nodeStack[:len(nodeStack)-1]

		currentNode, currentLevel := top.node, top.level
		maxDepth = max(maxDepth, currentLevel)

		if currentNode.Left != nil {
			nodeStack = append(nodeStack, treeNodeAndLevel{node: currentNode.Left, level: currentLevel + 1})
		}
		if currentNode.Right != nil {
			nodeStack = append(nodeStack, treeNodeAndLevel{node: currentNode.Right, level: currentLevel + 1})
		}
	}

	return maxDepth
}
```

### Step 3
- Goのスタックメモリサイズ1GBはかなり大きいので再帰を怖がらずに使おう、ということで最後は再帰の美しいコードで締める
  - C#, Java: 1MB
  - Ruby: 256KB
- ※追記 Goの再帰コードはそんなに望ましくないらしいです。
  - https://zenn.dev/nobonobo/articles/e651c66a15aaed657d6e#%E6%80%A7%E8%83%BD%E3%81%AFgo%E4%B8%AD%E7%B4%9A%E3%81%A7c++%E7%8E%84%E4%BA%BA%E3%81%AE9%E5%89%B2%E4%BB%A5%E4%B8%8A
  - https://ymotongpoo.hatenablog.com/about

```Go
func maxDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}
	leftDepth := maxDepth(root.Left)
	rightDepth := maxDepth(root.Right)
	return max(leftDepth, rightDepth) + 1
}
```
