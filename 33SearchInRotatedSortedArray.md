問題: https://leetcode.com/problems/search-in-rotated-sorted-array/description/

### Step 1
- O(log n)時間という縛りがなければ単に線形探索で良い
- データサイズも高々5000なのでACできる
- slices.Indexは探したい値が存在しない場合に-1を返す

```Go
func search(nums []int, target int) int {
	return slices.Index(nums, target)
}
```

- わからなかったので、以下リンク先を参考に
    - https://github.com/hayashi-ay/leetcode/pull/49/files#diff-0691fd54173ad5183bf1c632f87cc4a7353908565057fa6b9facae8e8ec5ec4bR32
- pivotを探す
    - pivotと表現できることを知らなかったが、標準的に使われているぽい
    - https://www.geeksforgeeks.org/search-an-element-in-a-sorted-and-pivoted-array/

```Go
func search(nums []int, target int) int {
	pivotIndex := searchPivotIndex(nums)
	if target <= nums[len(nums)-1] {
		index := searchTargetIndex(nums[pivotIndex:], target)
		if index < 0 {
			return -1
		}
		return index + pivotIndex
	}
	index := searchTargetIndex(nums[:pivotIndex], target)
	if index < 0 {
		return -1
	}
	return index
}

func searchPivotIndex(nums []int) int {
	left := 0
	right := len(nums) - 1
	for left < right {
		middle := left + (right-left)/2
		if nums[middle] <= nums[right] {
			right = middle
		} else {
			left = middle + 1
		}
	}
	return left
}

func searchTargetIndex(nums []int, target int) int {
	left := 0
	right := len(nums) - 1
	for left <= right {
		middle := left + (right-left)/2
		if nums[middle] == target {
			return middle
		}
		if nums[middle] < target {
			left = middle + 1
		} else {
			right = middle - 1
		}
	}
	return -1
}
```

### Step 2
#### 2a
- 昇順に並んでいるかどうかを考慮して一つの二分探索で行う方法
- https://github.com/hayashi-ay/leetcode/pull/49/files#diff-0691fd54173ad5183bf1c632f87cc4a7353908565057fa6b9facae8e8ec5ec4bR1
- テストケース
    - nums=[0], target=0 -> 0
    - nums=[0], target=-1 -> -1
    - nums=[0,2], target=-1 -> -1
    - nums=[0,2], target=0 -> 0
    - nums=[0,2], target=1 -> -1
    - nums=[0,2], target=2 -> 1
    - nums=[0,2], target=3 -> -1
    - nums=[2,0], target=-1 -> -1
    - nums=[2,0], target=0 -> 1
    - nums=[2,0], target=1 -> -1
    - nums=[2,0], target=2 -> 0
    - nums=[2,0], target=3 -> -1
    - nums=[6,0,2,4], target=6 -> 0
    - nums=[6,0,2,4], target=0 -> 1
    - nums=[6,0,2,4], target=7 -> -1
- 言語化
1. true: nums中のtargetと一致する要素とそれより右側の要素、
としてnumsを[false,...,false,true,...,true]のような配列とみなした時、
一番左のtrueの位置を探す問題と捉える
    - nums=[6,0,2,4], target=2 -> [false,false,true,true]
    - nums=[6,0,2,4], target=1 -> [false,false,false,false]
2. 位置を求めるにあたり、答えが含まれる範囲を狭めていく問題と捉える
3. 閉区間を採用。
targetがnumsに含まれるという仮定の元で探索を行うので
4. 閉区間[left,right]の初期値は[0,len(nums)-1]
5. 終了条件はleft>right。
つまり、rightがleftより左側に来たらtrueはなかったということになり、targetは存在しないので-1を返す。
よって、不変条件はleft<=right
6. 区間を狭めるためのロジックを考える。
    - middleを切り捨てで取る
    - `nums[middle] > nums[len(nums)-1]`であれば、[0,middle]は昇順。`nums[middle] <= nums[len(nums)-1]`であれば、[middle,len(nums)-1]は昇順。
    - 昇順であるとわかった方の区間でtargetが大小関係的に含まれるかどうかを調べ、含まれればそちらの区間を、含まれなければ反対側を探索する

```Go
func search(nums []int, target int) int {
	left := 0
	right := len(nums) - 1
	for left <= right {
		middle := left + (right-left)/2
		if nums[middle] == target {
			return middle
		}
		if nums[middle] > nums[len(nums)-1] { // 区間[0,middle]は昇順
			if nums[0] <= target && target < nums[middle] {
				right = middle - 1
			} else {
				left = middle + 1
			}
		} else { // 区間[middle,len(nums)-1]は昇順
			if nums[middle] < target && target <= nums[len(nums)-1] {
				left = middle + 1
			} else {
				right = middle - 1
			}
		}
	}
	return -1
}
```

#### 2b
- numsを-2,-1,0,1からなる昇順配列に変換してしまう方法
- 感動
- 参考
    - (一番わかりやすかった。ただし、下記コードは尻との比較を採用) https://discord.com/channels/1084280443945353267/1233295449985650688/1239446770761596928
    - https://discord.com/channels/1084280443945353267/1233295449985650688/1239594872697262121
- nums=[0,2,4,6,8,10], target=4
    - targetとの比較 -> [-1,-1,0,+1,+1,+1]
    - 尻との比較 -> [0,0,0,0,0,0]
    - 合計 -> [-1,-1,[0],1,1,1]
- nums=[8,10,0,2,4,6], target=4
    - targetとの比較 -> [+1,+1,-1,-1,0,+1]
    - 尻との比較 -> [-2,-2,0,0,0,0]
    - 合計 -> [-1,-1,-1,-1,[0],1]
- nums=[4,6,8,10,0,2], target=4
    - targetとの比較 -> [0,+1,+1,+1,-1,-1]
    - 尻との比較 -> [-2,-2,-2,-2,0,0]
    - 合計 -> [[-2],-1,-1,-1,-1,-1]
- nums=[2,4,6,8,10,0], target=4
    - targetとの比較 -> [-1,0,+1,+1,+1,-1]
    - 尻との比較 -> [-2,-2,-2,-2,-2,0]
    - 合計 -> [-3,[-2],-1,-1,-1,-1]
- nums=[2,4,6,8,10,0], target=5
    - targetとの比較 -> [-1,-1,+1,+1,+1,-1]
    - 尻との比較 -> [-2,-2,-2,-2,-2,0]
    - 合計 -> [-3,-3,-1,-1,-1,-1]
- targetとの大小関係から-1,0,+1の配列に変換する
 -> 尻より大きい要素は回転後に[+1,+1,-1,-1,0]のように昇順を崩すので、-2することによって昇順にする
 -> targetは尻より大きければ(回転後に最小値より前に来ていたら)-2になっているし、そうでなければ0
- この方法自体は自力で思いつける必要はないだろう
    - でもBoolToIntのようにGoでbool値をint型に変換する方法はまたどこかで使いそう
    - (a > b) - (a < b) も大小関係を-1,0,1に帰着させる方法として覚えておいた方がよさそう

```Go
func BoolToInt(t bool) int {
    if t {
        return 1
	}
	return 0
}

func search(nums []int, target int) int {
    targetComparison := func(n int) int {
        return BoolToInt(n > target) - BoolToInt(n < target)
	}
	converter := func(n int) int {
        return BoolToInt(nums[len(nums)-1] < n)*-2 + targetComparison(n)
	}
	index, found := slices.BinarySearchFunc(nums, target, func(a, b int) int {
        return converter(a) - converter(b)
	})
	if !found {
        return -1
	}
	return index
}
```

#### 2c
- 2bと同じロジックを構造体を使って実装
- numsの尻より大きいか -> targetとの大小比較 の順に調べる
- https://github.com/Yoshiki-Iwasa/Arai60/pull/36/files#r1712955053
- こっちの方がわかりやすい

```Go
func Btoi(t bool) int {
	if t {
		return 1
	}
	return 0
}

func search(nums []int, target int) int {
	comparisonPriority := func(n int) [2]int {
		return [2]int{Btoi(n <= nums[len(nums)-1]), Btoi(n > target) - Btoi(n < target)}
	}
	compareNums := func(a, b int) int {
		aPriority := comparisonPriority(a)
		bPriority := comparisonPriority(b)
		if aPriority[0] != bPriority[0] {
			return aPriority[0] - bPriority[0]
		}
		return aPriority[1] - bPriority[1]
	}
	index, found := slices.BinarySearchFunc(nums, target, func(a, b int) int {
		return compareNums(a, b)
	})
	if !found {
		return -1
	}
	return index
}
```

#### 2d
- 2cをBinarySearchFuncを使わずに実装

```Go
func search(nums []int, target int) int {
	left := 0
	right := len(nums)
	isTargetLargerThanTail := target > nums[len(nums)-1]
	for left < right {
		middle := left + (right-left)/2
		if (nums[middle] > nums[len(nums)-1]) == isTargetLargerThanTail {
			if nums[middle] < target {
				left = middle + 1
			} else {
				right = middle
			}
			continue
		}
		if isTargetLargerThanTail {
			right = middle - 1
		} else {
			left = middle + 1
		}
	}
	if left == len(nums) || nums[left] != target {
		return -1
	}
	return left
}
```

### Step 3
- 2c, 2dの考え方が一番好きだったのでそれを3回書く

```Go
func search(nums []int, target int) int {
	left := 0
	right := len(nums)
	tail := nums[len(nums)-1]
	isTargetLargerThanTail := target > tail
	for left < right {
		middle := left + (right-left)/2
		if (nums[middle] > tail) == isTargetLargerThanTail {
			if nums[middle] < target {
				left = middle + 1
			} else {
				right = middle
			}
			continue
		}
		if nums[middle] > tail {
			left = middle + 1
		} else {
			right = middle - 1
		}
	}
	if left < len(nums) && nums[left] == target {
		return left
	}
	return -1
}
```
