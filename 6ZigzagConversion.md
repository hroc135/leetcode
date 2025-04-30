問題: https://leetcode.com/problems/zigzag-conversion/description/

### Step 1
- 言われた通りに grid を埋めていき、最後に回収した
- 空間計算量: O(numRows * (len(s)/numRows))??
    - とにかく grid の大きさに依存することはわかるがしっかりとした見積もりはよくわからない
- 時間計算量: ？？
    - 外側のループは len(s) だけ回り、append で numRows の定数倍時間かかる
    - ただし、append で reallocate が起きる場合は grid の列数に依存するので空間計算量同様よくわからない

```Go
func convert(s string, numRows int) string {
	if len(s) <= numRows || numRows == 1 {
		return s
	}
	grid := make([][]byte, numRows)
	for i := range numRows {
		grid[i] = make([]byte, 1)
	}
	row := -1
	col := 0
	isUpwards := false
	for i := range s {
		switch isUpwards {
		case true:
			row--
			col++
			grid[row] = append(grid[row], make([]byte, numRows-1)...)
			grid[row][col] = s[i]
			if row == 0 {
				isUpwards = false
			}
		case false:
			row++
			grid[row][col] = s[i]
			if row == numRows-1 {
				isUpwards = true
				grid[row] = append(grid[row], make([]byte, numRows-1)...)
			}
		}
	}
	var sb strings.Builder
	for r := range len(grid) {
		for c := range len(grid[r]) {
			if grid[r][c] == 0 {
				continue
			}
			sb.WriteByte(grid[r][c])
		}
	}
	return sb.String()
}
```

- 他に考えられる解法
    - 外側のループを無限ループにし、内側で真下に進むものと斜め上に上げるものの二つのループを並べる方法
        - パフォーマンスは上と比較して変わらないが作業の様子は見やすいかも
    - 法則性を見つけて元の文字列から直接返還後のものを構築する方法

### Step 2
#### 2a
- 外側のループを無限ループにし、内側で真下に進むものと斜め上に上げるものの二つのループを並べる方法
- 実際書いてみたら外側が無限ループではダメだったので、sIndex が入力 s に対して範囲外アクセスをしないよう条件を付けた
    - 他の言語でいう while 文
- 下に行く時と斜め上に行く時を自分の中でしっかり定義したら初期値などの微調整をせずに済んだ
    - 肝は (0, 0) を斜め上に行くときとして見ること。
    (0, 0) ~ (numRows-1, 0) を下に行くときと見ると動作の一貫性がなくなって処理が面倒
```
斜　斜　斜
下斜下斜下
下　下　下
```

```Go
func convert(s string, numRows int) string {
	if numRows == 1 {
		return s
	}
	grid := make([][]byte, numRows)
	for r := range len(grid) {
		grid[r] = make([]byte, 1)
	}
	sIndex := 0
	row := 0
	col := 0
	for sIndex < len(s) {
		for ; row < numRows-1 && sIndex < len(s); row++ {
			grid[row][col] = s[sIndex]
			grid[row] = append(grid[row], make([]byte, numRows-1)...)
			sIndex++
		}
		if sIndex == len(s) {
			break
		}
		grid[numRows-1] = append(grid[numRows-1], make([]byte, numRows-1)...)
		for ; row > 0 && sIndex < len(s); row, col = row-1, col+1 {
			grid[row][col] = s[sIndex]
			sIndex++
		}
	}
	var sb strings.Builder
	charCount := 0
	for row := range len(grid) {
		for col := range len(grid[row]) {
			if charCount == len(s) {
				break
			}
			if grid[row][col] == 0 {
				continue
			}
			sb.WriteByte(grid[row][col])
			charCount++
		}
	}
	return sb.String()
}
```

#### 2b
- https://github.com/olsen-blue/Arai60/pull/61/files#diff-ccfa5b3e70552f7a1aea1f6a719cd00d74a1035c89cfab6426fddc4696ed3e21R180
    - 空白の部分は無視して row ごとに文字を繋げていって最後に row 順に全部繋げればいいだけ
    - あ、言われて見れば、、
- 今回は、2a とは違う進み方
```
下　下　下
下斜下斜下
斜　斜　斜
```
- こちらの方が自然な進み方だろう

```Go
func convert(s string, numRows int) string {
	if numRows == 1 || len(s) <= numRows {
		return s
	}
	rows := make([][]byte, numRows)
	row := 0
	isGoingDown := true
	for i := range len(s) {
		rows[row] = append(rows[row], s[i])
		switch isGoingDown {
		case true:
			row++
			if row == numRows-1 {
				isGoingDown = false
			}
		case false:
			row--
			if row == 0 {
				isGoingDown = true
			}
		}
	}
	var sb strings.Builder
	for _, r := range rows {
		for _, b := range r {
			sb.WriteByte(b)
		}
	}
	return sb.String()
}
```

- https://github.com/Ryotaro25/leetcode_first60/pull/66/files#r2024993518
    - なるほど
- https://github.com/Ryotaro25/leetcode_first60/pull/66/files#diff-6ba4653a2eea18b1cf3ddbdddaa49887ebd9e8498ec51081a56bbb5979aab7a3R12
    - 列数の計算方法
- https://github.com/saagchicken/coding_practice/pull/22/files#r2009990889
    - 何かライブラリ関数を使ったときに、さらっとでいいから他にどんなものがあるのか、周辺を眺める癖をつけよう
    - Go は若い言語のおかげでアップデートが結構ある

#### 2c
- https://github.com/saagchicken/coding_practice/pull/22/files#diff-641171eaccfc6c3f147cc8650b9302e2abf6fcaf35f2c3c35c8c6e0a4a83d31eR73
    - 面白い解法
    - なるほど、非同期処理で行番号を生成していくのか
    - 道案内人がいて、その人の指示に従ってせっせと文字を追加していく

```Go
func convert(s string, numRows int) string {
	if numRows == 1 || len(s) <= numRows {
		return s
	}

	rowChan := make(chan int)
	go func() {
		row := 0
		for {
			for row < numRows-1 {
				rowChan <- row
				row++
			}
			for row > 0 {
				rowChan <- row
				row--
			}
		}
	}()

	rows := make([][]byte, numRows)
	for i := range len(s) {
		r := <-rowChan
		rows[r] = append(rows[r], s[i])
	}
	var sb strings.Builder
	for _, row := range rows {
		for _, b := range row {
			sb.WriteByte(b)
		}
	}
	return sb.String()
}
```

### Step 3

```Go
func convert(s string, numRows int) string {
	if numRows == 1 || len(s) <= numRows {
		return s
	}
	rows := make([][]byte, numRows)
	row := 0
	isGoingDown := true
	for i := range s {
		rows[row] = append(rows[row], s[i])
		switch isGoingDown {
		case true:
			row++
			if row == numRows-1 {
				isGoingDown = false
			}
		case false:
			row--
			if row == 0 {
				isGoingDown = true
			}
		}
	}
	var sb strings.Builder
	for r := range rows {
        sb.Write(rows[r])
	}
	return sb.String()
}
```

- strings.Builder の内部実装を見た
    - buf []byte にバイトが溜められていくので、スライスと同様にキャパシティが足りなくなると動的にメモリを確保する
    - https://cs.opensource.google/go/go/+/refs/tags/go1.24.2:src/strings/builder.go;l=16
        - 非ゼロ値の strings.Builder オブジェクトをコピーすると、意図しないデータの共有・競合が起きてしまうのでダメ
        - コピーされてしまっていないかの確認は、`b.addr != b` (b は *Builder)。
        - コピー後の場合、b.addr はコピー元を指す

### CS