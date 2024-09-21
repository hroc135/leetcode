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
- 空間計算量：O(mn)

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

- 他の方の回答を読む時間
- https://github.com/goto-untrapped/Arai60/pull/31/files#r1650006241
  - 再帰の深さについての分析
- https://discord.com/channels/1084280443945353267/1230079550923341835/1231038652327657492
  - このスレッドは得られる情報が多かった
  - step1のコードはmap(実質集合)で探索済みインデックスを管理しているが、gridと同じサイズの配列を用意して管理した方が速そう。下記にローカルで検証した結果を記載
  - 理由はハッシュの計算に時間がかかるから（もちろんめちゃくちゃ長いというわけではないだろうが）
  - 講師陣の方もmediumの問題で15分以上かかるものがある。分散がかなり大きそう。なので10分以内は一つの基準としつつ、時間にこだわりすぎない。それより実装中何を考えたかというところに意識を向けることがArai60の取り組みの本質のはず

- Union-Findデータ構造を使って解いてみる
- 前門の[200. Number of Islands](https://leetcode.com/problems/number-of-islands/description/)では木のランクによる最適化を行ったが、今回は、木の要素数が島の面積となるため、そちらを使って最適化する方法を実装する
- 参考：https://qiita.com/saka_pon/items/2f18c84f1b6834e4fe4a#union-by-size
- 実装後、以下リンク先を見て不要な条件を調べていることに気がついた
  - https://github.com/hayashi-ay/leetcode/pull/34/files#r1502553199

```Go
const (
	water = 0
	land  = 1
)

func maxAreaOfIsland(grid [][]int) int {
	if len(grid) == 0 {
		return -1 // better to do something like `return 0, errors.New()`
	}
	rowSize, columnSize := len(grid), len(grid[0])
	uff := initUnionFindForest(grid, rowSize, columnSize)
	maxArea := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] == water {
				continue
			}
			area := 1
			index := twoDimensionToOneDimension(r, c, columnSize)
			if r+1 < rowSize && c < columnSize && grid[r+1][c] == land {
				area = uff.union(index, twoDimensionToOneDimension(r+1, c, columnSize))
			}
			if r < rowSize && c+1 < columnSize && grid[r][c+1] == land {
				area = uff.union(index, twoDimensionToOneDimension(r, c+1, columnSize))
			}
			maxArea = max(maxArea, area)
		}
	}

	return maxArea
}

func twoDimensionToOneDimension(row, column, columnSize int) int {
	return row*columnSize + column
}

// A unionFindForest represents a union-find data structure with an one-dimensional slice.
type unionFindForest struct {
	// parents is a slice of indices of parent node index.
	// When parents[i] == i, i is the root of the tree.
	// parents[i] is -1 when i is the index of water in the grid.
	parents []int

	// elementCounts is a slice that holds the count of elements in the tree.
	// Only elementCounts[i], where i is the index of the root, is reliable.
	elementCounts []int
}

func initUnionFindForest(grid [][]int, rowSize, columnSize int) unionFindForest {
	parents := make([]int, rowSize*columnSize)
	elementCounts := make([]int, rowSize*columnSize)

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			index := twoDimensionToOneDimension(r, c, columnSize)
			if grid[r][c] == water {
				parents[index] = -1
				continue
			}
			parents[index] = index
			elementCounts[index] = 1
		}
	}

	return unionFindForest{parents: parents, elementCounts: elementCounts}
}

// union returns the number of elements in the united tree
func (uff *unionFindForest) union(i, j int) int {
	iRoot, jRoot := uff.find(i), uff.find(j)
	if iRoot == jRoot {
		return uff.elementCounts[iRoot]
	}

	if uff.elementCounts[iRoot] <= uff.elementCounts[jRoot] {
		uff.parents[iRoot] = jRoot
		uff.elementCounts[jRoot] += uff.elementCounts[iRoot]
		return uff.elementCounts[jRoot]
	} else {
		uff.parents[jRoot] = iRoot
		uff.elementCounts[iRoot] += uff.elementCounts[jRoot]
		return uff.elementCounts[iRoot]
	}
}

func (uff *unionFindForest) find(i int) int {
	j := i
	for j != uff.parents[j] {
		j = uff.parents[j]
	}
	uff.parents[i] = j // set the parent of i to the found root
	return j
}
```

### Step 3
- 最後はスタックによるDFSで実装
- 訪問済みかどうかは二次元配列のbool値で管理することに
- 集合で管理する方法と比べ、LeetCode上で実行時間と使用メモリ量ともに改善した
  - 実行時間が改善した理由として考えられることは、上述のようにハッシュを計算する時間が必要なくなったこと
  - 使用メモリ量が改善したのは、mapは再ハッシュしなくて済むよう多めにメモリを割り当てるから

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
		return 0
	}
	rowSize, columnSize := len(grid), len(grid[0])
	isVisitedLand := make([][]bool, rowSize)
	for r := 0; r < rowSize; r++ {
		isVisitedLand[r] = make([]bool, columnSize)
	}
	maxArea := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] == water {
				continue
			}
			src := index{row: r, column: c}
			area := computeIslandArea(src, grid, rowSize, columnSize, isVisitedLand)
			maxArea = max(maxArea, area)
		}
	}

	return maxArea
}

func computeIslandArea(src index, grid [][]int, rowSize, columnSize int, isVisitedLand [][]bool) int {
	landStack := []index{src}
	isVisitedLand[src.row][src.column] = true
	area := 1

	for len(landStack) > 0 {
		// pop from landStack
		n := len(landStack)
		top := landStack[n-1]
		landStack = landStack[:n-1]

		neighbors := []index{
			{row: top.row + 1, column: top.column},
			{row: top.row - 1, column: top.column},
			{row: top.row, column: top.column + 1},
			{row: top.row, column: top.column - 1},
		}
		for _, neighbor := range neighbors {
			r, c := neighbor.row, neighbor.column
			if !(0 <= r && r < rowSize && 0 <= c && c < columnSize) {
				continue
			}
			if grid[r][c] == water || isVisitedLand[r][c] {
				continue
			}
			landStack = append(landStack, neighbor)
			isVisitedLand[r][c] = true
			area++
		}
	}

	return area
}
```
