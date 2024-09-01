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
