問題: https://leetcode.com/problems/k-th-symbol-in-grammar/description/

### Step 1
- コンパイラの授業の文脈自由文法の話に似ている作業
    - プッシュダウンオートマトンと再帰を使ったという朧げな記憶
- まず愚直に記号列を作っていく方法を思いつく
- 他にはnとkを再帰的に減らしていく方法も思いついたが、一旦ナイーブな方法で実装する
- 記号列をstring型で作る方法も考えられたが、
Goのstringはイミュータブルで余計なコピー作成が発生するのでスライスを使うことに
- 時間計算量: O(2^n)
    - currentRowSymbols のサイズは2^kなので内側のループは2^kであることより、
    1+2+4+...+2^n という一般項2^nの等比数列の和を求めてO(2^n)
- 空間計算量: O(2^n)
- ヒープメモリ切れでクラッシュした

```Go
func kthGrammar(n int, k int) int {
	currentRowSymbols := []int{0}
	for i := 1; i <= n; i++ {
		nextRowSymbols := []int{}
		for _, s := range currentRowSymbols {
			switch {
			case s == 0:
				nextRowSymbols = append(nextRowSymbols, 0)
				nextRowSymbols = append(nextRowSymbols, 1)
			case s == 1:
				nextRowSymbols = append(nextRowSymbols, 1)
				nextRowSymbols = append(nextRowSymbols, 0)
			}
		}
		currentRowSymbols = nextRowSymbols
	}
	return currentRowSymbols[k-1]
}
```

- 紙に書いたところ、以下のような法則性があることに気がついた
    - n行目の前半はn-1行目と一致する
    - n行目の後半はn-1行目の0と1を入れ替えたもの一致する
- テストケース
    - n=1, k=1 -> 0
    - n=2, k=1 -> 0
    - n=2, k=2 -> 1
    - n=3, k=1 -> 0
    - n=3, k=2 -> 1
    - n=3, k=3 -> 1
    - n=3, k=4 -> 0
    - n=4, k=1 -> 0
    - n=4, k=5 -> 1
- 時間計算量: O(n)
- 空間計算量: O(n)

```Go
func kthGrammar(n int, k int) int {
	switch {
	case n == 1:
		return 0
	case n == 2 && k == 1:
		return 0
	case n == 2 && k == 2:
		return 1
	}
	rowSizeHalf := int(math.Pow(2, float64(n-2)))
	if k <= rowSizeHalf {
		return kthGrammar(n-1, k)
	} else {
		// if kthGrammar(n-1, k-rowSizeHalf) == 0 then return 1
		// if kthGrammar(n-1, k-rowSizeHalf) == 1 then return 0
		return (kthGrammar(n-1, k-rowSizeHalf) + 1) & 1
	}
}
```

### Step 2
- https://github.com/hayashi-ay/leetcode/pull/46/files#diff-da439603310f08640b8dab0ec6cfc15251b5669e04e4effc5795dbe1f506a8daR13
    - O(2^n)の空間計算量でどのくらいのメモリ領域が使われるのかについて見積もっていたので自分もやってみる
    - メモリ使用量は2^{n-1}でleetcodeの制約はn <= 30
    - int64は8Bなので 2^29 ÷ 8 ≒ 2^30 ÷ 10 ≒ 1000^3 ÷ 10 = 10^8 = 100MB
- 0か1かなのでint64で64bitまとめて表す方法もある
    - ただし、メモリ使用量はたかだか1/64
    - https://github.com/hayashi-ay/leetcode/pull/46/files#diff-da439603310f08640b8dab0ec6cfc15251b5669e04e4effc5795dbe1f506a8daR16

#### 2a
- step1の修正
- 0なら1に、1なら0にの反転はもっと簡単にできる
    - https://github.com/fhiyo/leetcode/pull/47/files#diff-518e9507bea66eabe2b96ca4930b3dfa228b17d6c3e68dd05b92ab1c7de3228dR49
    - bits.Reverseを使っても良いが、0か1かだけなので上記で良さそう
- nが2の場合はなくても良い
- ifでreturnしているのでわざわざelseを書く必要がない
- pythonのようにキャッシュデコレータがあれば2の累乗を自作再帰関数で行ってキャッシュすれば若干早くなりそうだが、Goにはない
    - O(logn)時間の計算がO(1)で行える場合が出るが、メモリを消費することと実装難易度を考えるとわざわざやるほどでもない

```Go
func kthGrammar(n int, k int) int {
	if n == 1 {
		return 0
	}
	rowHalfSize := int(math.Pow(2, float64(n-2))) // 2**(n-1) / 2
	if k > rowHalfSize {
		return 1 - kthGrammar(n-1, k-rowHalfSize)
	}
	return kthGrammar(n-1, k)
}
```

#### 2b
- 二分木があると想像して葉から根までたどって戻ってくる方法
- https://github.com/hayashi-ay/leetcode/pull/46/files#diff-da439603310f08640b8dab0ec6cfc15251b5669e04e4effc5795dbe1f506a8daR66

```Go
func kthGrammar(n int, k int) int {
	patterns := map[int][2]int{
		0: {0, 1},
		1: {1, 0},
	}

	var kthGrammarHelper func(n int, k int) int
	kthGrammarHelper = func(n int, k int) int {
		if n == 1 {
			return 0
		}
		previousSymbol := kthGrammarHelper(n-1, (k+1)/2)
		return patterns[previousSymbol][(k-1)%2]
	}
	return kthGrammarHelper(n, k)
}
```

#### 2c
- kのpopcntから導けるらしい。なんだと
    - https://github.com/hayashi-ay/leetcode/pull/46#issuecomment-1986824146
- https://github.com/olsen-blue/Arai60/pull/47/files#r2003238004
    - この説明がわかりやすかった
- 0 -> 01, 1 -> 10 を二分木として見て観察すると、
左側に行く場合は親と同じで右側に行く場合は反転する
- 0 -> 01 -> 0110 を二分木として見て、
0-indexの2番の葉に辿り着くまでに根から順に右、左と移動したので
ビットの反転は1度だけ起きる。
根が0でビットの反転が1度(奇数回)起きると最終的なビットは1
- https://discord.com/channels/1084280443945353267/1200089668901937312/1216054396161622078
    - こんな話があったので読んでみる
    - メモは最下部CS欄に記載
- Goだとpopcntに相当する計算をbits.OnesCountで行えるらしい
- Goは未使用の変数を宣言するとエラーが出るので、
引数nを使わないとエラーが出るかなと思ったが、unusedparamsチェッカーが文句を言ってきただけだった

```Go
func kthGrammar(n int, k int) int {
	return bits.OnesCount(uint(k-1)) & 1
}
```

### Step 3
```Go
func kthGrammar(n int, k int) int {
	return bits.OnesCount(uint(k-1)) & 1
}
```

#### Step 4
- bits.OnesCountの内部実装確認
- uint型がマシン環境によって32bitになっているか64bitになっているかを調べてbits.OnesCount32かOnesCount64を呼び出している
- 32bitマシンか64bitマシンかどうかの調べ方が勉強になった
    - `const uintSize = 32 << (^uint(0) >> 63)`
    - `^uint(0)`は0のXORを取るので32bitマシンなら1が32個、
    64bitマシンなら64個並ぶ
    - それを63個右シフトしたら32bitマシンなら全部0で、
    64bitマシンなら末尾に1が残る
- OnesCount32, OnesCount64の中では下記リンク先で記載されていることと同じことをやっている
    - https://stackoverflow.com/questions/109023/count-the-number-of-set-bits-in-a-32-bit-integer#109025

```Go
const uintSize = 32 << (^uint(0) >> 63)
const UintSize = uintSize

func OnesCount(x uint) int {
	if UintSize == 32 {
		return bits.OnesCount32(uint32(x))
	}
	return bits.OnesCount64(uint64(x))
}
```

- uintSizeの調べ方と似ているものに、MaxIntがある
- MinIntは`MinInt = 1 << (intSize - 1)`でも得られるかと思ったが、overflowしてしまうらしい

```Go
const MaxInt = 1<<(intSize-1) - 1
const MinInt = -1 << (intSize - 1)
```

### CS
- Hamming Weight
    - 0のみからなる文字列に対するハミング距離みたいなもの
    - つまり、ビット列で1が出現する回数
- popcnt
    - x86などにあるhamming weightを計算する命令
    - Population Count の略らしい
- SWAR Algorithm
    - Hamming Weight を計算するアルゴリズム
    - SWAR: SIMD within a Register
    - アルゴリズムの中身はあまり理解できなかったが、
    ざっくり言うとビットのシフトと0101、0011みたいなビット列とのアンドを繰り返していく感じ
    - 0x5555 -> 0101...
    - 0x3333 -> 00110011...
    - 0x0F0F -> 00010001...
    - 0x0101 -> 0000000100000001...
    - みたいな規則性のあるビット列になる16進数たち
- SIMD: Single Instruction, Multiple Data
    - 日本語読みは「シムディー」
    - 単一の命令で複数のデータにアクセスすること