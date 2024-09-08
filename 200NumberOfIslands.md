以下のコードはGoで書かれており、すべてデフォルトのフォーマッターであるgofmtにかけてあります。

### Step 1
- '1'をグラフ探索の要領で調べていけば良い
- DFSの方がBFSより速いと聞いたことがあるのでDFSを使うことに。（後で真偽を確かめよう）
- DFSは再帰で実装（スタックでもできる）
- 10分ほどでコードを書き上げて提出したが、以下のテストケースに引っかかった
```
[["1","1","1"],
["0","1","0"],
["1","1","1"]]
```
- 原因はDFSで(x+1, y)と(x, y+1)に対してしか再帰を呼び出しておらず、(x-1, y)と(x, y-1)を探索していなかったから
- これを修正してひとまずAC
- 時間計算量：O(mn)??（あまり自信がない。numIslands関数にm*nの二重ループがあり、DFSはたかだかO(x+y)なのでこうした）
- 空間計算量：??（再帰が絡む時の計算量の算出がわからない、、。以前解説をdiscordで見かけたような気がするので探してみる）

```Go
func numIslands(grid [][]byte) int {
	visitedLandIdx := make(map[[2]int]struct{}, len(grid)*len(grid[0]))
	islands := 0
	for i := 0; i < len(grid); i++ {
		for j := 0; j < len(grid[0]); j++ {
			if grid[i][j] == '0' {
				continue
			}
			if _, ok := visitedLandIdx[[2]int{i, j}]; ok {
				continue
			}

			visitedLandIdx = landDfs(i, j, grid, visitedLandIdx)
			islands++
		}
	}

	return islands
}

func landDfs(x, y int, grid [][]byte, visitedLandIdx map[[2]int]struct{}) map[[2]int]struct{} {
	if grid[x][y] == '0' {
		return visitedLandIdx
	}
	if _, ok := visitedLandIdx[[2]int{x, y}]; ok {
		return visitedLandIdx
	}

	visitedLandIdx[[2]int{x, y}] = struct{}{}
	if x+1 < len(grid) {
		visitedLandIdx = landDfs(x+1, y, grid, visitedLandIdx)
	}
	if x-1 >= 0 {
		visitedLandIdx = landDfs(x-1, y, grid, visitedLandIdx)
	}
	if y+1 < len(grid[0]) {
		visitedLandIdx = landDfs(x, y+1, grid, visitedLandIdx)
	}
	if y-1 >= 0 {
		visitedLandIdx = landDfs(x, y-1, grid, visitedLandIdx)
	}

	return visitedLandIdx
}
```

### Step 2

#### 2a (スタックを使ったDFS)
- 他の方のプルリクで再帰の深さについての指摘があった
  - Goは再帰回数の上限が定められておらず、環境依存だが、最大9e4回再帰するということを考えると賢明な選択ではないだろう
  - DFSはスタックでも実装でき、こちらならスタックオーバーフローを防ぐことができる
- '0', '1'をそれぞれ定数water, landとして定義することによってマジックナンバーに見えないようにする
- DFS関数内の近傍インデックスを探索する部分を関数化
  - nested関数として定義したので、親関数の引数も内部で使うことができ、引数を2つだけにすることができた。この方が個人的に見やすい
  - nested関数でなければ、`func traverseNeighbors(r, c, rowSize, columnSize int, grid [][]byte, isVisitedLand [][]bool) bool`となってしまう
- 入力条件で len(grid) > 0 が保証されてはいるが、スライスの長さを確かめずにgrid[0]を参照することに抵抗を感じたので先に長さを調べることに

```Go
const (
	water         = '0'
	unvisitedLand = '1'
	visitedLand   = '2'
)

func numIslands(grid [][]byte) int {
	if len(grid) == 0 {
        	log.Fatal("length of grid is 0")
    	}
	rowSize, columnSize := len(grid), len(grid[0])
	islands := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] != unvisitedLand {
				continue
			}

			grid = markIslandVisited(r, c, rowSize, columnSize, grid)
			islands++
		}
	}

	return islands
}

// markIslandVisited uses DFS to traverse unvisited island
func markIslandVisited(srcRow, srcColumn, rowSize, columnSize int, grid [][]byte) [][]byte {
	idxStack := [][2]int{{srcRow, srcColumn}}
	grid[srcRow][srcColumn] = visitedLand

	traverseNeighbors := func(r, c int) {
		neighborIdxs := [4][2]int{
			{r + 1, c},
			{r - 1, c},
			{r, c + 1},
			{r, c - 1},
		}
		for _, idxs := range neighborIdxs {
			nr, nc := idxs[0], idxs[1]
			if !(0 <= nr && nr < rowSize && 0 <= nc && nc < columnSize) {
				continue
			}
			if grid[nr][nc] != unvisitedLand {
				continue
			}

			idxStack = append(idxStack, [2]int{nr, nc})
			grid[nr][nc] = visitedLand
		}
	}

	for len(idxStack) > 0 {
		// pop from idxStack
		peek := idxStack[len(idxStack)-1]
		peekRow, peekCol := peek[0], peek[1]
		idxStack = idxStack[:len(idxStack)-1]

		traverseNeighbors(peekRow, peekCol)
	}

	return grid
}
```

#### 2b (BFS)
- BFSでも解いてみる
- 「これでいけるはず！」というコードを提出してMemory Limit Exceededとなってしまった
  - 走査済みかどうかを入力値gridを書き換えていくことで新しく2次元配列を用意する必要をなくしたが、変わらずMemory Limit Exceeded
  - 原因を時間をかけて探すがなかなか見つからない
  - ついに諦めてChatGPTに聞いてみる
  - 原因は、セルをvisitedLandに変えるタイミングがキューから取り出した時になっており、同じインデックスが重複してキューに追加されてしまっていたこと
  - キューに加える時にvisitedLandの印を付けるように変更したらAC
  - DFSの方の回答にも当てはまるので2aも修正する（上記コードは修正後のもの）

```Go
const (
	water         = '0'
	unvisitedLand = '1'
	visitedLand   = '2'
)

func numIslands(grid [][]byte) int {
	if len(grid) == 0 {
        	log.Fatal("length of grid is 0")
    	}
	rowSize, columnSize := len(grid), len(grid[0])
	islands := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] != unvisitedLand {
				continue
			}

			grid = markIslandVisited(r, c, rowSize, columnSize, grid)
			islands++
		}
	}

	return islands
}

// markIslandVisited uses BFS to traverse unvisited island
func markIslandVisited(srcRow, srcColumn, rowSize, columnSize int, grid [][]byte) [][]byte {
	idxQueue := [][2]int{{srcRow, srcColumn}}
	grid[srcRow][srcColumn] = visitedLand

	traverseNeighbors := func(r, c int) {
		neighborIdxs := [4][2]int{
			{r + 1, c},
			{r - 1, c},
			{r, c + 1},
			{r, c - 1},
		}
		for _, idxs := range neighborIdxs {
			nr, nc := idxs[0], idxs[1]
			if !(0 <= nr && nr < rowSize && 0 <= nc && nc < columnSize) {
				continue
			}
			if grid[nr][nc] != unvisitedLand {
				continue
			}

			idxQueue = append(idxQueue, [2]int{nr, nc})
			grid[nr][nc] = visitedLand
		}
	}

	for len(idxQueue) > 0 {
		head := idxQueue[0]
		headRow, headCol := head[0], head[1]
		idxQueue = idxQueue[1:]

		traverseNeighbors(headRow, headCol)
	}

	return grid
}
```

#### 2c (union-find)
- 他の方の回答でunion-findを使った方法を散見したので試してみることに
- 聞き慣れないアルゴリズムなのでまずは以下の記事を参考に中身を理解する
  - https://en.wikipedia.org/wiki/Disjoint-set_data_structure
  - https://qiita.com/saka_pon/items/2f18c84f1b6834e4fe4a
- https://github.com/seal-azarashi/leetcode/pull/17/files で、unionfindクラスのメンバであるparentsとranksを一次元配列とし、連続したメモリ領域を使用できるよう工夫していたので真似することに
- つまずいたところは、unionメソッドの最後にuf.countをデクリメントしていたつもりが、コードを走らせてもuf.countの初期値が返ってきて、デクリメントされていなかった
  - 原因は、レシーバーをunionfindの値にしていたことで、unionfindのポインタでないと、unionfindの中のint型の値を上書きすることができない
- union-findはエンジニアの常識に含まれていないと思ったので、丁寧にコメントを残すことにする

```Go
const (
	water = '0'
	land  = '1'
)

func numIslands(grid [][]byte) int {
	if len(grid) == 0 {
		log.Fatal("length of grid is 0")
	}
	rowSize, columnSize := len(grid), len(grid[0])

	uf := initUnionFind(grid)

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] != land {
				continue
			}
			if r+1 < rowSize && grid[r+1][c] == land {
				uf.union(twoDimensionToOneDimension(r, c, columnSize), twoDimensionToOneDimension(r+1, c, columnSize))
			}
			if c+1 < columnSize && grid[r][c+1] == land {
				uf.union(twoDimensionToOneDimension(r, c, columnSize), twoDimensionToOneDimension(r, c+1, columnSize))
			}
		}
	}

	return uf.count
}

func twoDimensionToOneDimension(r, c, columnSize int) int {
	return r*columnSize + c
}

type unionfind struct {
	parents []int
	ranks   []int // rank of the root is 0
	count   int
}

func initUnionFind(grid [][]byte) unionfind {
	rowSize, columnSize := len(grid), len(grid[0])
	parents := make([]int, rowSize*columnSize)
	ranks := make([]int, rowSize*columnSize)
	count := 0

	for r := 0; r < rowSize; r++ {
		for c := 0; c < columnSize; c++ {
			if grid[r][c] == water {
				continue
			}
			idx := twoDimensionToOneDimension(r, c, columnSize)
			parents[idx] = idx
			count++
		}
	}

	return unionfind{parents: parents, ranks: ranks, count: count}
}

func (uf *unionfind) union(i, j int) {
	iRoot, jRoot := uf.find(i), uf.find(j)
	if iRoot == jRoot {
		return
	}

	switch {
	case uf.ranks[iRoot] < uf.ranks[jRoot]:
		uf.parents[iRoot] = jRoot

	case uf.ranks[iRoot] > uf.ranks[jRoot]:
		uf.parents[jRoot] = iRoot

	case uf.ranks[iRoot] == uf.ranks[jRoot]:
		uf.parents[jRoot] = iRoot
		uf.ranks[iRoot]++
	}

	uf.count--
}

// find returns the index of the root of the given index
func (uf unionfind) find(i int) int {
	for i != uf.parents[i] {
		i = uf.parents[i]
	}
	return i
}
```

