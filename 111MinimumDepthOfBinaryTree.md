```Go
// Definition for a binary tree node.
type TreeNode struct {
	Val   int
	Left  *TreeNode
	Right *TreeNode
}
```

### Step 1
- 最初は再帰で解けるかなと思ったが、つまづいたので、BFSでやることに
- 最短距離を探す問題なのでBFSの方が自然な発想
- 最近ループ不変条件を気にするようになった
  - 外側のforループでは、常に`nodesInCurrentLevel`に現在の`level`のnilでないノードが全て格納されている
  - 初めてループ不変条件という概念を知ったときは「実際は誰も意識してなさそうだな」と思ったが、意外と頭の整理に使える
- 時間計算量：O(n)
- 空間計算量：O(log n) (二分木の同じ階層のノードは高々log n個なので)

```Go
func minDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}

	level := 1
	nodesInCurrentLevel := []*TreeNode{root}
	for {
		nodesInNextLevel := []*TreeNode{}
		for _, node := range nodesInCurrentLevel {
			if node.Left == nil && node.Right == nil {
				return level
			}
			if node.Left != nil {
				nodesInNextLevel = append(nodesInNextLevel, node.Left)
			}
			if node.Right != nil {
				nodesInNextLevel = append(nodesInNextLevel, node.Right)
			}
		}
		level++
		nodesInCurrentLevel = nodesInNextLevel
	}
}
```

### Step 2
#### 2a
- nilノードもキューに入れるBFS
- step1のようにnilノードはキューに入れない方が自然な発想だとは思う
- この解法だと冒頭の`if root == nil { return 0 }`を消すことができる

```Go
func minDepth(root *TreeNode) int {
	level := 1
	nodesInCurrentLevel := []*TreeNode{root}
	for len(nodesInCurrentLevel) > 0 {
		nodesInNextLevel := []*TreeNode{}
		for _, node := range nodesInCurrentLevel {
			if node == nil {
				continue
			}
			if node.Left == nil && node.Right == nil {
				return level
			}
			nodesInNextLevel = append(nodesInNextLevel, node.Left)
			nodesInNextLevel = append(nodesInNextLevel, node.Right)
		}
		level++
		nodesInCurrentLevel = nodesInNextLevel
	}
	return 0
}
```

#### 2b
- 再帰
- 自分で試したときは躓いたが、以下を参考に実装
  - https://github.com/seal-azarashi/leetcode/pull/21/files#r1752890984
  - https://github.com/hayashi-ay/leetcode/pull/26/files#diff-c2ef246709da963a01dc6a50ecb5b5ce1169312bb960fb96731d87c76e1aa8a4R33
- ただし、Goでは再帰はループに直す傾向がある
- スタックサイズ見積もり
  - 1フレームの大きさ = 引数8 + 返り値8 + ローカル変数(8*3) + ベースポインタ8 + 戻りアドレス8 = 56B
  - 56B * 10^5 = 5.6MB
  - Goは64bitマシンならスタックサイズ1GBまで耐えられるので大丈夫だろう
  - 参考：https://github.com/rihib/leetcode/pull/41/files#diff-04b9326b75782ef947d7603c8de35ae07dcb272e8ce3949b7983749f0d26a001R20

```Go
func minDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}
	if root.Left == nil && root.Right == nil {
		return 1
	}

	depth := math.MaxInt
	if root.Left != nil {
		depth = min(depth, minDepth(root.Left)+1)
	}
	if root.Right != nil {
		depth = min(depth, minDepth(root.Right)+1)
	}

	return depth
}
```

#### 2c
- levelを保持する構造体を使うBFS

```Go
type nodeAndLevel struct {
	node  *TreeNode
	level int
}

func minDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}

	queue := []nodeAndLevel{{node: root, level: 1}}
	for len(queue) > 0 {
		first := queue[0]
		queue = queue[1:]

		if first.node.Left == nil && first.node.Right == nil {
			return first.level
		}
		if first.node.Left != nil {
			queue = append(queue, nodeAndLevel{node: first.node.Left, level: first.level + 1})
		}
		if first.node.Right != nil {
			queue = append(queue, nodeAndLevel{node: first.node.Right, level: first.level + 1})
		}
	}

	log.Fatal("minDepth terminated with an unknown reason")
	panic("unreachable")
}
```

#### 2d
- BFS
- step1で`nodesInNextLevel := []*TreeNode{}`としていた部分を、二分木の性質を考慮してキャパシティを上の階層のノード数の2倍に設定`nodesInNextLevel := make([]*TreeNode, 0, len(nodesInCurrentLevel)*2)`
  - キャパシティを設定することにより、スライスがキャパシティオーバーでリロケートされるのを防ぐことができ、特に綺麗な形をした二分木に対して効果を発揮できる
- 実験：step1のコードとローカルで実行時間の差を計測
- 1. 深さ17、ノード数2^17の綺麗な二分木（常に子が2ついる）
  - 見積もり実行時間：2^17 / 10e8 ≒ 10e5 / 10e8 = 10e-3 = 1ms
  - step1: 4.3ms
  - 2d: 1.6ms
- 2. 深さ10e5、ノード数10e5の直線
  - step1: 4ms
  - 2d: 5ms
- 予想通り、1のケースで効果を発揮してくれている

```Go
func minDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}

	level := 1
	nodesInCurrentLevel := []*TreeNode{root}
	for {
		nodesInNextLevel := make([]*TreeNode, 0, len(nodesInCurrentLevel)*2)
		for _, node := range nodesInCurrentLevel {
			if node.Left == nil && node.Right == nil {
				return level
			}
			if node.Left != nil {
				nodesInNextLevel = append(nodesInNextLevel, node.Left)
			}
			if node.Right != nil {
				nodesInNextLevel = append(nodesInNextLevel, node.Right)
			}
		}

		level++
		nodesInCurrentLevel = nodesInNextLevel
	}
}
```

### Step 3
- BFS（階層ごとにスライスを作る方法、スライスのキャパシティを指定）

```Go
func minDepth(root *TreeNode) int {
	if root == nil {
		return 0
	}

	level := 1
	currentLevelNodes := []*TreeNode{root}
	for {
		nextLevelNodes := make([]*TreeNode, 0, len(currentLevelNodes)*2)
		for _, node := range currentLevelNodes {
			if node.Left == nil && node.Right == nil {
				return level
			}
			if node.Left != nil {
				nextLevelNodes = append(nextLevelNodes, node.Left)
			}
			if node.Right != nil {
				nextLevelNodes = append(nextLevelNodes, node.Right)
			}
		}
		level++
		currentLevelNodes = nextLevelNodes
	}
}
```
