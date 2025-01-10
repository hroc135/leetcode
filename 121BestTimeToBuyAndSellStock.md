問題: https://leetcode.com/problems/best-time-to-buy-and-sell-stock/description/

### Step 1
- まず思いついたのはO(n^2)の全探索
    - leetcodeの制約は `len(prices) <= 1e5` なので、
    1e5^2 / 1e8 = 100s くらいかかってしまう
- 思いついたO(n)時間アルゴリズムの説明
    - pricesの要素を舐めていき、prefixの最小値を覚えておく
    - prefixの最小値とprices[i]の差分が最大利益になったら答えを更新
- n <- len(prices)
    - 時間計算量: O(n)
    - 空間計算量: O(1)
- テストケース
    - [0] -> 0
    - [0,0] -> 0
    - [0,1] -> 1
    - [1,0] -> 0
    - [10,20,0,1,2] -> 10
    - [10,20,0,100,2] -> 100
    - [0,20,10,30,10,50] -> 50
    - 要素数1,2の場合を機械的に生成
    - 最大利益が更新されるver, されないverも加える

```Go
func maxProfit(prices []int) int {
	minimumPrice := prices[0]
	res := 0
	for i := 1; i < len(prices); i++ {
		if prices[i] < minimumPrice {
			minimumPrice = prices[i]
			continue
		}
		res = max(res, prices[i]-minimumPrice)
	}
	return res
}
```

### Step 2
#### 2a
- step1の改善
- step1のif文をなくして以下のようにすることもできる
- 行数は減ったが、if文を使った方がアルゴリズムをうまく表現できている気がする
- 入力が空リストの場合
    - https://github.com/rihib/leetcode/pull/24/files#diff-642281710a01b50cc64b5a0013af510eb6ea4785e334a396d62c19026d66121dR7
    - 選択肢はerrorを返す、panicする、-1など特別な値を返す
    - 直近で似た議論があり、それと同じで空リストならそもそも関数を呼ぶなと言いたくなるのでpanicすることに
        - https://github.com/hroc135/leetcode/pull/34#discussion_r1907020304

```Go
func maxProfit(prices []int) int {
	if len(prices) == 0 {
		panic("maxProfit: empty list")
	}
	minimumPrice := prices[0]
	res := 0
	for i := 1; i < len(prices); i++ {
		p := prices[i]
		minimumPrice = min(minimumPrice, p)
		res = max(res, p-minimumPrice)
	}
	return res
}
```

#### 2b
- ナイーブなO(n^2)時間アルゴリズム
- 要素数が1e4なら、1e4^2 / 1e8 = 1s で収まるので
データサイズが小さいとわかっていたらこれでも良い

```Go
func maxProfit(prices []int) int {
	res := 0
	for i := 0; i < len(prices); i++ {
		for j := i + 1; j < len(prices); j++ {
			res = max(res, prices[j]-prices[i])
		}
	}
	return res
}
```

#### 2c
- 関数型っぽい見方もできるらしい
    - https://github.com/goto-untrapped/Arai60/pull/58/files#r1782742318
- scanl, foldlなどの高階関数をこういう風に使うんだと勉強になった
    - 自力で書ける気はあまりしていない

```haskell
prices = [7,1,5,3,6,4]
minPrices = scanl min (head prices) prices
profits = zipWith (-) prices (tail minPrices)
maxProfit = foldl max 0 profits
```

```Go
func maxProfit(prices []int) int {
	minPrices := make([]int, len(prices))
	minPrice := prices[0]
	for i := 0; i < len(prices); i++ {
		minPrice = min(minPrice, prices[i])
		minPrices[i] = minPrice
	}

	res := 0
	for i := 0; i < len(prices); i++ {
		res = max(res, prices[i]-minPrices[i])
	}
	return res
}
```

#### 2d
- 2aを逆から見ていくこともできる
    - https://github.com/fhiyo/leetcode/pull/38/files#diff-2508181bc4e99cbc345ea1ae774e36744db291b2c450072d0c29b5d0bd029069R28

```Go
func maxProfit(prices []int) int {
	maxPrice := prices[len(prices)-1]
	res := 0
	for i := len(prices) - 1; i >= 0; i-- {
		maxPrice = max(maxPrice, prices[i])
		res = max(res, maxPrice-prices[i])
	}
	return res
}
```

### Step 3

```Go
func maxProfit(prices []int) int {
	minPrice := prices[0]
	res := 0
	for i := 1; i < len(prices); i++ {
		if prices[i] < minPrice {
			minPrice = prices[i]
			continue
		}
		res = max(res, prices[i]-minPrice)
	}
	return res
}
```