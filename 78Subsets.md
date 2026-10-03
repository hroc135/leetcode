問題: https://leetcode.com/problems/subsets/description/

### Step 1
- 前問 46. Permutations でバックトラックの練習をしたおかげで割とすぐに方針が立った。
- 下記のようなイメージ（左側がsubset, 右側が残りの追加可能な要素）
```
[] [1, 2, 3] 
├─ [1] [2, 3]
│  ├─ [1, 2] [3]
│  │  └─ [1, 2, 3] [] -> done
│  └─ [1, 3] [] -> done
|
├─ [2] [3]
│  ├─ [2, 3] [] -> done
|
└─ [3] [] -> done
```

```Go
func subsets(nums []int) [][]int {
    result := [][]int{}
    type subsetState struct {
        subset []int
        restNums []int
    }
    stack := []subsetState{}
    stack = append(stack, subsetState{[]int{}, nums})
    for len(stack) > 0 {
        top := stack[len(stack)-1]
        stack = stack[:len(stack)-1]
        result = append(result, top.subset)
        if len(top.restNums) == 0 {
            continue
        }
        for i := range top.restNums {
            nextSubset := slices.Concat(top.subset, []int{top.restNums[i]})
            nextRestNums := make([]int, len(top.restNums)-i-1)
            copy(nextRestNums, top.restNums[i+1:])
            stack = append(stack, subsetState{nextSubset, nextRestNums})
        }
    }
    return result
}
```

- 再帰

```Go
func subsets(nums []int) [][]int {
    result := [][]int{}
    var subsetsHelper func(subset []int, restNums []int)
    subsetsHelper = func(subset []int, restNums []int) {
        result = append(result, subset)
        if len(restNums) == 0 {
            return
        }
        for i := range restNums {
            nextSubset := slices.Concat(subset, []int{restNums[i]})
            nextRestNums := slices.Clone(restNums[i+1:])
            subsetsHelper(nextSubset, nextRestNums)
        }
    }
    subsetsHelper([]int{}, nums)
    return result
}
```

### Step 2
#### 2a
- https://github.com/hayashi-ay/leetcode/pull/63/files#diff-ddd8c09ee41837c8d5bde978403f850a0b08217fb8ec8eac6d0f2ae10e369d04R93
- nums[:i] の subsets をすべて生成し、nums[:i+1] の subsets を生成するのに使う方法
- nums=[0,1,2] の subsets がすべて挙げられていたら、nums=[0,1,2,3] の subsets はそれの末尾に 3 を加えたものを追加してやればよいだけ
- このやり方は手でやるときと同じ手順だから好き

```Go
func subsets(nums []int) [][]int {
    result := [][]int{{}}
    for _, n := range nums {
        for _, subset := range result {
            result = append(result, slices.Concat(subset, []int{n}))
        }
    }
    return result
}
```

#### 2b
- バックトラック
- https://github.com/olsen-blue/Arai60/pull/52/files#diff-ddd8c09ee41837c8d5bde978403f850a0b08217fb8ec8eac6d0f2ae10e369d04R141

| 0 | 1 | 2 | subset | operation |
| --- | --- | --- | --- | --- |
| 0 | 0 | 0 | [] | 再帰でindexをインクリメント |
| 0 | 0 | 1 | [2] | append(2) |
| 0 | 1 | 0 | [1] | pop(2), append(1) |
| 0 | 1 | 1 | [1,2] | append(2) |
| 1 | 0 | 0 | [0] | pop(2), pop(1), append(0) |
| 1 | 0 | 1 | [0,2] | append(2) |
| 1 | 1 | 0 | [0,1] | pop(2), append(1) |
| 1 | 1 | 1 | [0,1,2] | append(2) |

```Go
func subsets(nums []int) [][]int {
    result := [][]int{}
    subset := []int{}

    var traverseNums func(i int)
    traverseNums = func(i int) {
        if i == len(nums) {
            result = append(result, slices.Clone(subset))
            return
        }
        traverseNums(i + 1)
        subset = append(subset, nums[i])
        traverseNums(i + 1)
        subset = subset[:len(subset)-1]
    }

    traverseNums(0)
    return result
}
```

#### 2c
- 2bの再帰バックトラックをループに直してみる
- https://github.com/olsen-blue/Arai60/pull/52/files#diff-ddd8c09ee41837c8d5bde978403f850a0b08217fb8ec8eac6d0f2ae10e369d04R160

```Go
func subsets(nums []int) [][]int {
    result := [][]int{}
    type subsetBuilder struct {
        subset []int
        index int
    }
    stack := []subsetBuilder{}
    stack = append(stack, subsetBuilder{[]int{}, 0})
    for len(stack) > 0 {
        top := stack[len(stack)-1]
        stack = stack[:len(stack)-1]
        if top.index == len(nums) {
            result = append(result, top.subset)
            continue
        }
        stack = append(stack, subsetBuilder{top.subset, top.index+1})
        stack = append(stack, subsetBuilder{slices.Concat(top.subset, nums[top.index:top.index+1]), top.index+1})
    }
    return result
}
```

#### 2d
- 2a を再帰に直した
- 帰りがけに subsets を生成

```Go
func subsets(nums []int) [][]int {
    if len(nums) == 0 {
        return [][]int{{}}
    }
    prefixSubsets := subsets(nums[:len(nums)-1])
    subsetsWithNumsTail := [][]int{}
    for _, subset := range prefixSubsets {
        subsetsWithNumsTail = append(subsetsWithNumsTail, slices.Concat(subset, []int{nums[len(nums)-1]}))
    }
    return append(prefixSubsets, subsetsWithNumsTail...)
}
```

#### 2e
- 2d を末尾再帰最適化できるようにした
- ただし、Go コンパイラは末尾再帰を最適化しない

```Go
func subsets(nums []int) [][]int {
    var subsetsRecursive func(int, [][]int) [][]int
    subsetsRecursive = func(index int, subsetsBeforeIndex [][]int) [][]int {
        if index == len(nums) {
            return subsetsBeforeIndex
        }
        num := nums[index]
        subsetsIncludingNum := [][]int{}
        for _, subset := range subsetsBeforeIndex {
            subsetWithNum := slices.Concat(subset, []int{num})
            subsetsIncludingNum = append(subsetsIncludingNum, subsetWithNum)
        }
        return subsetsRecursive(index + 1, append(subsetsBeforeIndex, subsetsIncludingNum...))
    }

    return subsetsRecursive(0, [][]int{{}})
}
```

#### 2f
- https://github.com/olsen-blue/Arai60/pull/52/files#diff-ddd8c09ee41837c8d5bde978403f850a0b08217fb8ec8eac6d0f2ae10e369d04R10
- ビットで subset に含む/含まないを表現する方法
- 読んだとき、うお！となった
- subset は 2^n 通りあるが、それをビットで表現しようという頭になれれば自力で導けたはず
- 外側のループを `for bitMask := 0; bitMask < len(nums); bitMask++` と書いたら range を使えと analyzer に注意された。
range 使えなくね？と思ったらどうやら Go 1.22 から int 型に対しても for range を使えるようになったらしい
- https://go.dev/ref/spec#For_range
> A "for" statement with a "range" clause iterates through all entries of an array, slice, string or map, values received on a channel, integer values from zero to an upper limit [Go 1.22], or values passed to an iterator function's yield function [Go 1.23].

```Go
func subsets(nums []int) [][]int {
	result := [][]int{}
	for bitMask := range 1 << len(nums) {
		subset := []int{}
		for i, n := range nums {
			if bitMask&(1<<i) > 0 {
				subset = append(subset, n)
			}
		}
		result = append(result, subset)
	}
	return result
}
```

### Step 3
- 一番好きな 2a の解法を選択
- ただし、可読性を意識したら 2a よりだいぶ行数が増えた

```Go
func subsets(nums []int) [][]int {
    allSubsets := [][]int{}
    allSubsets = append(allSubsets, []int{})
    for _, n := range nums {
        subsetsWithTailN := [][]int{}
        for _, subset := range allSubsets {
            newSubset := slices.Concat(subset, []int{n})
            subsetsWithTailN = append(subsetsWithTailN, newSubset)
        }
        allSubsets = append(allSubsets, subsetsWithTailN...)
    }
    return allSubsets
}
```

### CS
- Shallow copy vs Deep copy
    - shallow: コピーされた要素は元のものと同じ参照を持つ
    - deep: 完全に新しいオブジェクトを生成する
    - Go の slices.Clone は shallow copy
        - 下記コードで ss を Clone すると、新しいスライスオブジェクト ssClone が生成されるが、
        ssClone[0] の参照先はスライス ss[0] と同じ
        - つまり、プリミティブな型のスライスの Clone は参照の共有がないが、
        そうでないもの（ex. 構造体、スライスのスライス）については参照が共有されているので注意が必要
```Go
ss := [][]int{{0, 1, 2}, {3, 4, 5}}
fmt.Printf("ss: %p, ss[0]: %p, ss[1]: %p\n", &ss, &ss[0], &ss[1])
fmt.Printf("ss[0][0]: %p\n", &ss[0][0])
ssClone := slices.Clone(ss)
fmt.Printf("ssClone: %p, ssClone[0]: %p, ssClone[1]: %p\n", &ssClone, &ssClone[0], &ssClone[1])
fmt.Printf("ssClone[0][0]: %p\n", &ssClone[0][0])
```
```
ss: 0xc000008030, ss[0]: 0xc00002a1b0, ss[1]: 0xc00002a1c8
ss[0][0]: 0xc0000141f8
ssClone: 0xc000008048, ssClone[0]: 0xc00002a1e0, ssClone[1]: 0xc00002a1f8
ssClone[0][0]: 0xc0000141f8
```