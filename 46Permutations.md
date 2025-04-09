問題: https://leetcode.com/problems/permutations/description/

### Step 1
- 長さ1,2,3のスライスに対する操作は実装できそうで
それを拡張して一般的な方法を実装すればよさそうと思ったが拡張する方法が思いつかなかった
- とりあえず長さ1,2,3で動くコードを書いてみる

```Go
func permute(nums []int) [][]int {
    switch {
    case len(nums) == 0:
        return [][]int{}
    case len(nums) == 1:
        return [][]int{{nums[0]}}
    case len(nums) == 2:
        return permute2(nums, 0, 1)
    case len(nums) == 3:
        return permute3(nums, 0, 1, 2)
    default:
        panic("no idea...")
    }
}

func permute2(nums []int, i, j int) [][]int {
    return [][]int{
        {nums[i], nums[j]},
        {nums[j], nums[i]},
    }
}

func permute3(nums []int, i, j, k int) [][]int {
    result := [][]int{}
    for _, s := range permute2(nums, j, k) {
        result = append(result, append(s, nums[i]))
    }
    for _, s := range permute2(nums, i, k) {
        result = append(result, append(s, nums[j]))
    }
    for _, s := range permute2(nums, i, j) {
        result = append(result, append(s, nums[k]))
    }
    return result
}
```

- 書いてるうちに一般的な場合の方針が立つかなと思ったが、全然思いつかなかったのでほかの方のコードを見てみることに
- https://github.com/hayashi-ay/leetcode/pull/57/files#diff-0d3699b3287447f54faf602faea01d8030e9339f00ffb22c5cc830676711ef22R133
    - これを読んでなんとなくわかった気になるが、問題の形が変わったときに自力で
    実装できる自信はあまりない
- `nextRemainingNums := append(remainingNums[:i], remainingNums[i+1:]...)`
としてWAとなった。
理由は、append で元のスライスのキャパシティ以下のスライスを作るときは新しいメモリ領域の確保が生じず、第一引数のスライスの領域がそのままつかわれるから
- 時間計算量: O(n * n!)
- 空間計算量: O(n!)

```Go
func permute(nums []int) [][]int {
	permutations := [][]int{}
	permutation := []int{}

	var permuteHelper func([]int)
	permuteHelper = func(remainingNums []int) {
		if len(permutation) == len(nums) {
			permutationCopy := make([]int, len(permutation))
			copy(permutationCopy, permutation)
			permutations = append(permutations, permutationCopy)
			return
		}
		for i := range remainingNums {
			permutation = append(permutation, remainingNums[i])
			nextRemainingNums := []int{}
			for j := range remainingNums {
				if j == i {
					continue
				}
				nextRemainingNums = append(nextRemainingNums, remainingNums[j])
			}
			permuteHelper(nextRemainingNums)
			permutation = permutation[:len(permutation)-1]
		}
	}

	permuteHelper(nums)
	return permutations
}
```

### Step 2
#### 2a
- slices.Concat を使えば二つのスライスを繋げて新しいスライスを作ってくれるので、
自分で copy() を使わずに済む

```Go
func permute(nums []int) [][]int {
	permutations := [][]int{}
	permutation := []int{}

	var permuteHelper func([]int)
	permuteHelper = func(remainingNums []int) {
		if len(permutation) == len(nums) {
			permutationCopy := make([]int, len(permutation))
			copy(permutationCopy, permutation)
			permutations = append(permutations, permutationCopy)
			return
		}
		for i := range remainingNums {
			permutation = append(permutation, remainingNums[i])
			nextRemainingNums := slices.Concat(remainingNums[:i], remainingNums[i+1:])
			permuteHelper(nextRemainingNums)
			permutation = permutation[:len(permutation)-1]
		}
	}

	permuteHelper(nums)
	return permutations
}
```

#### 2b
- 要素のスワップを繰り返して全通り作る方法
    - https://github.com/fhiyo/leetcode/pull/50/files#diff-76c4644fcedcaf9f8c6b6283fa29fa6b79699ef29285914474e37e05a3dbe5f7R224
- 最初はこの方法ですべての permutations を過不足なく生成できる理由がわからなかった
- permutation=[0,1,2,3,4] でヘルパー関数の引数が 2 だとすると、
最初の2要素は固定で後ろの3要素はスワップにより順番が変わっていく。
処理が戻って permutation=[1,0,2,3,4] でヘルパー関数に再び引数 2 が渡されると、
それ以降の要素がスワップされても最初の2要素は1,0で固定、みたいな理解。
    - 正直まだ他人に分かりやすく教えられるほどの理解度ではない
- nums のコピー上でスワップを行っているのはスレッドセーフ性を保つため
    - https://github.com/Exzrgs/LeetCode/pull/19#discussion_r1619656305
- permutationCopy を作らず permutation を返り値の permutations に入れたら permutations の中身が全部オリジナル nums と同じ順のものになった。
更にコピーしてやらないとメモリ空間を共有するスライスが permutations に入れられて行ってしまう。
ここら辺のメモリ共有についての意識がまだ低い

```Go
func permute(nums []int) [][]int {
	permutation := make([]int, len(nums))
	copy(permutation, nums)
	permutations := [][]int{}

	var permuteHelper func(int)
	permuteHelper = func(i int) {
		if i == len(permutation)-1 {
			permutationCopy := make([]int, len(permutation))
			copy(permutationCopy, permutation)
			permutations = append(permutations, permutationCopy)
			return
		}
		for j := i; j < len(permutation); j++ {
			permutation[i], permutation[j] = permutation[j], permutation[i]
			fmt.Println(permutation)
			permuteHelper(i + 1)
			permutation[i], permutation[j] = permutation[j], permutation[i]
		}
	}

	permuteHelper(0)
	return permutations
}
```

#### 2c
- 再帰でやったならスタックに直すべし
- https://github.com/olsen-blue/Arai60/pull/51/files#diff-0d3699b3287447f54faf602faea01d8030e9339f00ffb22c5cc830676711ef22R188
- 構造体の名前でいつも悩む。
下記リンク先で `state` と命名されていた。「permutationを作るための中間状態」という意味合いを持たせたいので `permutationState` みたいなのでありかも

```Go
func permute(nums []int) [][]int {
	permutations := [][]int{}
	type permutationState struct {
		permutation []int
		restNums    []int
	}
	stack := []permutationState{{[]int{}, nums}}
	for len(stack) > 0 {
		top := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if len(top.permutation) == len(nums) {
			permutations = append(permutations, top.permutation)
			continue
		}
		for i := range top.restNums {
			nextPermutation := slices.Concat(top.permutation, []int{top.restNums[i]})
			nextRestNums := slices.Concat(top.restNums[:i], top.restNums[i+1:])
			stack = append(stack, permutationState{nextPermutation, nextRestNums})
		}
	}
	return permutations
}
```

- まだ他の解法もありそうだが、時間がかかりすぎているので一旦ここまでにしてstep3に進む

### Step 3
- スタックを使った解法
- ついでにスタックも自作した

```Go
type Stack[T any] []T

func (s Stack[T]) IsEmpty() bool {
    return len(s) == 0
}

func (s *Stack[T]) Push(v T) {
    *s = append(*s, v)
}

func (s *Stack[T]) Pop() (T, error) {
    if s.IsEmpty() {
        var t T
        return t, errors.New("cannot pop from a empty stack")
    }
    n := len(*s)
    top := (*s)[n-1]
    *s = (*s)[:n-1]
    return top, nil
}

func permute(nums []int) [][]int {
    permutations := [][]int{}
    type permutationState struct {
        permutation []int
        restNums []int
    }
    stack := Stack[permutationState]{}
    stack.Push(permutationState{[]int{}, nums})
    for !stack.IsEmpty() {
        top, _ := stack.Pop()
        if len(top.permutation) == len(nums) {
            permutations = append(permutations, top.permutation)
            continue
        }
        for i := range top.restNums {
            nextPermutation := slices.Concat(top.permutation, []int{top.restNums[i]})
            nextRestNums := slices.Concat(top.restNums[:i], top.restNums[i+1:])
            stack.Push(permutationState{nextPermutation, nextRestNums})
        }
    }
    return permutations
}
```

- slices.Concatも自作してみる
- 標準ライブラリの実装では引数名が `slices` になっていたが、
そうしてしまうと内部で別の標準ライブラリ関数の `slices.Grow` を呼び出す時に
slices が変数名の方で認識されてしまうので `ss` という命名になった（ご容赦）
- make の代わりに slices.Grow が使われている理由がよくわからなかった。
やっていることは `newSlice := make([]E, 0, size)` と同じではないか？と思った

```Go
func concat[S ~[]E, E any](ss ...S) S {
    size := 0
    for _, s := range ss {
        size += len(s)
        if size < 0 {
            panic("len out of range")
        }
    }
    newSlice := slices.Grow[S](nil, size)
    for _, s := range ss {
        newSlice = append(newSlice, s...)
    }
    return newSlice
}
```

### CS