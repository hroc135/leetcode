問題: https://leetcode.com/problems/coin-change/description/

### Step 1
- n円払うのに必要な最小の硬貨数を1から順に計算して記録していく
- n円払いたい。
n-1円を20枚の硬貨で出し終えていて1円玉があったら21枚で支払える。
一方、n-5円を10枚の硬貨で出せていたら11枚で足りる。
- テストケース
    - coins=[], amount=10 -> -1
    - coins=[1,5,10], amount=0 -> 0
    - coins=[1], amount=10 -> 10
    - coins=[2], amount=10 -> 5
    - coins=[3], amount=10 -> -1
    - coins=[1,5,10], amount=6 -> 2
    - coins=[1,5,10], amount=9 -> 5
    - coins=[1,5,10], amount=16 -> 3
    - coins=[1,5,10], amount=25 -> 3
- 制約条件で`1 <= coins[i] <= 2^31 - 1`となっていることから
integer overflowが起きないか心配になった。
coin[i1]+coin[i2]みたいな計算はないので大丈夫そう
- Goのint型は32bitマシンでは32bit, 64bitマシンでは64bit
- ループの中のif文が多くて美しくない
- ループの前後のエッジケース処理が美しくない
- 入出力の合致するコードになっただけ感

```Go
func coinChange(coins []int, amount int) int {
	if amount == 0 {
		return 0
	}
	minCoinCountsForAmount := make([]int, amount+1)
	for amt := 1; amt <= amount; amt++ {
		for _, coin := range coins {
			if amt-coin < 0 {
				continue
			}
			if amt-coin == 0 {
				minCoinCountsForAmount[amt] = 1
				break
			}
			if minCoinCountsForAmount[amt-coin] == 0 {
				continue
			}
			if minCoinCountsForAmount[amt] == 0 {
				minCoinCountsForAmount[amt] = minCoinCountsForAmount[amt-coin] + 1
				continue
			}
			minCoinCountsForAmount[amt] = min(minCoinCountsForAmount[amt], minCoinCountsForAmount[amt-coin]+1)
		}
	}
	if minCoinCountsForAmount[amount] == 0 {
		return -1
	}
	return minCoinCountsForAmount[amount]
}
```

- coinsを降順にソートして、DFS。最初にamountを支払えた時の硬貨数が最小


### Step 2


### Step 3
