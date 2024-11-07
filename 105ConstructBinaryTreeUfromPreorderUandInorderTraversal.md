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
- 性質:
    - preorder[0]は根
    - inorderの中で、根のインデックスより左の要素は左サブツリー、
    右の要素は右サブツリーを構成する
    - preorder[1:]は前からa個の要素が左サブツリーの要素、
    後ろからb個の要素が右サブツリーの要素。
    aは左サブツリーの要素数。bは右
- アルゴリズム: preorder[0] は根となる。
inorder は preorder[0] の位置する場所をpivotとして左右のサブツリーノードに分割する。
preorderの方は、preorder[1:a+1], preorder[a+1:]で左右に分割できる。aは左サブツリーの要素数
- 気にしたこと
    - "preorder and inorder consist of unique values"
        - この条件がないと、二分木が一意に定まらない
    - "Each value of inorder also appears in preorder"
    とか preorder, inorder の正しさとか、
    そもそもどういう時にこの問題みたいな場面が生まれるのか？
    いろいろ気になってしまった
    - 手元で実験したところ、preorder が決まっていたら、
    preorder をランダムにシャッフルして inorder を生成すると、
    二分木を構築できる時とできない時がある
    - 今回のbuildTreeの前の流れはこんな感じ？
        - ある場所に二分木がある。
        これを別のメモリを共有していない場所へ送りたい。
        なので二分木を構築できるヒントとしてpreorderとinorderを調べ、配列として送る。
        受け取り先でbuildTree関数を読んで元の二分木を再構築
    - ということは二分木を生成できない場合(preorderとinorderのいずれかが間違っていた場合)を検知できたほうがいい？
- n: 木の要素数
    - 再帰の深さ: log n。最悪の場合、木が直線だとn
    - 時間計算量: O(n^2)
        - slices.Index -> O(n), buildTreeがn回呼ばれる
    - 空間計算量: O(nlogn)
        - スタックフレームがlogn個積まれ、
        一つのスタックフレームの大きさは引数の大きさよりO(n)だから

```Go
func buildTree(preorder []int, inorder []int) *TreeNode {
	if len(preorder) == 0 {
		return nil
	}
	rootValue := preorder[0]
	root := &TreeNode{Val: rootValue}
	inorderRootIndex := slices.Index(inorder, rootValue)
	leftSubtreeNodeCount := inorderRootIndex
	root.Left = buildTree(preorder[1:leftSubtreeNodeCount+1], inorder[:inorderRootIndex])
	root.Right = buildTree(preorder[leftSubtreeNodeCount+1:], inorder[inorderRootIndex+1:])
	return root
}
```

### Step 2
#### 2a
