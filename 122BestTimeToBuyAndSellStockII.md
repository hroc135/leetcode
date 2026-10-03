問題: https://leetcode.com/problems/best-time-to-buy-and-sell-stock-ii/description/

### Step 1
- 購入価格を覚えておき、次の日に株価が下がるなら売って次の日に買う
- 方針はすぐに思いついたが、末尾要素の扱いに手こずった
- テストケース
    - [0] -> 0
    - [0,0] -> 0
    - [0,1] -> 1
    - [1,0] -> 0
    - [0,1,2,0,2] -> 4
    - [1,0,1,0,1] -> 2
    - [2,0,2,1,0] -> 2

```Go
func maxProfit(prices []int) int {
	purchasedPrice := prices[0]
	res := 0
	for i := 0; i < len(prices)-1; i++ {
		// When to sell
		if prices[i] > prices[i+1] {
			res += prices[i] - purchasedPrice
			purchasedPrice = prices[i+1]
		}
	}
	res += max(0, prices[len(prices)-1]-purchasedPrice)
	return res
}
```

### Step 2
#### 2a
- 前日から上がったらその差分を累積していく考え方
- 実装がシンプルになる
- 前日より株価が上がったらすぐ売っているというのがちょっと現実に即さない感じはある

```Go
func maxProfit(prices []int) int {
	accumulatedProfit := 0
	for i := 1; i < len(prices); i++ {
		if prices[i-1] < prices[i] {
			accumulatedProfit += prices[i] - prices[i-1]
		}
	}
	return accumulatedProfit
}
```

#### 2b
- 株を持っている状態と持っていない状態それぞれの場合の最良の収支を更新していく方法
- 理解するのにかなり時間がかかった
- profitWithStockがマイナスになる部分の理解に苦しんだ
- 参考
    - https://github.com/fhiyo/leetcode/pull/39#pullrequestreview-216579962
    - https://github.com/goto-untrapped/Arai60/pull/59/files#diff-c59f6e68b39b5b00cc1d1fd0ff30aa94e7e2a882d9daefdfb73eda1b94fb3e17R53-R54

```
入力: [7,1,5,3,6,4]
-7    -1 -> -1     1 ->  1     3 
   ↗︎         ↓  ↗️        ↓  ↗️
 0 ->  0     4 ->  4     7 ->  7

上がprofitWithStock、下がprofitWithoutStock
```

```Go
func maxProfit(prices []int) int {
	profitWithStock := -prices[0]
	profitWithoutStock := 0
	for i := 1; i < len(prices); i++ {
		profitWithStock = max(profitWithStock, profitWithoutStock-prices[i])
		profitWithoutStock = max(profitWithoutStock, profitWithStock+prices[i])
	}
	return profitWithoutStock
}
```

### Step 3

```Go
func maxProfit(prices []int) int {
	res := 0
	for i := 1; i < len(prices); i++ {
		if prices[i-1] < prices[i] {
			res += prices[i] - prices[i-1]
		}
	}
	return res
}
```

### CS
- Rust
    - なんで人気なんだろうと気になった
    - C/C++に比べてメモリの管理がしやすい
    - ガベージコレクションの代わりにオーナーシップという手法を用いている
    - 組み込みシステム開発などの低レイヤーでよく使われる
    - 参考: https://github.blog/developer-skills/programming-languages-and-frameworks/why-rust-is-the-most-admired-language-among-developers/
- トップダウン vs ボトムアップ
    - ソフトウェア工学における設計戦略
    - トップダウン: 全体を決めてから詳細を決める
    - ボトムアップ: 個々の部品を作り、それらを集積して全体を作る
    - 参考: https://ja.wikipedia.org/wiki/%E3%83%88%E3%83%83%E3%83%97%E3%83%80%E3%82%A6%E3%83%B3%E8%A8%AD%E8%A8%88%E3%81%A8%E3%83%9C%E3%83%88%E3%83%A0%E3%82%A2%E3%83%83%E3%83%97%E8%A8%AD%E8%A8%88