### Step 1
- 最初に思いついたのは、頭から一文字ずつ発生回数を数え、最初に見つかった発生回数1の文字のインデックスを返す方法
  - ただ、このやり方は時間計算量O(n^2)で、見積もり実行時間は、10^5^2 = 10^10 -> 10^8で割って100秒 になってしまうので他の方法を考えることに
- 採用したアルゴリズムは、(1)一文字ずつ、出現するインデックスをスライスに溜めていき、(2)スライスの長さが1のもの同士の要素を比べ、最小値を返す、というもの
- 時間計算量：O(n) （見積もり実行時間は、1ms）
- 空間計算量：O(n)

```Go
// Go

func firstUniqChar(s string) int {
	charIndices := make(map[rune][]int)
	for i, c := range s {
		charIndices[c] = append(charIndices[c], i)
	}

	ans := -1
	for _, indices := range charIndices {
		if len(indices) > 1 {
			continue
		}
		if ans == -1 {
			ans = indices[0]
		}
		ans = min(ans, indices[0])
	}

	return ans
}
```
