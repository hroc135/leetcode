### Step 1
- ポインタの矢印の先を変えるか矢印の元を変えるか悩み、時間がかかってしまった
- 今まで苦手だったポインタの扱いにだいぶ慣れてきた気がする

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    currentNode := head
    for currentNode != nil && currentNode.Next != nil {
        if currentNode.Val == currentNode.Next.Val {
            currentNode.Next = currentNode.Next.Next
        } else {
            currentNode = currentNode.Next
        }
    }
    return head
}
```

### Step 2
- Discordを見ていたら再起でもできそうということでやろうとしてみたが、なかなかうまくいかず、他の人のコードを見た。再起苦手、、
- ちなみにGoのstackは無限らしい（https://dave.cheney.net/2013/06/02/why-is-a-goroutines-stack-infinite）

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    if head == nil || head.Next == nil {
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

- 同じ数字が3個以上連続するときにいちいちcurrentを動かさないverも実装
- 実際の時間計算量はO(n)だが、O(n^2)に見えるのがなんとなく嫌

```Go
func deleteDuplicates(head *ListNode) *ListNode {
    current := head
    for current != nil && current.Next != nil {
        for current.Next != nil && current.Val == current.Next.Val {
            current.Next = current.Next.Next
        }
        current = current.Next
    }
    return head
}
```

### Step 3
- 結局これに落ち着いたというコード

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func deleteDuplicates(head *ListNode) *ListNode {
    current := head
    for current != nil && current.Next != nil {
        if current.Val == current.Next.Val {
            current.Next = current.Next.Next
        } else {
            current = current.Next
        }
    }
    return head
}
```

