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
- 行数は減ったが、if文を使った方がアルゴリズムをうまく表現できていると思う
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

### todo
- scanl, zipWithの議論確認
    - https://github.com/goto-untrapped/Arai60/pull/58/files#r1788461971