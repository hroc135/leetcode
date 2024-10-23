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
- 方針: BFSで各レベルを左から右へ探索して値をスライスに溜める。
レベル(0-index)が奇数だったらスライスをreverseする。
- 気にしたこと: slices.Reverseの処理が重くならないかどうか確認した。
slices.Reverseは線形時間で実行できる。
入力条件より、木のノード数は高々2000で、最大ノード数を持つレベルのノード数は1000未満。
要素数1000のスライスに対するReverseは、CPUのクロック周波数1e8psを考慮すると、1000 / 1e8 = 1e-5 = 10μs。
これだけ短い時間で処理できるなら大丈夫。
- n: ノード数, k: 最大ノード数を持つレベルのノード数
    - 時間計算量: O(nk)
    - 空間計算量: O(n)

```Go
func zigzagLevelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	zigzagLevelNodes := [][]int{}
	level := 0
	currentLevelNodes := []*TreeNode{root}
	for len(currentLevelNodes) > 0 {
		currentLevelNodeValues := []int{}
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
		if level%2 == 1 {
			slices.Reverse(currentLevelNodeValues)
		}
		zigzagLevelNodes = append(zigzagLevelNodes, currentLevelNodeValues)
		level++
		currentLevelNodes = nextLevelNodes
	}
	return zigzagLevelNodes
}
```

### Step 2
#### 2a reverse実装
```Go
func zigzagLevelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	zigzagLevelNodes := [][]int{}
	level := 0
	currentLevelNodes := []*TreeNode{root}
	for len(currentLevelNodes) > 0 {
		currentLevelNodeValues := []int{}
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
		if level%2 == 1 {
			// slices.Reverse(currentLevelNodeValues)
			reverse(&currentLevelNodeValues)
		}
		zigzagLevelNodes = append(zigzagLevelNodes, currentLevelNodeValues)
		level++
		currentLevelNodes = nextLevelNodes
	}
	return zigzagLevelNodes
}

func reverse(s *[]int) {
	i := 0
	j := len(*s) - 1
	for i < j {
		(*s)[i], (*s)[j] = (*s)[j], (*s)[i]
		i++
		j--
	}
}
```

#### 2b reverse呼ばない
- 参考: https://github.com/seal-azarashi/leetcode/pull/26/files#diff-39117f806e1c76b27224df2000d2200427b950646feb7d63be476d764d29dfa8R14
- 関数呼び出しのオーバーヘッドがなくなる
- その代わり読みにくい

```Go
func zigzagLevelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	result := [][]int{}
	level := 0
	currentLevelNodes := []*TreeNode{root}
	for len(currentLevelNodes) > 0 {
		currentLevelNodeCount := len(currentLevelNodes)
		currentLevelNodeValues := make([]int, 0, currentLevelNodeCount)
		nextLevelNodes := []*TreeNode{}
		for i := 0; i < currentLevelNodeCount; i++ {
			if level%2 == 0 {
				currentLevelNodeValues = append(currentLevelNodeValues, currentLevelNodes[i].Val)
			} else {
				currentLevelNodeValues = append(currentLevelNodeValues, currentLevelNodes[currentLevelNodeCount-i-1].Val)
			}
			if currentLevelNodes[i].Left != nil {
				nextLevelNodes = append(nextLevelNodes, currentLevelNodes[i].Left)
			}
			if currentLevelNodes[i].Right != nil {
				nextLevelNodes = append(nextLevelNodes, currentLevelNodes[i].Right)
			}
		}
		result = append(result, currentLevelNodeValues)
		level++
		currentLevelNodes = nextLevelNodes
	}
	return result
}
```

#### 2c 再帰
- 参考: https://github.com/seal-azarashi/leetcode/pull/26/files#diff-39117f806e1c76b27224df2000d2200427b950646feb7d63be476d764d29dfa8R69
- 思いつかなかった
- 再帰よりstep1のようなBFSの方がレベルごとの探索をより直感的にできるのでベスト解答ではないと思う
- 再帰の練習として実装してみる
- 再帰の深さは木の深さとなる

```Go
func zigzagLevelOrder(root *TreeNode) [][]int {
	if root == nil {
		return [][]int{}
	}
	zigzagLevelOrderValues := [][]int{}
	zigzagLevelOrderRecursively(root, 0, &zigzagLevelOrderValues)
	return zigzagLevelOrderValues
}

func zigzagLevelOrderRecursively(node *TreeNode, level int, zigzagLevelOrderValues *[][]int) {
	for len(*zigzagLevelOrderValues) <= level {
		*zigzagLevelOrderValues = append(*zigzagLevelOrderValues, []int{})
	}
	if level%2 == 0 {
		(*zigzagLevelOrderValues)[level] = append((*zigzagLevelOrderValues)[level], node.Val)
	} else {
		(*zigzagLevelOrderValues)[level] = append([]int{node.Val}, (*zigzagLevelOrderValues)[level]...)
	}
	if node.Left != nil {
		zigzagLevelOrderRecursively(node.Left, level+1, zigzagLevelOrderValues)
	}
	if node.Right != nil {
		zigzagLevelOrderRecursively(node.Right, level+1, zigzagLevelOrderValues)
	}
}
```