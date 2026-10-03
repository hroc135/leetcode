問題: https://leetcode.com/problems/unique-paths-ii/description/

### Step 1

- DPテーブルを作る方法でできそう
- 1次元でカウントする方法でもできそうだが、
まずは直感的にわかりやすい2次元で管理する方法で実装
- テストケース (入力 -> 期待される出力)
    - [] -> 0 (leetcodeの制約ではあり得ない入力)
    - [[]] -> 0
    - [[0]] -> 1
    - [[1]] -> 0
    - [[0,0]] -> 1
    - [[0],[0]] -> 1
    - [[0,0], [0,0]] -> 2
    - [[0,0], [0,1]] -> 0
    - [[0,0], [1,0]] -> 1
    - [[0,1], [0,0]] -> 1
    - [[1,0], [0,0]] -> 0
    - [[0,1], [1,0]] -> 0
    - [[0,1,0], [0,0,0], [1,0,0]] -> 2
        - このテストケースだけちょっとランダムに生成
- テストケースを考えると、pattern defeatingな処理も思いついたので、step2の2aで実装することに
- m: rowCount, n: rowCount
    - 時間計算量: O(mn)
    - 空間計算量: O(mn)

```Go
func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	rowCount := len(obstacleGrid)
	if rowCount == 0 {
		return 0
	}
	colCount := len(obstacleGrid[0])
	if colCount == 0 {
		return 0
	}
	pathCountGrid := make([][]int, rowCount)
	for i := range pathCountGrid {
		pathCountGrid[i] = make([]int, colCount)
	}

	for i := 0; i < rowCount; i++ {
		for j := 0; j < colCount; j++ {
			if obstacleGrid[i][j] == 1 {
				pathCountGrid[i][j] = 0
				continue
			}
			if i == 0 && j == 0 {
				pathCountGrid[0][0] = 1
				continue
			}
			p := 0
			if i-1 >= 0 {
				p += pathCountGrid[i-1][j]
			}
			if j-1 >= 0 {
				p += pathCountGrid[i][j-1]
			}
			pathCountGrid[i][j] = p
		}
	}
	return pathCountGrid[rowCount-1][colCount-1]
}
```

### Step 2
#### 2a
- https://github.com/hayashi-ay/leetcode/pull/44/files
	- `OBSTACLE = 1`としてマジックナンバーを解消
	- 値を受けると渡す話

```Go
func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	const (
		space    = 0
		obstacle = 1
	)

	rowCount := len(obstacleGrid)
	columnCount := len(obstacleGrid[0])
	paths := make([][]int, rowCount)
	for i := range paths {
		paths[i] = make([]int, columnCount)
	}

	for r := 0; r < rowCount; r++ {
		for c := 0; c < columnCount; c++ {
			if obstacleGrid[r][c] == obstacle {
				paths[r][c] = 0
				continue
			}
			if r == 0 && c == 0 {
				paths[0][0] = 1
				continue
			}
			if r > 0 {
				paths[r][c] += paths[r-1][c]
			}
			if c > 0 {
				paths[r][c] += paths[r][c-1]
			}
		}
	}
	return paths[rowCount-1][columnCount-1]
}
```

#### 2b
- pattern defeating
- 以下の入力で瞬時に0を返したい
    - [[1,...],...]
    - [[0,1,...],[1,...],...]
    - [...,[...,1]]
    - [...,[...,1],[...,1,0]]
- gridの大きさが1×1の時にobstacleGrid[0][0]が0なら1を、1なら0を返したかったので、
ビット演算で表現できそうだと思ったが、分からなかったのでgptに聞いた
    - XORを使いたい気持ちになったが、実装の仕方が分からなかった
    - ^num & 0b1
    - ^: XOR。numが1なら^numで0b11...10になる
    - このままだと負の数が帰ってしまうので、1bit分のANDを取る
    - gptは^num & 0x01というコードを書いたが、
    16進数でANDを取るより2進数で取った方が直感に反しないので変えた

```Go
func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	if obstacleGrid[0][0] == 1 {
		return 0
	}
	rowCount := len(obstacleGrid)
	colCount := len(obstacleGrid[0])
	if rowCount == 1 && colCount == 1 {
		return ^obstacleGrid[0][0] & 0b1
	}
	if obstacleGrid[rowCount-1][colCount-1] == 1 {
		return 0
	}
	// gridの始点(0,0)から進められるマスが全て障害である場合、0を返す
	if (rowCount <= 1 || obstacleGrid[1][0] == 1) && (colCount <= 1 || obstacleGrid[0][1] == 1) {
		return 0
	}
	// gridの終点へ進められるマスが全て障害である場合、0を返す
	if (rowCount <= 1 || obstacleGrid[rowCount-2][colCount-1] == 1) && (colCount <= 1 || obstacleGrid[rowCount-1][colCount-2] == 1) {
		return 0
	}
	pathCountGrid := make([][]int, rowCount)
	for i := range pathCountGrid {
		pathCountGrid[i] = make([]int, colCount)
	}

	for i := 0; i < rowCount; i++ {
		for j := 0; j < colCount; j++ {
			if obstacleGrid[i][j] == 1 {
				pathCountGrid[i][j] = 0
				continue
			}
			if i == 0 && j == 0 {
				pathCountGrid[0][0] = 1
				continue
			}
			p := 0
			if i-1 >= 0 {
				p += pathCountGrid[i-1][j]
			}
			if j-1 >= 0 {
				p += pathCountGrid[i][j-1]
			}
			pathCountGrid[i][j] = p
		}
	}
	return pathCountGrid[rowCount-1][colCount-1]
}
```

#### 2c
- DPテーブルでなく、一次元配列で管理する方法
- 空間計算量がO(n)に改善 (n: len(obstacleGrid[i]))

```Go
func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	rowCount := len(obstacleGrid)
	colCount := len(obstacleGrid[0])
	pathCounts := make([]int, colCount)
	for r := 0; r < rowCount; r++ {
		for c := 0; c < colCount; c++ {
			if r == 0 && c == 0 {
				pathCounts[c] = ^obstacleGrid[0][0] & 0b0001
				continue
			}
			if obstacleGrid[r][c] == 1 {
				pathCounts[c] = 0
				continue
			}
			if c == 0 {
				continue
			}
			pathCounts[c] += pathCounts[c-1]
		}
	}
	return pathCounts[colCount-1]
}
```

#### 2d
- 一次元DPで空間計算量をO(min(m,n))にするためにgridの転置をする方法
- 参考: https://github.com/TORUS0818/leetcode/pull/36/files#diff-f82359abd738e30b5de0c5be2f4904290a10e568766768732c87df2fdaa6cceeR110

```Go
func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	const obstacle = 1

	isObstacle := func(row, column int, isTransposed bool) bool {
		if isTransposed {
			return obstacleGrid[column][row] == obstacle
		}
		return obstacleGrid[row][column] == obstacle
	}

	rowCount := len(obstacleGrid)
	columnCount := len(obstacleGrid[0])
	isTransposed := false
	if rowCount < columnCount {
		rowCount, columnCount = columnCount, rowCount
		isTransposed = true
	}
	paths := make([]int, columnCount)
	for r := 0; r < rowCount; r++ {
		for c := 0; c < columnCount; c++ {
			if isObstacle(r, c, isTransposed) {
				paths[c] = 0
				continue
			}
			if r == 0 && c == 0 {
				paths[0] = 1
				continue
			}
			if c > 0 {
				paths[c] += paths[c-1]
			}
		}
	}
	return paths[columnCount-1]
}
```

#### 2e
- メモ付き再帰
- メモとしてrowとcolumnの組みをキーとするmapを作成しようと思ったが、
キーの型として構造体`struct{ row int, column int}`か長さ2のarrayの選択肢がある
	- mapのキーは比較演算子を使える型でないといけないが、
	調べたところいずれも比較演算子を使えることがわかった(https://go.dev/ref/spec#Comparison_operators)
		- 構造体: すべてのフィールドが比較可能なものである場合に限り、比較可能
		- array: 要素の型が比較可能なものである場合に限り、比較可能
	- rowとcolumnの組みはよく出てくるものなので明示的に構造体を作らなくても
	コメントさえつければarrayでも十分に読み手に意図が伝わると思った
	- 一方、gridを扱うようなプログラムがあるならリポジトリの別の箇所で`struct{ row int, column int}`
	くらい既に定義されていてもおかしくないとも思い、こちらで書くことにした
- IsNonNegative, Up, Leftは面接の場では多分自分で書かずに存在を仮定してしまってもいいもの
- これでいけると思ったらTLE。
構造体作る処理が重いのかなと思ってよく見返したらメモへの記録を忘れていただけだった
- 時間・空間計算量ともにO(mn)
- 参考: https://github.com/TORUS0818/leetcode/pull/36/files#diff-f82359abd738e30b5de0c5be2f4904290a10e568766768732c87df2fdaa6cceeR82

- これでいけると思ったらTLE
```Go
type Coordinate struct {
	Row    int
	Column int
}

func (coord Coordinate) IsNonNegative() bool {
	return coord.Row >= 0 && coord.Column >= 0
}

func (coord Coordinate) Up() Coordinate {
	return Coordinate{coord.Row - 1, coord.Column}
}

func (coord Coordinate) Left() Coordinate {
	return Coordinate{coord.Row, coord.Column - 1}
}

func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	const obstacle = 1

	pathCountMemo := make(map[Coordinate]int)
	var uniquePathsWithObstaclesHelper func(Coordinate) int
	uniquePathsWithObstaclesHelper = func(coord Coordinate) int {
		if !coord.IsNonNegative() {
			return 0
		}
		if v, found := pathCountMemo[coord]; found {
			return v
		}
		row, col := coord.Row, coord.Column
		if obstacleGrid[row][col] == obstacle {
			pathCountMemo[coord] = 0
			return 0
		}
		if coord.Row == 0 && coord.Column == 0 {
			pathCountMemo[coord] = 1
			return 1
		}
		pathCount := uniquePathsWithObstaclesHelper(coord.Up()) + uniquePathsWithObstaclesHelper(coord.Left())
		pathCountMemo[coord] = pathCount
		return pathCount
	}

	rowCount := len(obstacleGrid)
	columnCount := len(obstacleGrid[0])
	return uniquePathsWithObstaclesHelper(Coordinate{rowCount - 1, columnCount - 1})
}
```

### Step 3
- 1次元DP
- pattern defeatingな早期リターンや転置による最適化はしていない

```Go
func uniquePathsWithObstacles(obstacleGrid [][]int) int {
	const obstacle = 1
	rowCount := len(obstacleGrid)
	columnCount := len(obstacleGrid[0])
	pathCounts := make([]int, columnCount)
	for r := 0; r < rowCount; r++ {
		for c := 0; c < columnCount; c++ {
			if obstacleGrid[r][c] == obstacle {
				pathCounts[c] = 0
				continue
			}
			if r == 0 && c == 0 {
				pathCounts[0] = 1
				continue
			}
			if c == 0 {
				continue
			}
			pathCounts[c] += pathCounts[c-1]
		}
	}
	return pathCounts[columnCount-1]
}
```