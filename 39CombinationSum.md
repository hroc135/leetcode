問題: https://leetcode.com/problems/combination-sum/description/

### Step 1
- 前問の subsets の和を見ればいいだけじゃないかと思いきや要素の重複を許さないといけないだと？
- とりあえず手元でやってみる。手元でやれることをコンピュータにやらせる
- これも greedy に新しい組み合わせを作っていけばよい
- スタックを使おうか
    - > 箱に「これからしなきゃいけない内容の書かれた紙」を入れていって箱が空になったら終わり
        - https://discordapp.com/channels/1084280443945353267/1233603535862628432/1238707903196565546
- 箱に入れてほしい情報は何か？
作りかけの組み合わせ、その組み合わせの累積和、最後に加えられた要素のインデックスはどれか（これより前のインデックスは組み合わせに足さなくてよくなった）
- 時間計算量: O(target^n)?
    - これどうやって評価したらいいんだ？
    - subset は全部で 2^n 通り
    - candidates[i]=1 としたら、candidates[i] を 0~target 個含む場合が考えられる（target 通り）
    - なので時間計算量は O(target^n)?
    - 分割数で抑えられるらしい（https://discord.com/channels/1084280443945353267/1233295449985650688/1242067855579545611）
- 空間計算量: O(target * target^n)?
    - combination の長さが target になりうるので

```Go
func combinationSum(candidates []int, target int) [][]int {
	result := [][]int{}
	type combinationBuilder struct {
		combination    []int
		sum            int
		lastAddedIndex int
	}
	stack := []combinationBuilder{}
	for i, can := range candidates {
		if can <= target {
			stack = append(stack, combinationBuilder{[]int{can}, can, i})
		}
	}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if top.sum == target {
			result = append(result, top.combination)
			continue
		}
		for i := top.lastAddedIndex; i < len(candidates); i++ {
			if top.sum+candidates[i] <= target {
				newCombination := slices.Concat(top.combination, []int{candidates[i]})
				stack = append(stack, combinationBuilder{newCombination, top.sum + candidates[i], i})
			}
		}
	}
	return result
}
```

### Step 2
#### 2a
- step1 の修正
- step1 では candidates[i] > 0 という leetcode の制約が candidates[i] >= 0 になってもいいようにと思い、
top.sum == target となってもすぐには result に追加せず stack に入れて泳がしていた
    - が、よく考えたら candidates[i] = 0 の場合にどうする？0無限に含めれちゃうよ？という問題が生じるのでそうしなくてよさそう
- stack の初期値設定ももっとシンプルにした

```Go
func combinationSum(candidates []int, target int) [][]int {
    result := [][]int{}
    type combinationBuilder struct {
        combination []int
        sum int
        lastAddedIndex int
    }
    stack := []combinationBuilder{{[]int{}, 0, 0}}
    for len(stack) > 0 {
        top := stack[len(stack)-1]
        combination, sum, lastAddedIndex := top.combination, top.sum, top.lastAddedIndex
        stack = stack[:len(stack)-1]
        for i := lastAddedIndex; i < len(candidates); i++ {
            can := candidates[i]
            if sum+can == target {
                result = append(result, slices.Concat(combination, []int{can}))
                continue
            }
            if sum+candidates[i] < target {
                nextCombination := slices.Concat(combination, []int{can})
                stack = append(stack, combinationBuilder{nextCombination, sum+can, i})
            }
        }
    }
    return result
}
```

#### 2b
- 2a を再帰に直した
- 条件分岐の書き方が納得いかない
- https://github.com/fhiyo/leetcode/pull/52/files#diff-28c318778976f05919552531da3ec8c28ff86155cf38e57128246b935d3927fbR125
    - candidates をソートすることにより、ループを途中で打ち切れるようにしている

```Go
func combinationSum(candidates []int, target int) [][]int {
    result := [][]int{}

    var combinationSumHelper func([]int, int, int)
    combinationSumHelper = func(combination []int, combinationSum int, lastAddedIndex int) {
        for i := lastAddedIndex; i < len(candidates); i++ {
            can := candidates[i]
            newCombinationSum := can + combinationSum
            switch {
            case newCombinationSum == target:
                newCombination := slices.Concat(combination, []int{can})
                result = append(result, newCombination)
            case newCombinationSum < target:
                newCombination := slices.Concat(combination, []int{can})
                combinationSumHelper(newCombination, newCombinationSum, i)
            }
        }
    }

    combinationSumHelper([]int{}, 0, 0)
    return result
}
```

#### 2c
- A以降しか使ってはいけない状況下で、Aを1つ足すかB以降しか使わないかの2択で考える
    - https://github.com/fhiyo/leetcode/pull/52#discussion_r1690161771
    - リンク先の1番
```
candidates=[2,3,4], target=7
(インデックスx以降しか使ってはいけない, combination, combinationの累積和)
(0, [], 0)
├ (0, [2], 2)
|    ├ (0, [2,2], 4)
|    |    ├ (0, [2,2,2], 6)
|    |    |    ├ (0, [2,2,2,2], 8) ×
|    |    |    └ (1, [2,2,2], 6)
|    |    |         ├ (1, [2,2,2,3], 9) ×
|    |    |         └ (2, [2,2,2], 6)
|    |    |              ├ (2, [2,2,2,4], 10) ×
|    |    |              └ (3, [2,2,2], 6)
|    |    |                   └ ×
|    |    └ (1, [2,2], 4)
|    |         ├ (1, [2,2,3], 7) 〇
|    |         └ (2, [2,2], 4)
...
└ (1, [], 0)
```

```Go
func combinationSum(candidates []int, target int) [][]int {
    result := [][]int{}

    var combinationSumHelper func(int, []int, int)
    combinationSumHelper = func(candidatesStartIndex int, combination []int, sumCombination int) {
        if sumCombination == target {
            result = append(result, combination)
            return
        }
        if candidatesStartIndex == len(candidates) {
            return
        }
        can := candidates[candidatesStartIndex]
        newSumCombination := sumCombination + can
        if newSumCombination <= target {
            newCombination := slices.Concat(combination, []int{can})
            combinationSumHelper(candidatesStartIndex, newCombination, newSumCombination)
        }
        combinationSumHelper(candidatesStartIndex+1, combination, sumCombination)
    }

    combinationSumHelper(0, []int{}, 0)
    return result
}
```

#### 2d
- 2c をループに直す

```Go
func combinationSum(candidates []int, target int) [][]int {
	result := [][]int{}
	type combinationBuilder struct {
		combination    []int
		combinationSum int
		fromIndex      int
	}
	stack := []combinationBuilder{}
	stack = append(stack, combinationBuilder{[]int{}, 0, 0})
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		combination, combinationSum, fromIndex := top.combination, top.combinationSum, top.fromIndex
		if fromIndex == len(candidates) {
			continue
		}
		if combinationSum == target {
			result = append(result, combination)
			continue
		}
		can := candidates[fromIndex]
		if combinationSum+can <= target {
			newCombination := slices.Concat(combination, []int{can})
			newCombinationSum := combinationSum + can
			stack = append(stack, combinationBuilder{newCombination, newCombinationSum, fromIndex})
		}
		stack = append(stack, combinationBuilder{combination, combinationSum, fromIndex + 1})
	}
	return result
}
```

#### 2e
- candidates=[2,3,4], target=7 として、最初に 2 を何個含めるかで場合分けする方法
    - https://github.com/fhiyo/leetcode/pull/52#discussion_r1690161771
    - リンク先の2番

```Go
func combinationSum(candidates []int, target int) [][]int {
	result := [][]int{}

	var traverseCombinations func(int, []int, int)
	traverseCombinations = func(candidatesStartIndex int, combination []int, sumCombination int) {
		if sumCombination == target {
			result = append(result, combination)
			return
		}
		if candidatesStartIndex == len(candidates) {
			return
		}
		traverseCombinations(candidatesStartIndex+1, combination, sumCombination)
		can := candidates[candidatesStartIndex]
		newCombination := slices.Clone(combination)
		for newSumCombination := sumCombination + can; newSumCombination <= target; newSumCombination += can {
			newCombination = slices.Concat(newCombination, []int{can})
			traverseCombinations(candidatesStartIndex+1, newCombination, newSumCombination)
		}
	}

	traverseCombinations(0, []int{}, 0)
	return result
}
```

#### 2f
- 2e をループに直す

```Go
func combinationSum(candidates []int, target int) [][]int {
	combinations := [][]int{}
	type combinationBuilder struct {
		combination    []int
		combinationSum int
		addIndex       int
	}
	stack := []combinationBuilder{}
	stack = append(stack, combinationBuilder{[]int{}, 0, 0})
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		combination, combinationSum, addIndex := top.combination, top.combinationSum, top.addIndex
		if combinationSum == target {
			combinations = append(combinations, combination)
			continue
		}
		if addIndex == len(candidates) {
			continue
		}
		newCombination := slices.Clone(combination)
		stack = append(stack, combinationBuilder{newCombination, combinationSum, addIndex + 1})
		can := candidates[addIndex]
		for newCombinationSum := combinationSum + can; newCombinationSum <= target; newCombinationSum += can {
			newCombination = slices.Concat(newCombination, []int{can})
			stack = append(stack, combinationBuilder{newCombination, newCombinationSum, addIndex + 1})
		}
	}
	return combinations
}
```

#### 2g
- DP
    - https://github.com/fhiyo/leetcode/pull/52#issuecomment-2248269934

```Go
func combinationSum(candidates []int, target int) [][]int {
	sumToCombinations := make([][][]int, target+1)
	sumToCombinations[0] = append(sumToCombinations[0], []int{})
	for _, can := range candidates {
		for sum := can; sum <= target; sum++ {
			for _, combination := range sumToCombinations[sum-can] {
				sumToCombinations[sum] = append(sumToCombinations[sum], slices.Concat(combination, []int{can}))
			}
		}
	}
	return sumToCombinations[target]
}
```

### Step 3

```Go
func combinationSum(candidates []int, target int) [][]int {
	combinations := [][]int{}
	type combinationBuilder struct {
		combination     []int
		sum             int
		candidatesIndex int
	}
	stack := []combinationBuilder{{[]int{}, 0, 0}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		combination, sum, candidatesIndex := top.combination, top.sum, top.candidatesIndex
		if sum == target {
			combinations = append(combinations, combination)
			continue
		}
		if candidatesIndex == len(candidates) {
			continue
		}
		can := candidates[candidatesIndex]
		if newSum := sum + can; newSum <= target {
			newCombination := slices.Concat(combination, []int{can})
			stack = append(stack, combinationBuilder{newCombination, newSum, candidatesIndex})
		}
		stack = append(stack, combinationBuilder{combination, sum, candidatesIndex + 1})
	}
	return combinations
}
```

### CS