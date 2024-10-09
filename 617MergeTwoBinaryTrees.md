以下のコードは全てGoのデフォルトフォーマッターgofmtにかけてあります。

### Step 1
- 方針を決めるのに時間がかかった
- 破壊的変更をしないようにとか色々考えていたら頭がこんがらがった
- 二分木はノードに番号を振ることができるので、それを使って木をマップで表現することに
- 下記は Time Limit Exceeded になったコード
- 時間計算量: O(n1 + n2)	(n1: tree1のノード数、n2: tree2のノード数)
- 見積もり実行時間
	- 最悪の場合は入力の木が二つとも直線になっている時で、`overlapTrees`がO(2n), `createNewTree`がO(2n)なので、
	O(2n1 + 2n2 + 2(n1+n2)) = O(4(n1+n2))のはず。
	4*(2000 + 2000) / 10^8 = 16e-5 = 180μs
	- tree1とtree2をそれぞれ全探索してから新しい木を作っているので、探索しながら木を作る方法より遅くなるのはわかるが、
	なぜTLEになるほど遅くなるのかがわからない、、（何か見落としてる？）
- 空間計算量: O(n1 + n2)

```Go
type nodeAndIndex struct {
	node  *TreeNode
	index int
}

func mergeTrees(root1 *TreeNode, root2 *TreeNode) *TreeNode {
	treeMap := make(map[int]int)
	overlapTrees(root1, treeMap)
	overlapTrees(root2, treeMap)
	return createNewTree(treeMap)
}

func overlapTrees(root *TreeNode, treeMap map[int]int) {
	if root == nil {
		return
	}

	treeMap[0] += root.Val
	stack := []nodeAndIndex{{node: root, index: 0}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		if leftChild := top.node.Left; leftChild != nil {
			leftChildIndex := top.index*2 + 1
			treeMap[leftChildIndex] += leftChild.Val
			stack = append(stack, nodeAndIndex{node: leftChild, index: leftChildIndex})
		}
		if rightChild := top.node.Right; rightChild != nil {
			rightChildIndex := top.index*2 + 2
			treeMap[rightChildIndex] += rightChild.Val
			stack = append(stack, nodeAndIndex{node: rightChild, index: rightChildIndex})
		}
	}
}

// createNewTree returns the root of the new tree.
func createNewTree(treeMap map[int]int) *TreeNode {
	if _, ok := treeMap[0]; !ok {
		return nil
	}

	root := &TreeNode{Val: treeMap[0], Left: nil, Right: nil}
	stack := []nodeAndIndex{{node: root, index: 0}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		leftChildIndex := top.index*2 + 1
		rightChildIndex := top.index*2 + 2
		if v, ok := treeMap[leftChildIndex]; ok {
			top.node.Left = &TreeNode{Val: v, Left: nil, Right: nil}
			stack = append(stack, nodeAndIndex{node: top.node.Left, index: leftChildIndex})
		}
		if v, ok := treeMap[rightChildIndex]; ok {
			top.node.Right = &TreeNode{Val: v, Left: nil, Right: nil}
			stack = append(stack, nodeAndIndex{node: top.node.Right, index: rightChildIndex})
		}
	}

	return root
}
```

- https://discord.com/channels/1084280443945353267/1200089668901937312/1204285380095119390 を見てやり方を理解して自分で実装
- 再帰の深さは今回は高々4000。フレームサイズは、引数(8*2) + ローカル変数(8) + 戻り値アドレス(8) + 戻り値(8) + ベースポインタ(8) = 48B。
なので、スタックサイズは 2000 * 48B ≒ 100KB。Goランタイムのスタックサイズ1GBなら大丈夫
- 参照透過性を意識して、全て新しくノードを作る
- 時間計算量：O(n1 + n2)
- 空間計算量：O(n1 + n2)	(1つのスタックフレームの大きさがO(1)で,最悪の場合n1+n2回の再帰が生じるので)

```Go
func mergeTrees(root1 *TreeNode, root2 *TreeNode) *TreeNode {
	if root1 == nil && root2 == nil {
		return nil
	}
	if root1 == nil {
		newNode := &TreeNode{Val: root2.Val}
		newNode.Left = mergeTrees(nil, root2.Left)
		newNode.Right = mergeTrees(nil, root2.Right)
		return newNode
	}
	if root2 == nil {
		newNode := &TreeNode{Val: root1.Val}
		newNode.Left = mergeTrees(root1.Left, nil)
		newNode.Right = mergeTrees(root1.Right, nil)
		return newNode
	}
	newNode := &TreeNode{Val: root1.Val + root2.Val}
	newNode.Left = mergeTrees(root1.Left, root2.Left)
	newNode.Right = mergeTrees(root1.Right, root2.Right)
	return newNode
}
```

### Step 2
#### 2a スタックDFS 弱参照透過性
- https://github.com/fhiyo/leetcode/pull/25/files#r1656461334
- スタックDFSで見ていく
- 参照透過性は守っているが、`mergeNodes`関数で`if node1 == nil { return node2 }`としているように、重なっていないノードはオリジナルのノードを使う。
つまり、答えの木は、Valを更新しないといけないノード（重なっているノード）は新しいノードを作り、それ以外は入力と共有している
- つまり、関数の参照透過性（同じ入力に対して関数を2回走らせて2回とも同じ結果を返すか）は守られているが、呼び出し元のどこかでオリジナルの木に変更が加えられると、`mergeTrees`の結果も変わる可能性がある

```Go
type nodesBeforeAndAfterMerge struct {
	node1, node2, mergedNode *TreeNode
}

func mergeTrees(root1 *TreeNode, root2 *TreeNode) *TreeNode {
	mergedRoot := mergeNodes(root1, root2)
	if root1 == nil || root2 == nil {
		return mergedRoot
	}
	stack := []nodesBeforeAndAfterMerge{{root1, root2, mergedRoot}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		node1, node2, mergedNode := top.node1, top.node2, top.mergedNode
		stack = stack[:len(stack)-1]
		mergedNode.Left = mergeNodes(node1.Left, node2.Left)
		if node1.Left != nil && node2.Left != nil {
			stack = append(stack, nodesBeforeAndAfterMerge{node1: node1.Left, node2: node2.Left, mergedNode: mergedNode.Left})
		}
		mergedNode.Right = mergeNodes(node1.Right, node2.Right)
		if node1.Right != nil && node2.Right != nil {
			stack = append(stack, nodesBeforeAndAfterMerge{node1: node1.Right, node2: node2.Right, mergedNode: mergedNode.Right})
		}
	}
	return mergedRoot
}

func mergeNodes(node1, node2 *TreeNode) *TreeNode {
	if node1 == nil && node2 == nil {
		return nil
	}
	if node1 == nil {
		return node2
	}
	if node2 == nil {
		return node1
	}
	return &TreeNode{Val: node1.Val + node2.Val}
}
```

#### 2b スタックDFS 強参照透過性
- 2aのコードの
	```Go
	func mergeNodes(node1, node2 *TreeNode) *TreeNode {
		...
		if node1 == nil {
			return node2
		}
	```
	だと、マージ後の木が入力の木と共有するノードができる場合があり、
	思わぬ挙動をしかねないので、マージ後の木と入力ははっきり分ける場合を実装。
- 結構実装に苦労した

```Go
type nodesBeforeAndAfterMerge struct {
	node1, node2, mergedNode *TreeNode
}

func mergeTrees(root1 *TreeNode, root2 *TreeNode) *TreeNode {
	mergedRoot := mergeNodes(root1, root2)
	if root1 == nil || root2 == nil {
		return mergedRoot
	}
	stack := []nodesBeforeAndAfterMerge{{root1, root2, mergedRoot}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		node1, node2, mergedNode := top.node1, top.node2, top.mergedNode
		stack = stack[:len(stack)-1]

		mergedNode.Left = mergeNodes(node1.Left, node2.Left)
		if node1.Left != nil && node2.Left != nil {
			stack = append(stack, nodesBeforeAndAfterMerge{node1: node1.Left, node2: node2.Left, mergedNode: mergedNode.Left})
		}
		mergedNode.Right = mergeNodes(node1.Right, node2.Right)
		if node1.Right != nil && node2.Right != nil {
			stack = append(stack, nodesBeforeAndAfterMerge{node1: node1.Right, node2: node2.Right, mergedNode: mergedNode.Right})
		}
	}
	return mergedRoot
}

func mergeNodes(node1, node2 *TreeNode) *TreeNode {
	if node1 == nil && node2 == nil {
		return nil
	}
	if node1 == nil {
		newNode := &TreeNode{}
		deepcopyDescendants(newNode, node2)
		return newNode
	}
	if node2 == nil {
		newNode := &TreeNode{Val: node1.Val}
		deepcopyDescendants(newNode, node1)
		return newNode
	}
	return &TreeNode{Val: node1.Val + node2.Val}
}

func deepcopyDescendants(dst, src *TreeNode) {
	dst.Val = src.Val
	stack := [][2]*TreeNode{{dst, src}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		topDst, topSrc := top[0], top[1]
		stack = stack[:len(stack)-1]

		if topSrc.Left != nil {
			topDst.Left = &TreeNode{Val: topSrc.Left.Val}
			stack = append(stack, [2]*TreeNode{topDst.Left, topSrc.Left})
		}
		if topSrc.Right != nil {
			topDst.Right = &TreeNode{Val: topSrc.Right.Val}
			stack = append(stack, [2]*TreeNode{topDst.Right, topSrc.Right})
		}
	}
}
```

### Step 3
- 最も簡潔に書ける再帰を採用

```Go
func mergeTrees(root1 *TreeNode, root2 *TreeNode) *TreeNode {
	if root1 == nil && root2 == nil {
		return nil
	}
	if root1 == nil {
		newNode := &TreeNode{Val: root2.Val}
		newNode.Left = mergeTrees(nil, root2.Left)
		newNode.Right = mergeTrees(nil, root2.Right)
		return newNode
	}
	if root2 == nil {
		newNode := &TreeNode{Val: root1.Val}
		newNode.Left = mergeTrees(root1.Left, nil)
		newNode.Right = mergeTrees(root1.Right, nil)
		return newNode
	}
	newNode := &TreeNode{Val: root1.Val + root2.Val}
	newNode.Left = mergeTrees(root1.Left, root2.Left)
	newNode.Right = mergeTrees(root1.Right, root2.Right)
	return newNode
}
```
