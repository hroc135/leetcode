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
    - coins=[3,5,10], amount=7 -> -1
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

### Step 2
#### 2a
- step1のボトムアップDPの改善
- DPテーブルをmath.MaxIntで埋めれば条件分岐が少なくなる
- 二つのループを合体させることもできるが、DPテーブルの初期化をまとめて行った方がわかりやすいと思い、ループを分けた
- 最初のループはJavaのArrays.fillのようなメソッドがGoにあれば生まれなかった
- 参考
	- https://hayapenguin.com/notes/LeetCode/322/CoinChange
	- https://github.com/seal-azarashi/leetcode/pull/37/files#r1832794636

```Go
func coinChange(coins []int, amount int) int {
	minCoinCombinations := make([]int, amount+1)
	for i := 1; i < len(minCoinCombinations); i++ {
		minCoinCombinations[i] = math.MaxInt64
	}
	for amt := 1; amt <= amount; amt++ {
		for _, coin := range coins {
			if coin <= amt && minCoinCombinations[amt-coin] < math.MaxInt64 {
				minCoinCombinations[amt] = min(minCoinCombinations[amt], minCoinCombinations[amt-coin]+1)
			}
		}
	}
	if minCoinCombinations[amount] == math.MaxInt64 {
		return -1 // no combination exist
	}
	return minCoinCombinations[amount]
}
```

#### 2b
- 2aのminCoinCombinationsのようなDPテーブルに、
その金額を払うための最小coin数と払えるかどうか(math.MaxInt64なら払えない)
というheterogeneousな情報が格納されてしまうのは良くないというコメントがあった
	- https://github.com/goto-untrapped/Arai60/pull/34#discussion_r1668488602
- 支払い可能な金額をmapで管理するようにした
- 2aが10ms程度だったのに対し、こちらは200ms程度になった
	- 下記コードだと再ハッシュされるので、
	`changeableAmounts := make(map[int]struct{}, amount+1)`
	とサイズを設定しても100msくらいかかった
	- mapへの書き込みが思い?

```Go
func coinChange(coins []int, amount int) int {
	coinCountForAmounts := make([]int, amount+1)
	for i := 1; i < len(coinCountForAmounts); i++ {
		coinCountForAmounts[i] = math.MaxInt64
	}
	changeableAmounts := map[int]struct{}{0: {}}
	for currentAmount := 1; currentAmount <= amount; currentAmount++ {
		for _, coin := range coins {
			if currentAmount < coin {
				continue
			}
			if _, found := changeableAmounts[currentAmount-coin]; !found {
				continue
			}
			coinCountForAmounts[currentAmount] = min(coinCountForAmounts[currentAmount], coinCountForAmounts[currentAmount-coin]+1)
			changeableAmounts[currentAmount] = struct{}{}
		}
	}
	if _, found := changeableAmounts[amount]; !found {
		return -1 // the given amount is not changeable
	}
	return coinCountForAmounts[amount]
}
```

#### 2c
- coinsを降順にソートしてDFS
- 12,345円払わないといけない時に1円玉から考えたりしない。
1万円札が1枚必要で、千円札が2枚必要で、...と大きい額のものから順に考えていくはず

- 最初に以下のようなコードを書いてWA
- これだとgreedyなので、coins=[1,8,10], amount=16のような場合に
10+1*6に飛びついてしまう(それ以上の探索をせずに回答してしまう)

```Go
func coinChange(coins []int, amount int) int {
	// sortedCoins is a slice of coins sorted in the descending order
	sortedCoins := make([]int, len(coins))
	copy(sortedCoins, coins)
	slices.SortFunc(sortedCoins, func(a, b int) int { return b - a })

	return coinChangeHelper(sortedCoins, amount)
}

// Argument sortedCoins is sorted in the descending order.
func coinChangeHelper(sortedCoins []int, amount int) int {
	if amount == 0 {
		return 0
	}
	for i, coin := range sortedCoins {
		if coin > amount {
			continue
		}
		coinCount := coinChangeHelper(sortedCoins[i:], amount-coin) + 1
		if coinCount > 0 {
			return coinCount
		}
	}
	return -1
}
```

- これがACコード
- coinsを降順にソートする際は参照透過性を保つためにcopyした

```Go
func coinChange(coins []int, amount int) int {
	// sortedCoins is sorted in the descending order
	sortedCoins := make([]int, len(coins))
	copy(sortedCoins, coins)
	slices.SortFunc(sortedCoins, func(a, b int) int {
		return b - a
	})

	minCoinCountForAmounts := make([]int, amount+1)
	for i := 1; i < len(minCoinCountForAmounts); i++ {
		minCoinCountForAmounts[i] = math.MaxInt64
	}

	var coinChangeHelper func(accumulatedAmount int, coinCount int, sortedCoinsStartIndex int)
	coinChangeHelper = func(accumulatedAmount, coinCount, sortedCoinsStartIndex int) {
		minCoinCountForAmounts[accumulatedAmount] = min(minCoinCountForAmounts[accumulatedAmount], coinCount)
		for i := sortedCoinsStartIndex; i < len(sortedCoins); i++ {
			nextAmount := accumulatedAmount + sortedCoins[i]
			if nextAmount > amount {
				continue
			}
			if minCoinCountForAmounts[nextAmount] <= coinCount+1 {
				continue
			}
			coinChangeHelper(nextAmount, coinCount+1, i)
		}
	}

	coinChangeHelper(0, 0, 0)
	if minCoinCountForAmounts[amount] < math.MaxInt64 {
		return minCoinCountForAmounts[amount]
	}
	return -1 // no coin combination found
}
```

#### 2d
- BFS
- 無名構造体の書き方を忘れていた
- 参考
	- https://github.com/seal-azarashi/leetcode/pull/37/files#r1830469401
	- https://github.com/seal-azarashi/leetcode/pull/37/files#diff-d111aa48a9b8e9e14eb6bc7f1e3254ae69a49b49fc338da8095b0b21ce3ad667R410

```Go
func coinChange(coins []int, amount int) int {
	amountToMinCoinCount := make([]int, amount+1)
	for i := range amountToMinCoinCount {
		amountToMinCoinCount[i] = math.MaxInt64
	}
	queue := []struct {
		amount    int
		coinCount int
	}{{0, 0}}

	for len(queue) > 0 {
		head := queue[0]
		currentAmount := head.amount
		currentCoinCount := head.coinCount
		queue = queue[1:]
		if amountToMinCoinCount[currentAmount] <= currentCoinCount {
			continue
		}
		amountToMinCoinCount[currentAmount] = currentCoinCount
		for _, coin := range coins {
			if head.amount+coin > amount {
				continue
			}
			queue = append(queue, struct {
				amount    int
				coinCount int
			}{currentAmount + coin, currentCoinCount + 1})
		}
	}
	if amountToMinCoinCount[amount] == math.MaxInt64 {
		return -1 // no combination exist
	}
	return amountToMinCoinCount[amount]
}
```

### Step 3
- coinsの降順ソートしてDFSする方法が最も直感に近い方法な気がした
- 2cからの改善点
	- math.MaxInt64がマジックナンバーにならないよう定数notChangeableを用意する
	- coinChangeHelperだとヘルパー関数であるという情報しかないので、
	searchMinCoinCountsに変更
	- 参照透過性を保つためにsortedCoinsという新しいsliceを作ったつもりだったが、
	よく考えたら少なくともcoinChange関数においてcoinsをin-placeにソートしても
	参照透過性は損なわれない。
	coinChangeの呼び出し元でcoinsの順番に意味がある場合にソートするのは問題かもしれないが、
	coinsの順番に意味はないと勝手に判断し、in-placeでソートすることに

```Go
func coinChange(coins []int, amount int) int {
	const notChangeable = -1

	// sort coins in the descending order
	slices.SortFunc(coins, func(a, b int) int { return b - a })

	coinCountForAmounts := make([]int, amount+1)
	for i := 1; i < len(coinCountForAmounts); i++ {
		coinCountForAmounts[i] = notChangeable
	}

	var searchMinCoinCounts func(currentAmount int, coinCount int, coinsStartIndex int)
	searchMinCoinCounts = func(currentAmount, coinCount, coinsStartIndex int) {
		coinCountForAmounts[currentAmount] = coinCount
		for i := coinsStartIndex; i < len(coins); i++ {
			nextAmount := currentAmount + coins[i]
			if nextAmount > amount {
				continue
			}
			if coinCountForAmounts[nextAmount] != notChangeable && coinCountForAmounts[nextAmount] <= coinCount+1 {
				continue
			}
			searchMinCoinCounts(nextAmount, coinCount+1, i)
		}
	}

	searchMinCoinCounts(0, 0, 0)
	return coinCountForAmounts[amount]
}
```

### CS
- composite literal
	- 複数のデータ型を一つの集合として表すもの
	- ex. スライス、構造体、マップ、チャネル
	- プリミティブ型の対義語のイメージ
- simplifycompositelit
	- コンポジット表現の簡素化をするフォーマッター
	- gofmt -s で呼び出せる。vscodeでセーブ時に動いてくれてるっぽい
	- `changeableAmounts := map[int]struct{}{0: struct{}{}}`
	としたらsimplifycompositelitに怒られ、
	`changeableAmounts := map[int]struct{}{0: {}}`に直された