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
- 方針はすぐに定まったが、l1とl2の長さが異なる時の処理と繰上げの処理に手こずった
- 先頭から一個一個足してノードを生成し、繋げていく方針。
- 「うわー、冗長すぎー」というコードが誕生した。Step2で改善していく。

```Go
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    dummy := &ListNode{Val: -1, Next: nil}
    addedNode := dummy
    carryUpFlag := false
    for l1 != nil && l2 != nil {
        s := l1.Val + l2.Val

        if carryUpFlag {
            s++
            carryUpFlag = false
        }

        if s >= 10 {
            carryUpFlag = true
            s %= 10
        }

        addedNode.Next = &ListNode{s, nil}
        addedNode = addedNode.Next
        l1, l2 = l1.Next, l2.Next
    }

    for l1 != nil {
        if carryUpFlag {
            l1.Val++
            carryUpFlag = false
        }

        if l1.Val >= 10 {
            carryUpFlag = true
            l1.Val %= 10
        }
        addedNode.Next = &ListNode{l1.Val, nil}
        addedNode = addedNode.Next
        l1 = l1.Next
    }

    for l2 != nil {
        if carryUpFlag {
            l2.Val++
            carryUpFlag = false
        }

        if l2.Val >= 10 {
            carryUpFlag = true
            l2.Val %= 10
        }
        addedNode.Next = &ListNode{l2.Val, nil}
        addedNode = addedNode.Next
        l2 = l2.Next
    }

    if carryUpFlag {
        addedNode.Next = &ListNode{1, nil}
    }

    return dummy.Next
}
```

### Step 2
- Step1の冗長さの原因は、1)l1もl2も桁が残っている場合、2)l1だけ桁が残っている場合、3)l2だけ桁が残っている場合、の3パターンのforループに分けてしまっていたこと。これを一つのループに収める。
- 最後にl1もl2も桁が残っていないが繰り上げが残っている場合の処理もループの中に組み込んだ。

```Go
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    dummy := &ListNode{Val: -1, Next: nil}
    addedNode := dummy
    carryUpFlag := false
    
    for l1 != nil || l2 != nil || carryUpFlag {
        s := 0
        if l1 != nil {
            s += l1.Val
            l1 = l1.Next
        }
        if l2 != nil {
            s += l2.Val
            l2 = l2.Next
        }

        if carryUpFlag {
            s++
            carryUpFlag = false
        }

        if s >= 10 {
            s %= 10
            carryUpFlag = true
        }

        addedNode.Next = &ListNode{s, nil}
        addedNode = addedNode.Next
    }

    return dummy.Next
}
```

- 再帰でも解いてみた。この問題ならわざわざ再帰でやらなくてもいいなというのが感想

```Go
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    dummy := &ListNode{Val: -1, Next: nil}
    addTwoNodes(dummy, l1, l2, false)
    return dummy.Next
}

func addTwoNodes(addedNode, l1, l2 *ListNode, carryUpFlag bool) {
    if l1 == nil && l2 == nil && !carryUpFlag {
        return
    }

    s := 0
    if l1 != nil {
        s += l1.Val
        l1 = l1.Next
    }
    
    if l2 != nil {
        s += l2.Val
        l2 = l2.Next
    }

    if carryUpFlag {
        s++
        carryUpFlag = false
    }

    if s >= 10 {
        s %= 10
        carryUpFlag = true
    }

    addedNode.Next = &ListNode{Val: s, Next: nil}
    addTwoNodes(addedNode.Next, l1, l2, carryUpFlag)
}
```

### Step 3
- addedNodeをaddedに変更。`added := dummy`から、`added`がノードであることを推測できるから。
- carryUpFlagをcarryUpに変更。`if carryUpFlag`より`if carryUp`の方が自然だと思った。

```Go
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    dummy := &ListNode{Val: -1, Next: nil}
    added := dummy
    carryUp := false

    for l1 != nil || l2 != nil || carryUp {
        s := 0
        if l1 != nil {
            s += l1.Val
            l1 = l1.Next
        }
        if l2 != nil {
            s += l2.Val
            l2 = l2.Next
        }

        if carryUp {
            s++
            carryUp = false
        }

        if s >= 10 {
            s %= 10
            carryUp = true
        }

        added.Next = &ListNode{Val: s, Next: nil}
        added = added.Next
    }

    return dummy.Next
}
```
