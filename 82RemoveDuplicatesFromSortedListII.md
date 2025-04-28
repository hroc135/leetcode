### Step 1
- かなり時間がかかってしまった
- ヘルパー関数を作った方が見やすそう

1. 一旦全てのノードを調べ、各値のノードの個数を配列に格納
2. 1.で重複を検知した部分を削除する。まずは、returnすべきheadの位置を探す。その次にhead以降を操作。

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    // count nodes that have same value
    sameValCnts := []int{}
    node := head
    var prevVal int
    for node != nil {
        if node == head || node.Val != prevVal {
            sameValCnts = append(sameValCnts, 1)
            prevVal = node.Val
        } else {
            sameValCnts[len(sameValCnts)-1]++
        }
        node = node.Next
    }

    // delete duplicate nodes
    node = head
    headFound := false
    for _, c := range sameValCnts {
        if !headFound { // search the head to return first
            if c == 1 {
                headFound = true
                node = head
                continue
            } else {
                for j := 0; j < c; j++ {
                    head = head.Next
                }
            }

        } else {
            if c == 1 {
                node = node.Next
            } else {
                for j := 0; j < c; j++ {
                    node.Next = node.Next.Next
                }
            }
        }
    }

    return head
}
```

### Step 2
- ヘルパー関数を作ってみやすくした
- 重複ノード部分のメモリを解放した

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    sameValCnts := countSameValueNode(head)
    node := head
    headFound := false
    for _, c := range sameValCnts {
        if !headFound {
            if c == 1 {
                headFound = true
                node = head
            } else {
                for i := 0; i < c; i++ {
                    tmp := head.Next
                    head = nil
                    head = tmp
                }
            }

        } else {
            if c == 1 {
                node = node.Next
            } else {
                for i := 0; i < c; i++ {
                    tmp := node.Next.Next
                    node.Next = nil
                    node.Next = tmp
                }
            }
        }
    }

    return head
}

func countSameValueNode(head *ListNode) []int {
    sameValCnts := []int{}
    node := head
    var prevVal int
    for node != nil {
        if node == head || node.Val != prevVal {
            sameValCnts = append(sameValCnts, 1)
            prevVal = node.Val
        } else {
            sameValCnts[len(sameValCnts)-1]++
        }
        node = node.Next
    }
    return sameValCnts
}
```

- 他の人の解答を見ていたら、headの前にダミーノードを付け加えたらheadの位置を調べる部分とhead以降を調べる部分に分けずに済むと知り、実装してみた
- 同じ値のノードの個数をマップで管理する方針に変えたが、この方が読み手にとってわかりやすそう
- コードがかなりスッキリした印象

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    valCounter := make(map[int]int) // {nodevalue: occurrence}
    node := head
    for node != nil {
        if _, exist := valCounter[node.Val]; exist {
            valCounter[node.Val]++
        } else {
            valCounter[node.Val] = 1
        }
        node = node.Next
    }

    dummy := &ListNode{Val: -110, Next: head}
    node = dummy
    for node.Next != nil {
        if valCounter[node.Next.Val] > 1 {
            node.Next = node.Next.Next
        } else {
            node = node.Next
        }
    }
    return dummy.Next
}
```

### Step 3
- これで落ち着いたというコード
- 同じ値のノードの数を数えるマップの名前はvalCounterに変更

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    valCounter := make(map[int]int) // {nodevalue: occurrence}
    node := head
    for node != nil {
        if _, exist := valCounter[node.Val]; exist {
            valCounter[node.Val]++
        } else {
            valCounter[node.Val] = 1
        }
        node = node.Next
    }

    dummy := &ListNode{Val: -200, Next: head}
    node = dummy
    for node.Next != nil {
        if valCounter[node.Next.Val] > 1 {
            node.Next = node.Next.Next
        } else {
            node = node.Next
        }
    }
    return dummy.Next
}
```
