```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
```

### Step 1
- スタックに入れて取り出していく方法を真っ先に思いついた
- バブルソートのように後ろにswapしていく方法も思いついたが、O(n^2)になりそうだったのでやめておいた
- goの場合は標準でスタックがなく、popの作業が面倒なので、尻から取り出していくときは単に逆からインデックスでアクセスしていった

```Go
func reverseList(head *ListNode) *ListNode {
    nodes := []*ListNode{}
    sentinel := head
    for sentinel != nil {
        nodes = append(nodes, sentinel)
        sentinel = sentinel.Next
    }

    l := len(nodes)
    if l == 0 {
        return nil
    }

    newHead := nodes[l-1]
    sentinel = newHead
    for i := 1; i < l; i++ {
        sentinel.Next = nodes[l-i-1]
        sentinel.Next.Next = nil
        sentinel = sentinel.Next
    }

    return newHead
}
```

### Step 2
- わざわざスタックに溜めず、単に矢印を付け替えていく方法を試してみた
- in-placeででき、時間計算量はstep1と同じO(n)なので性能としてはこっちの方が良い

```Go
func reverseList(head *ListNode) *ListNode {
    var prev *ListNode = nil
    current := head
    for current != nil {
        next := current.Next
        current.Next = prev
        prev = current
        current = next
    }
    return prev
}
```

- 再帰を使ったやり方もdiscordで見かけたので試してみることに
- 想像以上にエレガントな解法が出来上がった

```Go
func reverseList(head *ListNode) *ListNode {
    return reverseListRecursive(head, nil)
}

func reverseListRecursive(current, previous *ListNode) *ListNode {
    if current == nil {
        return previous
    }
    preserved := current.Next
    current.Next = previous
    return reverseListRecursive(preserved, current)
}
```

### Step 3
- ファイナルアンサーは性能が良く、発想も自然なiterativeな方法

```Go
func reverseList(head *ListNode) *ListNode {
    var previous, current *ListNode = nil, head
    for current != nil {
        tmp := current.Next
        current.Next = previous
        previous, current = current, tmp
    }
    return previous
}
```

- 再帰でももう一度解いてみた
- 再帰のヘルパー関数の命名はいつも悩む、、。
  - 今回は一つ一つの矢印の向きを逆にしていくという意味でreverseArrowとしたが、単にhelperだとまずいのだろうか
  - googleのスタイルガイドには特に記載なし

```Go
func reverseList(head *ListNode) *ListNode {
    var reverseArrow func(*ListNode, *ListNode) *ListNode
    reverseArrow = func(current, previous *ListNode) *ListNode {
        if current == nil {
            return previous
        }

        next := current.Next
        current.Next = previous
        return reverseArrow(next, current)
    }
    return reverseArrow(head, nil)
}
```
