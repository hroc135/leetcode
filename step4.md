### Step 4
- ヒープ
- 修正点
  - `numFrequency`構造体のフィールドは、広い行数に渡って使用されるので省略しすぎない

```Go
type numFrequency struct {
	num       int
	frequency int
}

type numFrequencyHeap []numFrequency

func (h numFrequencyHeap) Len() int           { return len(h) }
func (h numFrequencyHeap) Less(i, j int) bool { return h[i].frequency < h[j].frequency }
func (h numFrequencyHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }

func (h *numFrequencyHeap) Push(x any) {
	*h = append(*h, x.(numFrequency))
}

func (h *numFrequencyHeap) Pop() any {
	l := len(*h)
	min := (*h)[l-1]
	*h = (*h)[:l-1]
	return min
}

func (h numFrequencyHeap) top() (numFrequency, error) {
	if h.Len() == 0 {
		return numFrequency{num: 0, frequency: 0}, errors.New("Empty heap")
	}
	return h[0], nil
}

func topKFrequent(nums []int, k int) []int {
	numToFrequency := make(map[int]int)
	for _, n := range nums {
		numToFrequency[n]++
	}

	h := &numFrequencyHeap{}
	heap.Init(h)

	for n, freq := range numToFrequency {
		top, _ := h.top()
		if h.Len() == k && freq <= top.frequency {
			continue
		}

		heap.Push(h, numFrequency{num: n, frequency: freq})
		if h.Len() > k {
			heap.Pop(h)
		}
	}

	ans := make([]int, 0, k)
	for h.Len() > 0 {
		top := heap.Pop(h).(numFrequency)
		fmt.Println(top)
		ans = append(ans, top.num)
	}

	return ans
}
```

- バケットソート

```Go
func topKFrequent(nums []int, k int) []int {
	numToFrequency := make(map[int]int)
	maxFrequency := 0
	for _, n := range nums {
		numToFrequency[n]++
		maxFrequency = max(maxFrequency, numToFrequency[n])
	}

	numFreqBuckets := make([][]int, maxFrequency+1)
	for n, freq := range numToFrequency {
		numFreqBuckets[freq] = append(numFreqBuckets[freq], n)
	}

	ans := make([]int, 0, k)
	for i := len(numFreqBuckets) - 1; i >= 0; i-- {
		if len(numFreqBuckets[i]) == 0 {
			continue
		}

		ans = append(ans, numFreqBuckets[i]...)
		if len(ans) == k {
			break
		}
	}

	return ans
}
```
