### Step 4
- iterativeな方法はすぐに解けたが、再帰は何度か不正答を繰り返してしまった。もう少し練習が必要。

iterative
```Go
func deleteDuplicates(head *ListNode) *ListNode {
    node := head
    for node != nil && node.Next != nil {
        if node.Val == node.Next.Val {
            node.Next = node.Next.Next
            continue
        }
        node = node.Next
    }
    return head
}
```

再帰
```Go
func deleteDuplicates(head *ListNode) *ListNode {
    if head == nil {
        return nil
    } else if head.Next == nil {
        return head
    }

    if head.Val == head.Next.Val {
        head.Next = head.Next.Next
        _ = deleteDuplicates(head)
    } else {
        _ = deleteDuplicates(head.Next)
    }

    return head
}
```
