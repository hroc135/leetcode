問題: https://leetcode.com/problems/powx-n/description/

### Step 1
- nがpositiveなら1にxをn回かける。
nがnegativeなら1をn回xで割る
- xやnが0の場合をエッジケースとして処理
- テストケース
    - 0^0 -> 1
    - 0^1 -> 0
    - 2^0 -> 1
    - 2^2 -> 4
    - 2^-2 -> 1/4
    - 2^3 -> 8
    - -2^2 -> 4
    - -2^3 -> -8
- TLEしたコード
    - O(n)時間

```Go
func myPow(x float64, n int) float64 {
	if n == 0 {
		return 1
	}
	if x == 0 && n < 0 {
		panic("cannot define 0 to the negative number")
	}
	if x == 0 {
		return 0
	}
	res := 1.0
	if n < 0 {
		for i := 0; i < -n; i++ {
			res /= x
		}
		return res
	} else {
		for i := 0; i < n; i++ {
			res *= x
		}
		return res
	}
}
```

- O(n)時間でダメならO(logn)時間にしてやろう
- 2^100をどうしたら効率的に計算できるか考える
    - 2^100 = 2^(2*50) = 4^50 = 4^(2*25) 
    = 16^25 = 16^(2*12+1) = 256^12 * 16 ...
    - こうすればlogn時間で計算できる
- 2^100 を形を変えながら別の累乗計算に持ち込むので再帰で実装できる
- nが負のときにどうしようか悩んだが、nを正の数に変換して計算して最後に1をそれで割ったら答えが出ることに気がついた
- 自分でできてかなりの達成感
- 時間計算量: O(log n)
- 空間計算量: O(log n)
    - O(1)サイズのスタックフレームがlog n個積まれるから
    - 64bitマシンのint型は64bitであることから、
    スタックフレームは最大で log(2^64) = 64個積まれる
    - この程度ならスタックオーバーフローは起きない

```Go
func myPow(x float64, n int) float64 {
	if n == 0 {
		return 1
	}
	if n < 0 {
		return negativePow(x, n)
	}
	return positivePow(x, n)
}

func positivePow(x float64, n int) float64 {
	if x == 0 {
		return 0
	}
	if n == 1 {
		return x
	}
	quotient := n / 2
	remainder := n % 2
	if remainder == 1 {
		return positivePow(x*x, quotient) * x
	}
	return positivePow(x*x, quotient)
}

func negativePow(x float64, n int) float64 {
	if x == 0 && n < 0 {
		panic("cannot define 0 to a negative number")
	}
	return 1.0 / positivePow(x, -n)
}
```

### Step 2
#### 2a
- step1の修正
- 読み返してエッジケースの処理が気になった
    - xが0の場合はヘルパー関数よりも呼び出し元で弾いた方がすっきりと再帰関数をかけると思った
- nが負の場合の処理方法として、nを正にして1/x^(-n)と解釈する方法もある
    - https://github.com/SanakoMeine/leetcode/pull/9/files#diff-579f0a929d810b241709f7ffe2baa254c89984745a8b4f97490b2bb4b3e04903R39
- https://github.com/SanakoMeine/leetcode/pull/9/files#diff-579f0a929d810b241709f7ffe2baa254c89984745a8b4f97490b2bb4b3e04903R83
    - 自分も再帰の方がしっくりきた
- x==0の場合を呼び出し元で検出するかどうか迷った。
今回はコードの簡潔さを優先して検出しないことにした。
- pattern defeatingにしたければ、x==0 or 1の場合にそれぞれ呼び出し元で0と1を返せば良い

```Go
func myPow(x float64, n int) float64 {
	if n == 0 {
		return 1
	}
	if x == 0 && n < 0 {
		panic("cannot define 0 to the power of negative")
	}
	if n < 0 {
		n = -n
		x = 1 / x
	}
	return powPositiveExponent(x, n)
}

func powPositiveExponent(x float64, n int) float64 {
	if n == 1 {
		return x
	}
	remainder := n % 2
	if remainder == 1 {
		return powPositiveExponent(x*x, n/2) * x
	}
	return powPositiveExponent(x*x, n/2)
}
```

#### 2b
- ループを使う方法

```Go
func myPow(x float64, n int) float64 {
	if n == 0 {
		return 1
	}
	if x == 0 && n < 0 {
		panic("cannot define 0 to the power of negative")
	}
	if n < 0 {
		n = -n
		x = 1 / x
	}
	remainder := 1.0
	for {
		if n == 1 {
			return x * remainder
		}
		if n%2 == 1 {
			remainder *= x
		}
		x *= x
		n /= 2
	}
}
```

- 浮動小数の計算であることを明示するために1.0と書く
    - https://github.com/Ryotaro25/leetcode_first60/pull/48/files#r1882191228
- 奇数かどうかを見る方法として`n & 1`というビット演算もある
    - https://github.com/nittoco/leetcode/pull/17/files#diff-a3e3ccfc2495e5fe6296419ea0d68563a7e1d6f7aa562d9cc9a489848c590908R66
- nがint型の最小値の場合、int型の最大値・最小値の非対称性より、-nで期待される値にならない
    - そこで、int型を浮動小数に変換してしまう
    - https://github.com/nittoco/leetcode/pull/17/files#diff-a3e3ccfc2495e5fe6296419ea0d68563a7e1d6f7aa562d9cc9a489848c590908R66

#### 2c
- math.Powのソースコードを読んでみる
- 想像以上に複雑なことをしていた
- 特殊ケースを処理してから一般的なケースの計算をしている
- 特殊ケース
1. Pow(x, ±0) = 1 for any x
2. Pow(1, y) = 1 for any y
3. Pow(x, 1) = x for any x
4. Pow(NaN, y) = NaN
5. Pow(x, NaN) = NaN
	- 1~5はすぐ納得
6. Pow(±0, y) = ±Inf for y an odd integer < 0
	- 0の冪乗は0だと思っていたが、負の冪乗の場合は偶奇によって±Infになる
	- 負の冪乗は逆数と見ることができるが、分母を0にできないのでこうなるぽい
7. Pow(±0, -Inf) = +Inf
8. Pow(±0, +Inf) = +0
9. Pow(±0, y) = +Inf for finite y < 0 and not an odd integer
10. Pow(±0, y) = ±0 for y an odd integer > 0
11. Pow(±0, y) = +0 for finite y > 0 and not an odd integer
	- 6~11の0の冪乗の分類の解読は時間がかかった
	- なぜNaNではなくInfを返すのだろうと思ったのでそれぞれがIEEE 754でどのように定義されているかを調べる
		- InfとNaNの大きな違いは演算可能かどうか
	- 最下部CS欄にその他メモ記載
12. Pow(-1, ±Inf) = 1
13. Pow(x, +Inf) = +Inf for |x| > 1
14. Pow(x, -Inf) = +0 for |x| > 1
15. Pow(x, +Inf) = +0 for |x| < 1
16. Pow(x, -Inf) = +Inf for |x| < 1
17. Pow(+Inf, y) = +Inf for y > 0
18. Pow(+Inf, y) = +0 for y < 0
19. Pow(-Inf, y) = Pow(-0, -y)
20. Pow(x, y) = NaN for finite x < 0 and finite non-integer y
	- これはよくわからなかった

- 本体の解読は挫折した
	- step4で見返せるように特殊ケースの処理部分を除去したライブラリコードを貼っておく

```Go
func pow(x, y float64) float64 {
	if y == 0 {
		return 1
	}

	yi, yf := math.Modf(math.Abs(y))
	if yf != 0 && x < 0 {
		return math.NaN()
	}

	// ans = a1 * 2**ae (= 1 for now).
	a1 := 1.0
	ae := 0

	// ans *= x**yf
	if yf != 0 {
		if yf > 0.5 {
			yf--
			yi++
		}
		a1 = math.Exp(yf * math.Log(x))
	}

	// ans *= x**yi
	// by multiplying in successive squarings
	// of x according to bits of yi.
	// accumulate powers of two into exp.
	x1, xe := math.Frexp(x)
	for i := int64(yi); i != 0; i >>= 1 {
		if xe < -1<<12 || 1<<12 < xe {
			// catch xe before it overflows the left shift below
			// Since i !=0 it has at least one bit still set, so ae will accumulate xe
			// on at least one more iteration, ae += xe is a lower bound on ae
			// the lower bound on ae exceeds the size of a float64 exp
			// so the final call to Ldexp will produce under/overflow (0/Inf)
			ae += xe
			break
		}
		if i&1 == 1 {
			a1 *= x1
			ae += xe
		}
		x1 *= x1
		xe <<= 1
		if x1 < .5 {
			x1 += x1
			xe--
		}
	}

	// ans = a1*2**ae
	// if y < 0 { ans = 1 / ans }
	// but in the opposite order
	if y < 0 {
		a1 = 1 / a1
		ae = -ae
	}
	return math.Ldexp(a1, ae)
}
```

- 関数内部で使われていたヘルパー関数たちを自分で実装してみる

```Go
func IsNaN(f float64) bool {
	return f != f
}

func Signbit(f float64) bool {
	return math.Float64bits(f)&(1<<63) != 0
}

func isOddInt(x float64) bool {
	if math.Abs(x) >= (1 << 53) {
		return false
	}
	xi, xf := math.Modf(x) // math.Modfはfloat64型の数値を整数部と小数部に分ける
	return xf == 0 && int64(xi)&1 == 1
}
```

#### 2d
- 2cで調べた標準ライブラリの内部実装を参考に特殊ケースをちゃんと処理したもの
- nをfloat型に変換することによりnがMinIntの場合にも対応

```Go
func myPow(x float64, n int) float64 {
	switch {
	case n == 0 || x == 1:
		return 1
	case n == 1:
		return x
	case math.IsNaN(x):
		return math.NaN()
	case x == 0:
		switch {
		case n < 0:
			if math.Signbit(x) && n&1 == 1 {
				return math.Inf(-1)
			}
			return math.Inf(1)
		case n > 0:
			if math.Signbit(x) && n&1 == 1 {
				return x
			}
			return 0
		}
	case math.IsInf(x, 0):
		if math.IsInf(x, -1) {
			return myPow(1/x, -n)
		}
		switch {
		case n < 0:
			return 0
		case n > 0:
			return math.Inf(1)
		}
	}
	if n < 0 {
		n = -n
		x = 1 / x
	}
	return myPowFloat(x, float64(n))
}

func myPowFloat(x float64, y float64) float64 {
	if y == 0 {
		return 1
	}
	if y == 1 {
		return x
	}
	yi, _ := math.Modf(y)
	if int64(yi)%2 == 1 {
		return myPowFloat(x*x, y/2) * x
	}
	return myPowFloat(x*x, y/2)
}
```

### Step 3
```Go
func myPow(x float64, n int) float64 {
	switch {
	case n == 0:
		return 1
	case math.IsNaN(x):
		return math.NaN()
	case x == 0:
		switch {
		case n < 0:
			if math.Signbit(x) && n&1 == 1 {
				return math.Inf(-1)
			}
			return math.Inf(1)
		case n > 0:
			if math.Signbit(x) && n&1 == 1 {
				return x
			}
			return 0
		}
	case math.IsInf(x, 0):
		if math.IsInf(x, -1) {
			return myPow(1/x, -n)
		}
		switch {
		case n < 0:
			return 0
		case n > 0:
			return math.Inf(1)
		}
	}

	if n < 0 {
		n = -n
		x = 1 / x
	}
	accumulatedProduct := 1.0
	for {
		if n == 1 {
			return x * accumulatedProduct
		}
		if n&1 == 1 {
			accumulatedProduct *= x
		}
		x *= x
		n >>= 1
	}
}
```

### CS
- quotient: (和差積商の)商
- remainder: 割り算の余り
- base: x^n のx
- exponent: x^n のn
- Goの浮動小数点型はfloat64とfloat32の2種類で、デフォルトはfloat64。
つまり、`a := 1.0`はfloat64型として解釈される。
float型はない。
- operator: 演算子
- operand: 演算の対象となる値や変数
- IEEE 754
	- 特別な値たち
		- 0
			- sign: 0 or 1 で±0
			- exponent: 0
			- mantissa: 0
			- +0 == -0 が成り立つ
		- denormalized(非正規仮数)
			- 通常仮数部の前に1.が付くが、それを除くケース
			- つまり、仮数部が0.から始まりうる
			- これによって正規化数え表現可能な範囲より小さい値を表現できるようになる
			- exponent: 0
			- mantissa: 0以外
		- infinity
			- 正負がある
			- 演算が定義できる(NaNとの違い)
				- 例えば, `math.Inf(1) > 1.0`はtrue
				- `math.Inf(1) + math.Inf(1)`は+Inf
			- exponent: all 1
			- mantissa: 0
		- NaN(Not a Number)
			- エラーを表現する
			- exponent: all 1
			- mantissa: 0以外
		- https://www.geeksforgeeks.org/ieee-standard-754-floating-point-numbers/
	- 単精度: single-precision 32bit
	- 倍精度: double-precision 64bit