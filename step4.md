### Step 4
- container/heapのソースコードを見ながらヒープを自作してみた
- intのオーバーフローはアンテナを張って自分で可能性があることに気がつけるようになりたい

```Go
type intMinHeap []int

func (h intMinHeap) len() int { return len(h) }

func (h intMinHeap) swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *intMinHeap) push(n int) {
	*h = append(*h, n)
	i := len(*h) - 1
	for {
		j := (i - 1) / 2 // parent index
		if i == 0 || (*h)[i] >= (*h)[j] {
			break
		}

		h.swap(i, j)
		i = j
	}
}

func (h *intMinHeap) pop() (int, error) {
	if len(*h) == 0 {
		return 0, errors.New("Empty Heap")
	}

	size := len(*h)
	top := (*h)[0]
	h.swap(0, size-1)
	*h = (*h)[:size-1]

	i := 0
	for {
		j1 := 2*i + 1   // left child index
		if j1 >= size-1 || j1 < 0 {
			break
		}

		j := j1
		j2 := j1 + 1    // right child index
		if j2 < size-1 && (*h)[j2] < (*h)[j1] {
			j = j2
		}

		if (*h)[i] <= (*h)[j] {
			break
		}

		h.swap(i, j)
		i = j
	}

	return top, nil
}

func (h intMinHeap) top() int {
	return h[0]
}

type KthLargest struct {
	k    int
	nums intMinHeap
}

func Constructor(k int, nums []int) KthLargest {
	numsHeap := &intMinHeap{}
	for _, n := range nums {
		if numsHeap.len() == k && n <= numsHeap.top() {
			continue
		}

		numsHeap.push(n)
		if numsHeap.len() > k {
			numsHeap.pop()
		}
	}

	return KthLargest{k: k, nums: *numsHeap}
}

func (this *KthLargest) Add(val int) int {
	if this.nums.len() == this.k && val <= this.nums.top() {
		return this.nums.top()
	}

	this.nums.push(val)
	if this.nums.len() > this.k {
		this.nums.pop()
	}

	return this.nums.top()
}
```

- スライスをソートする方法も指摘を受けて再実装
- 修正箇所
  - ソートを降順にして、前からk番目の要素（下の実装の場合、末尾の要素）がk番目に大きい要素であるようにした
  - Add関数の中の、numsの要素数がkより大きかったらいらない部分を削る作業をappendした後にした
  - Add関数の中で、numsは書き換えられることがあるが、kはreadだけなのにthis.kが登場する場面が多くてコードも長くなってしまったので、
冒頭で`k = this.k`とした

```Go
type KthLargest struct {
    k int
    nums []int
}

func Constructor(k int, nums []int) KthLargest {
    slices.SortFunc(nums, func(a, b int) int {
        return -1 * cmp.Compare(a, b)
    })

    if len(nums) > k {
        nums = nums[:k]
    }

    return KthLargest{k: k, nums: nums}
}

func (this *KthLargest) Add(val int) int {
    k := this.k

    if len(this.nums) == k && val <= this.nums[k-1] {
        return this.nums[k-1]
    }

    this.nums = append(this.nums, val)
    slices.SortFunc(this.nums, func(a, b int) int {
        return -1 * cmp.Compare(a, b)
    })

    if len(this.nums) > k {
        this.nums = this.nums[:k]
    }
    
    return this.nums[k-1]
}
```
