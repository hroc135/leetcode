### Step 4
- ハッシュマップの値はstruct{}にした
- すんなり解けた

```Go
func hasCycle(head *ListNode) bool {
    visited := make(map[*ListNode]struct{})
    for head != nil {
        if _, exist := visited[head]; exist {
            return true
        }
        visited[head] = struct{}{}
        head = head.Next
    }
    return false
}
```
