### Step 1
- hash tableに訪れたノードを記憶させて逐一参照する方針
- 最初はループの始まるノードのインデックスを返すと勘違いしてリジェクトされた。I/Oを最初に確認することは基本中の基本
- 使用メモリがO(n)になっているので、O(1)でできる方法を考える

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func detectCycle(head *ListNode) *ListNode {
    visited := make(map[*ListNode]bool)
    for head != nil {
        if _, exist := visited[head]; exist {
            return head
        }
        visited[head] = true
        head = head.Next
    }
    return nil
}
```

### Step 2
- https://leetcode.com/problems/linked-list-cycle-ii/solutions/1701128/c-java-python-slow-and-fast-image-explanation-beginner-friendly/
- 上記リンクを参考にしてtortoise and hareでメモリ使用量がO(1)となるように実装
- パフォーマンス的にはこちらの方が良いが、数学的説明が必要なのでパフォーマンスクリティカルな部分でないなら使いたくない

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func detectCycle(head *ListNode) *ListNode {
    slowPtr, fastPtr := head, head

    // check if there exists a cycle
    for {
        if fastPtr == nil || fastPtr.Next == nil {
            return nil
        }
        slowPtr = slowPtr.Next
        fastPtr = fastPtr.Next.Next
        if slowPtr == fastPtr {
            break
        }
    }

    for {
        if slowPtr == head {
            return slowPtr
        }
        slowPtr = slowPtr.Next
        head = head.Next
    }
}
```

### Step 3
- いつもGoで集合みたいなものを実装するときに悩むのがmapのvalueをどうしようかというところ
- 今回はvoidというデータ型を作り、emptyというvoid型の変数を作った

```Go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */

type void struct {}
var empty void

func detectCycle(head *ListNode) *ListNode {
    visited := make(map[*ListNode]void)
    for head != nil {
        if _, exist := visited[head]; exist {
            return head
        }
        visited[head] = empty
        head = head.Next
    }
    return nil
}
```
