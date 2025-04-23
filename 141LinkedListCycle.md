### Step 1
- Tortoise and Hare methodを使うという方針はすぐに思いついたものの、実装力不足を感じた。
- 以下、通らなかったコード。fastがnilかもしれないのにfast.Nextにアクセスしようとしており、inputが[]のときにpanicになる。

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func hasCycle(head *ListNode) bool {
    slow, fast := head, head
    for {
        if fast.Next == nil {
            return false
        }

        if slow == fast {
            return true
        }     

        slow = slow.Next
        fast = fast.Next.Next   
    }
}
```

### Step 2
- slow, fastという名前が変数名として微妙だと思い、slow pointerという意味でslowPtrとした（fastも同様）。
- ループの中でtrue/false両方を判定するのではなく、falseの（閉路が存在しない）場合にループを抜け出すようにした。

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func hasCycle(head *ListNode) bool {
    slowPtr, fastPtr := head, head
    for fastPtr != nil && fastPtr.Next != nil {
        slowPtr = slowPtr.Next
        fastPtr = fastPtr.Next.Next
        if slowPtr == fastPtr {
            return true
        }
    }
    return false
}
```

### Step 3
- 以下のページを参考にGoのポインタについて復習。手を動かしながら読んだので前より理解が深まった。
https://medium.com/@jamal.kaksouri/a-comprehensive-guide-to-pointers-in-go-4acc58eb1f4d

