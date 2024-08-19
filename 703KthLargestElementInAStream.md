```Go
/**
 * Your KthLargest object will be instantiated and called as such:
 * obj := Constructor(k, nums);
 * param_1 := obj.Add(val);
 */
```

### Step 1
- 真っ先に思いついた解法は、numsを常にソート済み配列としておき、最後からk番目のインデックスにアクセスする方法。
- Go 1.22以降、`sort.Ints`は単に`slices.Sort`を呼び出すらしい
  - `slices.Sort`は2021年に論文で発表されたPattern-defeating Quicksortというアルゴリズムを使っているらしい
    - pdqsortがquicksortより優れている点は、最短O(n)でソートできる点。O(n)でできるのは、最初からソートされている場合と、ソートされている配列に一番最後にソートされていない要素が置かれているとき。
なので今回のAddでのソートはO(n)でできている
    - https://arxiv.org/pdf/2106.05123
    - https://github.com/orlp/pdqsort

```Go
type KthLargest struct {
    k int
    nums []int
}

func Constructor(k int, nums []int) KthLargest {
    sort.Ints(nums)
    return KthLargest{k: k, nums: nums}
}

func (this *KthLargest) Add(val int) int {
    this.nums = append(this.nums, val)
    sort.Ints(this.nums)
    return this.nums[len(this.nums) - this.k]
}
```

### Step 2
- まずはStep1の解答をブラッシュアップしてみる
- numsが長さk以上の時は、k以下の部分を捨てると無駄な処理をしなくて済む
- Step1では単に新しい値をappendしてからソートしていたが、`slices.BinarySearch`を使うことによって計算量を削減
- パフォーマンスはStep1より格段に上がったが、可読性が犠牲になったような気がする、、。this.numsの長さがkと等しくなったりならなかったりすることが可読性低下の原因のような気がする
- 参照
  - https://github.com/seal-azarashi/leetcode/pull/8/files

```Go
type KthLargest struct {
    k int
    nums []int
}

func Constructor(k int, nums []int) KthLargest {
    slices.Sort(nums)
    return KthLargest{k: k, nums: nums}
}

func (this *KthLargest) Add(val int) int {
    if len(this.nums) > this.k {
        this.nums = this.nums[len(this.nums) - this.k :]
    }
    if len(this.nums) == this.k && val <= this.nums[0] {
        return this.nums[0]
    }
    insertIdx, _ := slices.BinarySearch(this.nums, val)
    this.nums = slices.Insert(this.nums, insertIdx, val)
    return this.nums[len(this.nums) - this.k]
}
```

- ということでlen(this.nums)が常にkになるようにした

```Go
type KthLargest struct {
    k int
    nums []int
}

func Constructor(k int, nums []int) KthLargest {
    slices.Sort(nums)
    reduceNumsLenToK(&nums, k)
    return KthLargest{k: k, nums: nums}
}

func (this *KthLargest) Add(val int) int {
    if len(this.nums) == this.k && val <= this.nums[0] {
        return this.nums[0]
    }
    insertIdx, _ := slices.BinarySearch(this.nums, val)
    this.nums = slices.Insert(this.nums, insertIdx, val)
    reduceNumsLenToK(&this.nums, this.k)
    return this.nums[0]
}

func reduceNumsLenToK(nums *[]int, k int) {
    n := len(*nums)
    if n > k {
        *nums = (*nums)[n - k :]
    }
}
```

- Discordで他の人の解答を見ていたら、ヒープをエレガントに使っていたので自分も実装してみた
- 中身は他の方々と同じ。追加したい値がtopよりも小さかったら追加しない部分も実装。
- ヒープの前準備が面倒で仕様を理解するのに時間がかかってしまったが、理解してみればなんだそういうことかという感じ
- heapのソースコードも見てみた。sortと密接に結びついていたのでついでにsortの方も読んでみた
  - https://cs.opensource.google/go/go/+/refs/tags/go1.22.5:src/container/heap/heap.go
  - https://cs.opensource.google/go/go/+/refs/tags/go1.22.5:src/slices/sort.go

```Go
// make heap.Interface
// https://pkg.go.dev/container/heap#Interface
type intHeap []int

func (h intHeap) Len() int { return len(h) }
func (h intHeap) Less(i, j int) bool { return h[i] < h[j] }
func (h intHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *intHeap) Push(x any) {
    *h = append(*h, x.(int))
}

func (h *intHeap) Pop() any {
    n := len(*h)
    min := (*h)[n-1]
    *h = (*h)[:n-1]
    return min
}

func (h intHeap) top() int {
    return h[0]
}

// KthLargest
type KthLargest struct {
    k int
    nums intHeap
}

func Constructor(k int, nums []int) KthLargest {
    h := &intHeap{}
    for _, n := range nums {
        if h.Len() >= k && n <= h.top() {
            continue
        }
        heap.Push(h, n)
        if h.Len() > k {
            heap.Pop(h)
        }
    }
    return KthLargest{k: k, nums: *h}
}

func (this *KthLargest) Add(val int) int {
    if this.nums.Len() >= this.k && val <= this.nums.top() {
        return this.nums.top()
    }
    heap.Push(&this.nums, val)
    if this.nums.Len() > this.k {
        heap.Pop(&this.nums)
    }
    return this.nums.top()
}
```

- Discordを見ているとクイックセレクトというアルゴリズムもあるらしいが、なかなかプルリクを出せていなかったので、一旦Step3に進むことにした

### Step 3
- 一旦今までの解法を整理する
- step1の配列をソートする方法
  - Constructor: O(n0 logn0)時間 (n0: 初期のnumsの要素数)
  - Add: O(n)時間 (pdqsortのおかげ)
- step2の配列を常に長さk以下に抑える方法
  - Constructor: O(n0 logn0)時間
  - Add: O(logk + k) = O(k)時間
- ヒープを使う方法
  - Constructor: O(n0 logk)時間
  - Add: O(logk)時間
- 空間計算量はいずれもin-placeで実現できているので、O(n) or O(k)
- ということでヒープを使った方が最もパフォーマンスが良いし、ヒープはSEの常識に入ると思うので、ヒープでやるのが一番良さそう

```Go
// Prepare heap.Interface
type intHeap []int

func (h intHeap) Len() int { return len(h) }
func (h intHeap) Less(i, j int) bool { return h[i] < h[j] }
func (h intHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *intHeap) Push(x any) { *h = append(*h, x.(int)) }

func (h *intHeap) Pop() any {
    n := len(*h)
    min := (*h)[n-1]
    *h = (*h)[:n-1]
    return min
}

func (h intHeap) top() int { return h[0] }

// Solution for the problem
type KthLargest struct {
    k int
    nums intHeap
}

func Constructor(k int, nums []int) KthLargest {
    numsHeap := &intHeap{}
    for _, num := range nums {
        if (*numsHeap).Len() == k && num < (*numsHeap).top() {
            continue
        }
        heap.Push(numsHeap, num)
        if numsHeap.Len() > k {
            heap.Pop(numsHeap)
        }
    }
    return KthLargest{k: k, nums: *numsHeap}
}

func (this *KthLargest) Add(val int) int {
    if this.nums.Len() == this.k && val < this.nums.top() {
        return this.nums.top()
    }
    heap.Push(&this.nums, val)
    if this.nums.Len() > this.k {
        heap.Pop(&this.nums)
    }
    return this.nums.top()
}
```
