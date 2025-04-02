```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
```

### Step 4
- 真っ先にiterativeな方法で解きたくなった
- 自分にとってはこれが一番自然な解法

```Go
func reverseList(head *ListNode) *ListNode {
    var previous *ListNode = nil
    current := head

    for current != nil {
        next := current.Next
        current.Next = previous
        previous, current = current, next
    }

    return previous
}
```

- recursiveな方法。後ろから付け替えていく場合。
- step2の再帰はiterativeっぽい発想になってしまっていたが、このやり方はよりrecursiveな感じがする
- しかもヘルパー関数を必要としない

```Go
func reverseList(head *ListNode) *ListNode {
    if head == nil || head.Next == nil {
        return head
    }

    newHead := reverseList(head.Next)
    head.Next.Next = head
    head.Next = nil

    return newHead
}
```
