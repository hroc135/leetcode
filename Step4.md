### Step 4
- Step3からかなり修正した
- 同じ処理が続いていた部分を関数化した（getVal関数、moveNode関数）
- 繰り上げを0,1の自然数として変数に格納した。
ただし、0 or 1を保証できるように、enumぽいことをした。Goにはenumがないので初見だと気持ち悪い書き方になってしまうのが難点。
普通はiotaを使うが、わかりにくいので=0, =1とした。型名carryUp、中身dont, do、変数名cu、これでいいのだろうか、、
- enumの準備、関数の準備 -> ダミーノードやフラグの準備 -> コア部分（ループ）という順番で書いた

```Go
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    type carryUp int
    const (
        dont carryUp = 0
        do  carryUp = 1
    )

    getVal := func(node *ListNode) int {
        if node == nil {
            return 0
        }
        return node.Val
    }

    moveNode := func(node *ListNode) *ListNode {
        if node == nil {
            return node
        }
        return node.Next
    }
    
    dummy := &ListNode{Val: -1, Next: nil}
    added := dummy    
    var cu carryUp = dont

    for l1 != nil || l2 != nil || cu == do {
        sum := getVal(l1) + getVal(l2) + int(cu)
        cu = dont
        if sum >= 10 {
            sum %= 10
            cu = do
        }
        added.Next = &ListNode{Val: sum, Next: nil}
        added = added.Next
        l1, l2 = moveNode(l1), moveNode(l2)
    }

    return dummy.Next
}
```
