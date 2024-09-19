以下のコードはGoで書かれており、すべてデフォルトのフォーマッターであるgofmtにかけてあります。

### Step 1
- まず思いついた方針は、各島についてDFSをして島の面積を調べていく方法
- なぜBFSではなくDFSかというと、キューを用いるBFSは先頭要素のメモリ番地が変わっていくため、使用メモリが通算の要素数より大きくなってしまい、非効率だから
- 実装できたつもりが、テストケースを走らせると無限ループしてしまった
  - コードを読み返しても原因がわからなかったので、一晩寝てみることに。そして翌日、なぜかすぐに原因が見つかった
  - 原因はtraverseIsland関数の近傍を調べる部分で、`if _, ok := visitedLands[neighbor]; ok`とするべきところを`if _, ok := visitedLands[neighbor]; !ok`としてしまっていたこと
- 時間計算量：O(mn) (m,nはそれぞれgridの縦と横の長さ)
  - 一般的にDFSの時間計算量はO(V+E)と知られている。今回はVの最大値がmnで、Eは2mn未満であるので一つの島のDFSにかかる時間はO(mn)で抑えられる
  - 反対に、gridが全て海でも、gridの全てのインデックスを調べるのにO(mn)時間かかる
  - 今回は入力条件よりmnの最大値は2500である。DFSを再帰で実装すると、Goだと再帰回数の上限が定められていないので（環境には依存するが）できそう。ただし、確約はできない。Pythonだとデフォルトが1000回なので多めに設定してやる必要が生じる
- 空間計算量：O(

```Go
const (
	water = 0
	land  = 1
)

type index struct {
	row, column int
}

func maxAreaOfIsland(grid [][]int) int {
	if len(grid) == 0 {
		return -1 // better to do something like `return 0, errors.New("grid is empty")`
	}
	rowSize, columnSize := len(grid), len(grid[0])
	visitedLands := make(map[index]struct{}, rowSize*columnSize)
	maxArea := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if _, ok := visitedLands[index{row: r, column: c}]; grid[r][c] == land && !ok {
				islandArea := traverseIsland(r, c, rowSize, columnSize, grid, visitedLands)
				maxArea = max(maxArea, islandArea)
			}
		}
	}

	return maxArea
}

// traverseIsland traverses unvisited lands to get the area of the island.
// Traversed lands will be marked as visited.
func traverseIsland(row, column, rowSize, columnSize int, grid [][]int, visitedLands map[index]struct{}) int {
	landStack := []index{{row: row, column: column}}
	visitedLands[index{row: row, column: column}] = struct{}{}
	area := 1

	for len(landStack) > 0 {
		// pop from landStack
		l := len(landStack)
		top := landStack[l-1]
		landStack = landStack[:l-1]

		neighbors := [4]index{
			{row: top.row + 1, column: top.column},
			{row: top.row - 1, column: top.column},
			{row: top.row, column: top.column + 1},
			{row: top.row, column: top.column - 1},
		}
		for _, neighbor := range neighbors {
			if !(0 <= neighbor.row && neighbor.row < rowSize && 0 <= neighbor.column && neighbor.column < columnSize) {
				continue
			}
			if grid[neighbor.row][neighbor.column] == water {
				continue
			}
			if _, ok := visitedLands[neighbor]; ok {
				continue
			}
			area++
			landStack = append(landStack, neighbor)
			visitedLands[neighbor] = struct{}{}
		}
	}

	return area
}
```

### Step 2
- まずはstep1のコードを改善する
- 読み返して違和感を感じたのは、maxAreaOfIsland関数の2重ループ内の`islandArea := traverseIsland(r, c, rowSize, columnSize, grid, visitedLands)`の1行で、traverseIslandという関数名とislandAreaという出力が結びつかない
  - 関数名をcomputeIslandAreaとし、`area := computeIslandArea(.....)`とした
  - これなら島の面積を調べるということが一目でわかるという利点がある。DFSを使って調べるということについてはgodocに記載
- step1実装中に無限ループに陥った原因（言い訳）として、同じ意味のif文2箇所を異なる構成にしていたことが考えられる
  - 「同じ意味のif文2箇所」とは、maxAreaOfIsland関数の2重ループ内とcomputeIslandArea関数の近傍探索の部分
  - maxAreaOfIsland関数の方は、`if grid[r][c] == land && visitedLandsにindex{r, c}が含まれない { DFS }`としていたのに対し、
computeIslandArea関数内では、`if grid[r][c] == water { continue } if visitedLandsにindex{r, c}が含まれる { continue } それ以外の場合はスタックに追加`といった違いがあった
  - これを後者の順序に統一。なぜならearly returnぽいから
- step1のコードでvisitedLandsというマップをtraverseIsland関数に渡して変更を加え、その変更結果がmaxAreaOfIsland関数内でも反映されているという挙動について慣れていないしよく理解していないので調べて整理してみる
  - まず、Goのマップは関数に参照型として渡される（pass by reference)。これは値として渡されるケースとは異なり、参照型として渡されたものに対して関数内で加えられた変更は呼び出し元にも当然反映される
  - pass by referenceとpass by valueをよく理解していなかったが、以下の記事がわかりやすく解説してくれていた
    - https://david-yappeter.medium.com/golang-pass-by-value-vs-pass-by-reference-e48aac8b2716
  - Goのpass by referenceは、slice, map
  - Goのpass by valueは、int, floatなどの数値型、string, rune, array, struct

```Go
const (
	water = 0
	land  = 1
)

type index struct {
	row, column int
}

func maxAreaOfIsland(grid [][]int) int {
	if len(grid) == 0 {
		return -1 // better to do something like `return 0, errors.New()`
	}
	rowSize, columnSize := len(grid), len(grid[0])
	visitedLands := make(map[index]struct{}, rowSize*columnSize)
	maxArea := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] == water {
				continue
			}
			if _, ok := visitedLands[index{row: r, column: c}]; ok {
				continue
			}
			area := computeIslandArea(index{r, c}, rowSize, columnSize, grid, visitedLands)
			maxArea = max(maxArea, area)
		}
	}

	return maxArea
}

// computeIslandArea traverses unvisited lands using DFS to get the area of the island.
// Whenever a traversed land is pushed to DFS stack,
// that land will be immediately added to visitedLands map.
func computeIslandArea(src index, rowSize, columnSize int, grid [][]int, visitedLands map[index]struct{}) int {
	landStack := []index{src}
	visitedLands[src] = struct{}{}
	area := 1

	for len(landStack) > 0 {
		// pop from landStack
		l := len(landStack)
		top := landStack[l-1]
		landStack = landStack[:l-1]

		neighbors := [4]index{
			{row: top.row + 1, column: top.column},
			{row: top.row - 1, column: top.column},
			{row: top.row, column: top.column + 1},
			{row: top.row, column: top.column - 1},
		}
		for _, neighbor := range neighbors {
			if !(0 <= neighbor.row && neighbor.row < rowSize && 0 <= neighbor.column && neighbor.column < columnSize) {
				continue
			}
			if grid[neighbor.row][neighbor.column] == water {
				continue
			}
			if _, ok := visitedLands[neighbor]; ok {
				continue
			}
			landStack = append(landStack, neighbor)
			visitedLands[neighbor] = struct{}{}
			area++
		}
	}

	return area
}
```
