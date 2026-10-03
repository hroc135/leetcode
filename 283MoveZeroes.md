問題: https://leetcode.com/problems/move-zeroes/description/

### Step 1
- 前から舐めるとインデックスのずれを考慮する必要があって面倒なので、後ろから回した
- in-place でという制約を見落としていて、参照透過性を考慮してコピーを作成していたが、不要だった

```Go
func moveZeroes(nums []int)  {
    for i := len(nums) - 1; i >= 0; i-- {
        if nums[i] == 0 {
            nums = slices.Delete(nums, i, i+1)
            nums = append(nums, 0)
        }
    }
}
```

### Step 2
#### 2a
- step1 の修正
- slices.Delete の内部実装を見たところ、例外処理などのオーバーヘッドがあり、今回は不要だと思ったので、使わなかった
- よく考えたら append(nums[:i], nums[i+1:]...) は O(n-i+1)=O(n) 時間かかっているので、全体で O(n^2) になってしまっていた

```Go
func moveZeroes(nums []int) {
	for i := len(nums) - 1; i >= 0; i-- {
		if nums[i] == 0 {
			nums = append(nums[:i], nums[i+1:]...)
			nums = append(nums, 0)
		}
	}
}
```

#### 2b
- https://github.com/fhiyo/leetcode/pull/54/files#diff-2f8b85074aa38861aa9dd6fbe0c5f1b540a06f8618d7552b4ffd05da21f795d3R17
- 時間計算量: O(2n) = O(n)
- 空間計算量: O(n)

```Go
func moveZeroes(nums []int) {
	nonzeroes := []int{}
	for _, n := range nums {
		if n != 0 {
			nonzeroes = append(nonzeroes, n)
		}
	}
	copy(nums, nonzeroes)
	for i := len(nonzeroes); i < len(nums); i++ {
		nums[i] = 0
	}
}
```

#### 2c
- 2b を in-place に
    - https://github.com/fhiyo/leetcode/pull/54/files#diff-2f8b85074aa38861aa9dd6fbe0c5f1b540a06f8618d7552b4ffd05da21f795d3R88
- 時間計算量: O(2n) = O(n)
- 空間計算量: O(1)
- https://github.com/fhiyo/leetcode/pull/54/files#r1729230640
    - コンパイラでループ展開（loop unrolling）してくれる場合もある
    - ここまで頭が回っていなかった
- https://discord.com/channels/1084280443945353267/1201211204547383386/1230568276690468917
    - たしかにこっちのほうがしっくりくる
- erase-remove idiom というのがあるらしい
    - C++ の remove と大体同じ実装
    - https://cplusplus.com/reference/algorithm/remove/

```Go
func moveZeroes(nums []int)  {
    nonzeroCount := 0
    for _, n := range nums {
        if n != 0 {
            nums[nonzeroCount] = n
            nonzeroCount++
        }
    }
    for i := nonzeroCount; i < len(nums); i++ {
        nums[i] = 0
    }
}
```

#### 2d
- https://github.com/fhiyo/leetcode/pull/54/files#diff-2f8b85074aa38861aa9dd6fbe0c5f1b540a06f8618d7552b4ffd05da21f795d3R136
- https://github.com/rihib/leetcode/pull/50/files#diff-6dd7d1270e29a07842912b50d2236807871f48d1b90d26c0bc9ad4d0ecd8f05dR18
- 0 でないものを前に持ってくることで、0 がバブルソートぽく後ろに押し出される方法
- > 仮に仕様変更で0ではなくて0以下を端に寄せたいとなった場合にもcontinueする条件をnums[i] <= 0とするだけでワークするので、良いと思います。
    - https://github.com/fhiyo/leetcode/pull/54/files#r1720791348
    - この視点はなかった。コードの保守性を考慮するというのはこういうことなのか。奥が深い、、
- Go は `nums[0], nums[0] = nums[0], nums[0]` でも動くが、気持ち悪いので、`i == nonzeroCount` の場合は弾いた
    - Goの場合は特別に弾かなくてもよいが、C++ だと未定義動作になるらしい

```Go
func moveZeroes(nums []int) {
	nonzeroCount := 0
	for i, n := range nums {
		if n == 0 {
			continue
		}
		if i == nonzeroCount {
			nonzeroCount++
			continue
		}
		nums[nonzeroCount], nums[i] = nums[i], nums[nonzeroCount]
		nonzeroCount++
	}
}
```

### Step 3
- 2c が一番素直な理解だと思うし、ループ展開のメリットもありそう
- slices.Delete の内部実装を調べていたらビルトインの clear を見つけ、調べたら最後の 0 埋めに使えそうだった
    - ただし、要件が変わったときに潰しが効かなさそうではある

```Go
func moveZeroes(nums []int)  {
    nonzeroCount := 0
    for _, n := range nums {
        if n != 0 {
            nums[nonzeroCount] = n
            nonzeroCount++
        }
    }
    clear(nums[nonzeroCount:])
}
```

- slices.Delete

```Go
func Delete[S ~[]E, E any](s S, i, j int) S {
	_ = s[i:j:len(s)] // 0 ≤ i ≤ j ≤ len(s) を満たしていなければ run time panic する
	if i == j {
		return s
	}
	oldLen := len(s)
	s = append(s[:i], s[j:]...)
	clear(s[len(s):oldLen])
	return s
}
```

### CS