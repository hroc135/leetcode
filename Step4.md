### Step 4
- 1回のループで解く方法が一番楽で効率的
- `dummy := &ListNode{Val: -200, Next: head}`は-200に特別な意味があるように思われかねないので0にした
- duplicatedFlagという命名に点いて、bool型である時点でフラグかなという予測が立ってもおかしくないので、isDuplicatedに変更

```Go
func deleteDuplicates(head *ListNode) *ListNode {
    dummy := &ListNode{Val: 0, Next: head}
    node := dummy
    isDuplicated := false

    for node.Next != nil {
        if node.Next.Next != nil && node.Next.Val == node.Next.Next.Val {
            node.Next = node.Next.Next
            isDuplicated = true
        } else if isDuplicated {
            node.Next = node.Next.Next
            isDuplicated = false
        } else {
            node = node.Next
        }
    }

    return dummy.Next
}
```
