### Step 4
- ハッシュマップの値はstruct{}にした

```Go
func detectCycle(head *ListNode) *ListNode {
    visited := make(map[*ListNode]struct{})
    for head != nil {
        if _, exist := visited[head]; exist {
            return head
        }
        visited[head] = struct{}{}
        head = head.Next
    }
    return nil
}
```
