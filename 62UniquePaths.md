問題: https://leetcode.com/problems/unique-paths/description/

### Step 1
- (i,j)地点にたどり着くpathは上(i-1,j)と左(i,j-1)にたどり着くpathの合計値。
二次元的に値を参照したいのでDPテーブルを使う
- 今回はleetcodeのテストケースを走らせる前に自作テストケースを頭の中で走らせることに
    - 以前川中さんが「テストケースは機械的に生成するといい」とおっしゃっていたので、以下を試す
    - (m,n) = (0,0), (0,1), (1,0), (1,1), (1,2), (2,1), (2,2)
    - 2つほど境界条件関連のバグが見つかった。
    脳内シミュレーションの練習にもなるので習慣化しよう
- 時間計算量: O(mn)
- 空間計算量: O(mn)

```Go
func uniquePaths(m int, n int) int {
	if m == 0 || n == 0 {
		return 0 // 本当は return 0, err としたい
	}
	uniquePathsGrid := make([][]int, m)
	for i := 0; i < m; i++ {
		uniquePathsGrid[i] = make([]int, n)
		for j := 0; j < n; j++ {
			if i == 0 && j == 0 {
				uniquePathsGrid[0][0] = 1
				continue
			}
			paths := 0
			if i-1 >= 0 {
				paths += uniquePathsGrid[i-1][j]
			}
			if j-1 >= 0 {
				paths += uniquePathsGrid[i][j-1]
			}
			uniquePathsGrid[i][j] = paths
		}
	}
	return uniquePathsGrid[m-1][n-1]
}
```

### Step 2

#### 2a
- step1のコードをpattern-defeatingにしてみる
- m,nのいずれかが1,2の場合にO(1)時間で計算できる

```Go
func uniquePaths(m int, n int) int {
	if m == 0 || n == 0 {
		return 0 // 本当は return 0, err としたい
	}
	if m == 1 || n == 1 {
		return 1
	}
	if m == 2 {
		return n
	}
	if n == 2 {
		return m
	}
	uniquePathsGrid := make([][]int, m)
	for i := 0; i < m; i++ {
		uniquePathsGrid[i] = make([]int, n)
		for j := 0; j < n; j++ {
			if i == 0 && j == 0 {
				uniquePathsGrid[0][0] = 1
				continue
			}
			paths := 0
			if i-1 >= 0 {
				paths += uniquePathsGrid[i-1][j]
			}
			if j-1 >= 0 {
				paths += uniquePathsGrid[i][j-1]
			}
			uniquePathsGrid[i][j] = paths
		}
	}
	return uniquePathsGrid[m-1][n-1]
}
```

#### 2b
- 一次元DP
- 時間計算量: O(mn)
- 空間計算量: O(min(m, n))
- 参考: https://github.com/hayashi-ay/leetcode/pull/39/files#diff-3d04158956739fa9e3948a043cdcf2a3246498baedcc5098bf90ee92cad790d0R27

```Go
func uniquePaths(m int, n int) int {
	if m == 0 || n == 0 {
		return 0
	}
	if m < n {
		return uniquePaths(n, m)
	}
	pathsCounter := make([]int, n)
	for i := range pathsCounter {
		pathsCounter[i] = 1
	}
	for row := 1; row < m; row++ {
		for col := 1; col < n; col++ {
			pathsCounter[col] += pathsCounter[col-1]
		}
	}
	return pathsCounter[n-1]
}
```

#### 2c
- 自分で手を動かしてDPテーブルを作った時に規則性がありそうだと思ったので、
多分mとnから瞬時に答えを導くことのできる計算式がありそうだと思った
- 自分では思いつかなかったので、調べたら以下リンク先に説明があった
    - https://github.com/hayashi-ay/leetcode/pull/39/files#diff-3d04158956739fa9e3948a043cdcf2a3246498baedcc5098bf90ee92cad790d0R41
    - そういえば高校か中学の組み合わせの授業でやった記憶がある
- 以下のコードでinteger overflowを起こしてWA
    - 不用意に大きい数の積を計算するべきではない
    - レベル1: integer overflowって何？小さい数だと正解なのに大きい数だと不正解なのはなぜ？
    - レベル2: 大きい数で不正解 -> もしかしてinteger overflowが起きてるかな？
    - レベル3: このアルゴリズムでできそうだけど大きい数だとinteger overflowを起こしそう。
    他の選択肢もないか考えてみよう
    - レベル2と3の間の違いは「衝動的に思いついたことを書いて」しまっているかどうかだと思う。
    ここは20数年で染み付いてしまった思考習慣なので、時間をかけて直すしかない
        - https://discord.com/channels/1084280443945353267/1084283898617417748/1295668028641382433
- 分母と分子の計算部分のループはどちらもk-1回のループなので一つにまとめることができるが、
分けた方が組み合わせの計算を追いやすいと思った。
また、コンパイラでループ融合の最適化がかかるなら分けたコードを書いても
分けずに書いたコードと同じ速度で実行してくれると期待できる
(Goコンパイラにループ融合最適化があるかどうかは調べても出てこず)

```Go
func uniquePaths(m int, n int) int {
	return combination(m-1+n-1, m-1)
}

func combination(n, k int) int {
	if k > n/2 {
		return combination(n, n-k)
	}
	numerator := 1
	for i := n; i >= n-k+1; i-- {
		numerator *= i
	}
	denominator := 1
	for i := k; i >= 1; i-- {
		denominator *= i
	}
	return numerator / denominator
}
```

- 積が大きくなりすぎないように、分子を分母で割り切れる時は割りながら掛けていく
- 時間計算量: O(min(m, n))
- 空間計算量: O(1)

```Go
func uniquePaths(m int, n int) int {
	return combination(m-1+n-1, m-1)
}

func combination(n, k int) int {
	if k > n/2 {
		return combination(n, n-k)
	}
	numerator := 1
	denominator := 1
	for i := 0; i < k; i++ {
		numerator *= n - k + 1 + i
		denominator *= i + 1
		if numerator%denominator == 0 {
			numerator /= denominator
			denominator = 1
		}
	}
	return numerator
}
```

- Goは標準ライブラリでは組み合わせの計算は用意されていないが、
サードパーティで見つけたので中身を見てみた
    - https://github.com/gonum/gonum/blob/v0.15.1/stat/combin/combin.go#L29
- 組み合わせnCkのことを英語ではBinomial Coefficient(n choose k)というらしい
- 自分は`if k > n/2 { return combination(n, n-k) }`としていたが、
`if k > n/2 { k = n - k }`としていた。
こっちの方がシンプルだし関数呼び出しを減らせる(数nsくらいなのでそこまで影響は大きくない)
- あと自分のコードは割り切れない時に割ってしまうと数字がずれてしまうことを懸念して逐次確認するようにしていたが、ライブラリのコードではその確認をしていない。
分母で素数pが出現するまでにループはp回回る。分子の積の一番小さい数n-k+1と、素数pを含む最も小さい数の差はp以下である。よって、必ず割り切れる、という理屈
    - ただ読み手にそのパズルをさせていいのか、ということが指摘できる。

```Go
func uniquePaths(m int, n int) int {
	return BinomialCoefficient(m-1+n-1, m-1)
}

// BinomialCoefficient returns the answer of n choose k.
func BinomialCoefficient(n, k int) int {
	if k > n/2 {
		k = n - k
	}
	res := 1
	for i := 1; i <= k; i++ {
		res = res * (n - k + i) / i
	}
	return res
}
```

### Step 3

```Go
func uniquePaths(m int, n int) int {
	if m < n {
		m, n = n, m
	}
	pathCountTable := make([]int, n)
	for i := range pathCountTable {
		pathCountTable[i] = 1
	}
	for i := 1; i < m; i++ {
		for j := 1; j < n; j++ {
			pathCountTable[j] += pathCountTable[j-1]
		}
	}
	return pathCountTable[n-1]
}
```

### CS
- ループ融合
    - コンパイラの最適化手法の一つ
    - 二つのループを合体させることにより、ループの中身からループ条件の確認部分へのジャンプの回数を半分に減らせる
    - 背景: コンパイラの最適化はループに関係する部分が非常に大事。
    ループの外で定数畳み込みをやっても大した効果はないが、ループ部分の無駄を省くことは影響が大きい