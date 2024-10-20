
### Step 1
- 方針: BFSを使って木をレベル毎に探索していく
- アルゴリズムを言語化: レベルiのノードをスライスcurrentLevelNodesで保持する。
currentLevelNodesを順に舐めてレベルi+1のノードをnextLevelNodesに、ノードの値をnextLevelNodeValuesに格納する。
レベルi+1にノードがなければループから出て結果を返す。
レベルi+1のノードがあればそれを結果に加え、currentLevelNodesをnextLevelNodesに更新する(レベルiをi+1に更新する)。
- 20分弱でできた（2回テストケースに引っかかった）
    - 次のレベルにノードがない時に空リストが答えの最後に追加されてしまっていた
    - 一番外側のループに条件を加えなかったのでrootがnilでも動くかと思ったが、
    root.Valにアクセスしていたため、エラー
- 時間計算量: O(n)
- 空間計算量: O(n)

```Go
func levelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	nodeValuesByLevel := make([][]int, 0, 2000)
	nodeValuesByLevel = append(nodeValuesByLevel, []int{root.Val})
	currentLevelNodes := []*TreeNode{root}
	for {
		nextLevelNodes := []*TreeNode{}
		nextLevelNodeValues := []int{}
		for _, node := range currentLevelNodes {
			if node.Left != nil {
				nextLevelNodes = append(nextLevelNodes, node.Left)
				nextLevelNodeValues = append(nextLevelNodeValues, node.Left.Val)
			}
			if node.Right != nil {
				nextLevelNodes = append(nextLevelNodes, node.Right)
				nextLevelNodeValues = append(nextLevelNodeValues, node.Right.Val)
			}
		}
		if len(nextLevelNodes) == 0 {
			break
		}
		nodeValuesByLevel = append(nodeValuesByLevel, nextLevelNodeValues)
		currentLevelNodes = nextLevelNodes
	}
	return nodeValuesByLevel
}
```

### Step 2
#### 2a BFS2
- 参考: https://github.com/hayashi-ay/leetcode/pull/32/files#diff-f64e64b98ee3e79b1af4864eb48c186566221d5e613381a9102b5069412dd01eR9
- アルゴリズムを言語化: レベルiのノードをスライスcurrentLevelNodesで保持する。
currentLevelNodesを順に舐めてcurrentLevelNodesの値をcurrentLevelValuesに入れていき、
レベルi+1のノードをnextLevelNodesに入れていく。
currentLevelNodesを舐め終わったらcurrentLevelValuesを結果に加える。
currentLevelNodesをレベルi+1のノード集に更新する。
これをcurrentLevelNodesが0になるまで続ける
- こちら、今いるレベルのノードの値を答えに加え、次のレベルのノードをスライスに溜めていく、
という作業方針の方が、step1の次のレベルのノードの値を答えに加える、という方針より直感的だと思った。

```Go
func levelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	nodeValuesByLevel := [][]int{}
	currentLevelNodes := []*TreeNode{root}
	for len(currentLevelNodes) > 0 {
		currentLevelValues := []int{}
		nextLevelNodes := []*TreeNode{}
		for _, node := range currentLevelNodes {
			currentLevelValues = append(currentLevelValues, node.Val)
			if node.Left != nil {
				nextLevelNodes = append(nextLevelNodes, node.Left)
			}
			if node.Right != nil {
				nextLevelNodes = append(nextLevelNodes, node.Right)
			}
		}
		nodeValuesByLevel = append(nodeValuesByLevel, currentLevelValues)
		currentLevelNodes = nextLevelNodes
	}
	return nodeValuesByLevel
}
```

#### 2b スタックDFS
- 問題文中の"from left to right"を見落としていてWrong Answerになってしまった。

- DFSだとレベルを保持するための構造体を作る必要が生じてしまうので、2aのBFSの解答の方が適切
```Go
type nodeLevel struct {
	node  *TreeNode
	level int
}

func levelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	nodeValuesByLevel := [][]int{}
	stack := []nodeLevel{{root, 0}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		node, level := top.node, top.level
		stack = stack[:len(stack)-1]
		for len(nodeValuesByLevel) <= level {
			nodeValuesByLevel = append(nodeValuesByLevel, []int{})
		}
		nodeValuesByLevel[level] = append(nodeValuesByLevel[level], node.Val)
		if node.Right != nil {
			stack = append(stack, nodeLevel{node.Right, level + 1})
		}
		if node.Left != nil {
			stack = append(stack, nodeLevel{node.Left, level + 1})
		}
	}
	return nodeValuesByLevel
}
```

### Step 3
- レベル毎に木を探索するBFSの方がDFSより自然な発想。
BFSの中でもstep1と比べて2aの方が自然な手順(2aのアルゴリズムの説明参照)なのでこれを採用。
- `currentLevelNodes`の要素数をnとすると、`currentLevelNodeValues`の要素数はnなので初期化時にキャパシティをnに設定。
`nextLevelNodes`の要素数は最大で2n、最小で0。
今回nの最大値は2000で、2000個(< 2^11)のノードからなる綺麗な二分木は一つのレベルで最大2^9 = 512になるので、0 ~ 512だけ差があることになる。
キャパシティを2nと指定して再割り当てをなくすか、無駄なメモリ使用を嫌って指定しないか、間を取ってnとしてみるか、が選択肢としてあるが、
再割り当てが起きても高々9回なので(キャパシティは2^10までは2倍ずつ増えるので)、削れる実行時間よりメモリの無駄の方が大きいと思えたので指定しないことに

```Go
func levelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	nodeValuesByLevel := [][]int{}
	currentLevelNodes := []*TreeNode{root}
	for len(currentLevelNodes) > 0 {
		currentLevelNodeValues := make([]int, 0, len(currentLevelNodes))
		nextLevelNodes := []*TreeNode{}
		for _, node := range currentLevelNodes {
			currentLevelNodeValues = append(currentLevelNodeValues, node.Val)
			if node.Left != nil {
				nextLevelNodes = append(nextLevelNodes, node.Left)
			}
			if node.Right != nil {
				nextLevelNodes = append(nextLevelNodes, node.Right)
			}
		}
		nodeValuesByLevel = append(nodeValuesByLevel, currentLevelNodeValues)
		currentLevelNodes = nextLevelNodes
	}
	return nodeValuesByLevel
}
```