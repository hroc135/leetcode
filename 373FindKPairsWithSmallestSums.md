### Step 1
- ぱっと思いついた方法は、すべてのペアを生成し、各合計値を元にソートして最初のk個を取り出す方法。
- しかし、いかにも時間制限を超えそうなので他の方法を考えることにする
- ヒープを使えば多少マシになる？
- ただし、n^2通りのペアについて考えることに変わりはないのでそこまで改善されていない気はしつつも、とりあえず実装してみる

```Go
type pair struct {
    pair [2]int
    sum int
}

type pairSumMaxHeap []pair

func (h pairSumMaxHeap) Len() int { return len(h) }
func (h pairSumMaxHeap) Less(i, j int) bool { return h[i].sum > h[j].sum } // max heap
func (h pairSumMaxHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *pairSumMaxHeap) Push(x any) { *h = append(*h, x.(pair)) }

func (h *pairSumMaxHeap) Pop() any {
    n := len(*h)
    max := (*h)[n-1]
    *h = (*h)[:n-1]
    return max
}

func (h pairSumMaxHeap) topSum() int { return h[0].sum }

func kSmallestPairs(nums1 []int, nums2 []int, k int) [][]int {
    h := &pairSumMaxHeap{}
    for _, n1 := range nums1 {
        for _, n2 := range nums2 {
            sum := n1 + n2
            // not sure if it's okay to do >= because I'm not sure if I have to distinguish [1,1] and [0,2]
            if h.Len() == k && sum >= h.topSum() {
                continue
            }
            p := pair{pair: [2]int{n1, n2}, sum: sum}
            heap.Push(h, p)
            if h.Len() > k {
                heap.Pop(h)
            }
        }
    }
    kSmallestSums := [][]int{}
    for i := 0; i < k; i++ {
        p := heap.Pop(h).(pair)
        pairSlice := p.pair[:]  // p.pair is an array of len 2
        kSmallestSums = append(kSmallestSums, pairSlice)
    }
    return kSmallestSums
}
```

- 案の定時間制限超え。「これ以上は調べなくても良い」という条件を探す必要がありそう
- nums1とnums2が昇順ソートされていることを利用し、合計値がヒープの根の値より大きくなったら2重ループの内側を出るようにしたら通った
- 外側のループも出れる条件を考えたが、nums2[i]がそれぞれ負の値を取りうるので出来なさそう

```Go
type pair struct {
    pair [2]int
    sum int
}

type pairSumMaxHeap []pair

func (h pairSumMaxHeap) Len() int { return len(h) }
func (h pairSumMaxHeap) Less(i, j int) bool { return h[i].sum > h[j].sum } // max heap
func (h pairSumMaxHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *pairSumMaxHeap) Push(x any) { *h = append(*h, x.(pair)) }

func (h *pairSumMaxHeap) Pop() any {
    n := len(*h)
    max := (*h)[n-1]
    *h = (*h)[:n-1]
    return max
}

func (h pairSumMaxHeap) topSum() int { return h[0].sum }

func kSmallestPairs(nums1 []int, nums2 []int, k int) [][]int {
    h := &pairSumMaxHeap{}
    for _, n1 := range nums1 {
        for _, n2 := range nums2 {
            sum := n1 + n2
            if h.Len() == k && sum >= h.topSum() {
                break
            }
            p := pair{pair: [2]int{n1, n2}, sum: sum}
            heap.Push(h, p)
            if h.Len() > k {
                heap.Pop(h)
            }
        }
    }
    kSmallestSums := [][]int{}
    for i := 0; i < k; i++ {
        p := heap.Pop(h).(pair)
        pairSlice := p.pair[:]  // p.pair is an array of len 2
        kSmallestSums = append(kSmallestSums, pairSlice)
    }
    return kSmallestSums
}
```

### Step 2
```Go
// Implement heap.Interface
type pair struct {
    elems [2]int  // [nums1 elem, nums2 elem]
    sum int
}

type pairSumMaxHeap []pair

func (h pairSumMaxHeap) Len() int { return len(h) }
func (h pairSumMaxHeap) Less(i, j int) bool { return h[i].sum > h[j].sum }
func (h pairSumMaxHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *pairSumMaxHeap) Push(x any) { *h = append(*h, x.(pair)) }

func (h *pairSumMaxHeap) Pop() any {
    n := len(*h)
    max := (*h)[n-1]
    *h = (*h)[:n-1]
    return max
}

func (h pairSumMaxHeap) top() pair { return h[0] }

// Solution
func kSmallestPairs(nums1 []int, nums2 []int, k int) [][]int {
    h := &pairSumMaxHeap{}

    for _, n1 := range nums1 {
        for _, n2 := range nums2 {
            sum := n1 + n2
            if h.Len() == k && sum >= h.top().sum {
                break
            }
            heap.Push(h, pair{elems: [2]int{n1, n2}, sum: sum})
            if h.Len() > k {
                heap.Pop(h)
            }
        }
    }

    kSmallestSumPairs := [][]int{}
    for i := 0; i < k; i++ {
        pairRaw := heap.Pop(h).(pair)
        e := pairRaw.elems[:]
        kSmallestSumPairs = append(kSmallestSumPairs, e)
    }
    return kSmallestSumPairs
}
```

- テーブルを使って下と右に攻めていく方法があるらしいとDiscordで知り、試してみた（集合を使わないver）
- 理解にかなり苦しんだ
- 参照
  - https://github.com/TORUS0818/leetcode/pull/12/commits/09636a11c0c084c245f82bb029f198c2d0966455?short_path=12341a7#diff-12341a70069caa7ec44aba610c42a0123605c2680c11a88728158764788bead7

```Go
// Implement heap.Interface
type pair struct {
    sum int
    row int
    col int
}

type pairSumMinHeap []pair

func (h pairSumMinHeap) Len() int { return len(h) }
func (h pairSumMinHeap) Less(i, j int) bool { return h[i].sum < h[j].sum }
func (h pairSumMinHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *pairSumMinHeap) Push(x any) { *h = append(*h, x.(pair)) }

func (h *pairSumMinHeap) Pop() any {
    n := len(*h)
    min := (*h)[n-1]
    *h = (*h)[:n-1]
    return min
}

// Solution
func kSmallestPairs(nums1 []int, nums2 []int, k int) [][]int {
    minPair := pair{sum: nums1[0] + nums2[0], row: 0, col: 0}
    h := &pairSumMinHeap{minPair}

    l1, l2 := len(nums1), len(nums2)
    nextRows, nextCols := make([]int, l2), make([]int, l1)
    
    kSmallestPairs := [][]int{}

    for len(kSmallestPairs) < k {
        top := heap.Pop(h).(pair)
        kSmallestPairs = append(kSmallestPairs, []int{nums1[top.row], nums2[top.col]})
        nextRows[top.col]++
        nextCols[top.row]++

        if top.row + 1 < l1 && top.col == nextCols[top.row+1] {
            p := pair{sum: nums1[top.row + 1] + nums2[top.col], row: top.row + 1, col: top.col}
            heap.Push(h, p)
        }
        if top.col + 1 < l2 && top.row == nextRows[top.col+1] {
            p := pair{sum: nums1[top.row] + nums2[top.col + 1], row: top.row, col: top.col + 1}
            heap.Push(h, p)
        }
    }

    return kSmallestPairs
}
```

### Step 3
- 最終的に落ち着いたコード

```Go
// Implement heap.Interface
type pair struct {
    sum int
    idx1 int
    idx2 int
}

type pairSumMinHeap []pair

func (h pairSumMinHeap) Len() int { return len(h) }
func (h pairSumMinHeap) Less(i, j int) bool { return h[i].sum < h[j].sum }
func (h pairSumMinHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *pairSumMinHeap) Push(x any) { *h = append(*h, x.(pair)) }

func (h *pairSumMinHeap) Pop() any {
    n := len(*h)
    min := (*h)[n-1]
    *h = (*h)[:n-1]
    return min
}

func kSmallestPairs(nums1 []int, nums2 []int, k int) [][]int {
    min := pair{sum: nums1[0] + nums2[0], idx1: 0, idx2: 0}
    h := &pairSumMinHeap{min}

    l1, l2 := len(nums1), len(nums2)
    nextIdx2ForNums1, nextIdx1ForNums2 := make([]int, l1), make([]int, l2)

    kSmallestPairs := [][]int{}

    for len(kSmallestPairs) < k {
        top := heap.Pop(h).(pair)
        kSmallestPairs = append(kSmallestPairs, []int{nums1[top.idx1], nums2[top.idx2]})
        nextIdx2ForNums1[top.idx1]++
        nextIdx1ForNums2[top.idx2]++

        if top.idx1 + 1 < l1 && top.idx2 == nextIdx2ForNums1[top.idx1 + 1] {
            p := pair{
                sum: nums1[top.idx1 + 1] + nums2[top.idx2],
                idx1: top.idx1 + 1,
                idx2: top.idx2,
            }
            heap.Push(h, p)
        }
        if top.idx2 + 1 < l2 && top.idx1 == nextIdx1ForNums2[top.idx2 + 1] {
            p := pair{
                sum: nums1[top.idx1] + nums2[top.idx2 + 1],
                idx1: top.idx1,
                idx2: top.idx2 + 1,
            }
            heap.Push(h, p)
        }
    }
    return kSmallestPairs
}
```
