### Step 1
- 最初に思いついたのはヒープを使う方法
  - numとその発生回数をマップに溜めた後、順にminヒープにpushしていく。ヒープのノード数は常にkで抑え、残ったものが最大頻度をもつk個の要素。
- ヒープのノード数を常にk以下に抑えるので、時間計算量はO(n logk)
  - 見積もり実行時間：10^5 * log 10^5 ≒ 10^6。これを1億で割って、10^-2 s = 10 ms。
  - よって、最悪のケースで10msかかるだろう。
  - 空間計算量はO(n)
- テストケースで細かいミスを修正した後に一発でACしたのは嬉しかった

```Go
type numCount struct {
    n int
    cnt int
}

type numCountMinHeap []numCount

func (h numCountMinHeap) Len() int { return len(h) }
func (h numCountMinHeap) Less(i, j int) bool { return h[i].cnt < h[j].cnt }
func (h numCountMinHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *numCountMinHeap) Push(x any) { *h = append(*h, x.(numCount)) }

func (h *numCountMinHeap) Pop() any {
    n := len(*h)
    min := (*h)[n-1]
    *h = (*h)[:n-1]
    return min
}

func (h numCountMinHeap) top() numCount { return h[0] }

func topKFrequent(nums []int, k int) []int {
    numCntHashMap := make(map[int]int)  // {num: cnt}
    for _, n := range nums {
        if _, exist := numCntHashMap[n]; exist {
            numCntHashMap[n]++
            continue
        }
        numCntHashMap[n] = 1
    }

    h := &numCountMinHeap{}
    for n, c := range numCntHashMap {
        if h.Len() == k && c <= h.top().cnt {
            continue
        }
        heap.Push(h, numCount{n: n, cnt: c})
        if h.Len() > k {
            heap.Pop(h)
        }
    }

    topKFrequentElems := []int{}
    for h.Len() > 0 {
        top := heap.Pop(h).(numCount)
        topKFrequentElems = append(topKFrequentElems, top.n)
    }

    return topKFrequentElems
}
```

### Step 2
- step1をブラッシュアップ
- Goのint型のデフォルト値（nil）が0であることを使い、最初のループの中の発生頻度を数える処理を簡潔にした
- 問題文ではfrequencyという単語が使われいたので、cntからfreqに変更した

```Go
type numFrequency struct {
    n int
    freq int
}

type numFreqMinHeap []numFrequency

func (h numFreqMinHeap) Len() int { return len(h) }
func (h numFreqMinHeap) Less(i, j int) bool { return h[i].freq < h[j].freq }
func (h numFreqMinHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }

func (h *numFreqMinHeap) Push(x any) { *h = append(*h, x.(numFrequency)) }

func (h *numFreqMinHeap) Pop() any {
    n := len(*h)
    min := (*h)[n-1]
    *h = (*h)[:n-1]
    return min
}

func (h numFreqMinHeap) top() numFrequency { return h[0] }

func topKFrequent(nums []int, k int) []int {
    numFreqHashMap := make(map[int]int) // {num: freq}
    for _, n := range nums {
        numFreqHashMap[n]++
    }

    h := &numFreqMinHeap{}
    for n, f := range numFreqHashMap {
        if h.Len() == k && f <= h.top().freq {
            continue
        }
        heap.Push(h, numFrequency{n: n, freq: f})
        if h.Len() > k {
            heap.Pop(h)
        }
    }

    topKFreqElems := []int{}
    for h.Len() > 0 {
        top := heap.Pop(h).(numFrequency)
        topKFreqElems = append(topKFreqElems, top.n)
    }

    return topKFreqElems
}
```

- Discordで他の人の解答を見ていたら、バケットソートを使っている人がいたので真似をした
- 時間計算量O(n)で実現できており、感動
  - 見積もり実行時間：1ms
- 参照：https://github.com/hayashi-ay/leetcode/pull/60/files

```Go
func topKFrequent(nums []int, k int) []int {
    numToFreq := make(map[int]int)
    maxFreq := 0
    for _, n := range nums {
        numToFreq[n]++
        if numToFreq[n] > maxFreq {
            maxFreq = numToFreq[n]
        }
    }

    numFreqBuckets := make([][]int, maxFreq + 1)
    for n, f := range numToFreq {
        numFreqBuckets[f] = append(numFreqBuckets[f], n)
    }

    topKFreqElems := []int{}
    for i := maxFreq; i >= 0; i-- {
        if len(topKFreqElems) >= k {
            break
        }
        topKFreqElems = append(topKFreqElems, numFreqBuckets[i]...)
    }
    return topKFreqElems
}
```

### Step 3
- 最終的なコード。Step2のバケットソートでやった
- step2からの変更箇所
  - maxFreq変数の更新にビルトインのmax関数を使った。2023年にリリースされたGo1.21で追加されたものらしいが、知らなかった。使う言語の最新verを追うことも大事
  - 最後のループのbreakする部分をtopKFreqElemsの更新の後にした。その方が自然

```Go
func topKFrequent(nums []int, k int) []int {
    numToFreq := make(map[int]int)
    maxFreq := 0
    for _, n := range nums {
        numToFreq[n]++
        maxFreq = max(maxFreq, numToFreq[n])
    }

    numFreqBuckets := make([][]int, maxFreq + 1)
    for n, f := range numToFreq {
        numFreqBuckets[f] = append(numFreqBuckets[f], n)
    }

    topKFreqElems := []int{}
    for i := maxFreq; i >= 0; i-- {
        topKFreqElems = append(topKFreqElems, numFreqBuckets[i]...)
        if len(topKFreqElems) >= k {
            break
        }
    }

    return topKFreqElems
}
```
