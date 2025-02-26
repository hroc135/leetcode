問題: https://leetcode.com/problems/capacity-to-ship-packages-within-d-days/description/

### Step 1
- 見当もつかなかったので他の人のプルリクを見た
    - https://github.com/hayashi-ay/leetcode/pull/55/files#diff-4e146417f14c744a10f851601f26cd2cb17b420ff966720e568f6f5679aa475eR1
    - https://github.com/Mike0121/LeetCode/pull/46/files
- なるほど、答えのcapacityは[weightsの最大要素, weightsの総計]の区間に存在することになるので、その範囲を探索すれば良いのか
- まずは線形に探索していく。時間計算量はO(len(weights) * (weightsSum-maxWeight))になるので、weightsの要素が大きいと時間がかかりそう
- 案の定TLEした

```Go
func shipWithinDays(weights []int, days int) int {
	maxWeight := slices.Max(weights)
	weightSum := 0
	for _, w := range weights {
		weightSum += w
	}
	for capacity := maxWeight; capacity <= weightSum; capacity++ {
		if isShipableWithinCapacity(weights, days, capacity) {
			return capacity
		}
	}
	panic("unreacheable")
}

func isShipableWithinCapacity(weights []int, days int, capacity int) bool {
	day := 1
	weight := 0
	for _, w := range weights {
		if weight+w > capacity {
			day++
			weight = 0
		}
		weight += w
		if day > days {
			return false
		}
	}
	return true
}
```

- ここで登場するのが二分探索
- [weightsの最大要素, weightsの総計]の区間を、
true: 与えられたdays以内に出荷できるcapacity と定義すると、
[false,...,false,true,...,true]という配列になり、一番左のtrueの位置を求める
- trueは必ず存在するので、閉区間を使って範囲を狭めていき、left==rightとなったらその値が求めたいcapacity
- Goではcapはbuilt-in関数名になっているため、変数名として使用することは避ける
- Goにはスライスの要素の総計を求める標準ライブラリ関数が存在しない

```Go
func shipWithinDays(weights []int, days int) int {
	maxWeight := slices.Max(weights)
	weightsSum := 0
	for _, w := range weights {
		weightsSum += w
	}
	low := maxWeight
	high := weightsSum
	for low < high {
		middle := low + (high-low)/2
		if isShipableWithinCapacity(weights, days, middle) {
			high = middle
		} else {
			low = middle + 1
		}
	}
	return low
}

func isShipableWithinCapacity(weights []int, days int, capacity int) bool {
	day := 1
	weight := 0
	for _, w := range weights {
		if weight+w > capacity {
			day++
			weight = 0
		}
		weight += w
		if day > days {
			return false
		}
	}
	return true
}
```

### Step 2
#### 2a
- shipableではなくshippable
- ヘルパー関数をshippableかどうかのbool値で出力する方法以外に、
capacityに対して何日必要かを返してそれがdays以下かどうかを呼び出し元で確認する方法もある。
このほうがヘルパー関数がシンプルになる一方、daysを超えた時点でfalseを返す方が速い

```Go
func shipWithinDays(weights []int, days int) int {
	maxWeight := slices.Max(weights)
	weightsSum := 0
	for _, w := range weights {
		weightsSum += w
	}
	low := maxWeight
	high := weightsSum
	for low < high {
		middle := low + (high-low)/2
		requiredDays := requiredDaysToShip(weights, middle)
		if requiredDays <= days {
			high = middle
		} else {
			low = middle + 1
		}
	}
	return low
}

// requiredDaysToShip returns the minimum days to ship within the given capacity.
func requiredDaysToShip(weights []int, capacity int) int {
	days := 1
	weight := 0
	for _, w := range weights {
		if weight+w > capacity {
			days++
			weight = w
			continue
		}
		weight += w
	}
	return days
}
```

#### 2b
- 標準ライブラリ関数のslices.BinarySearchFuncを使ってみる
- [maxWeight,weightsSum]区間のスライスを作成しないといけないため、
空間計算量がO(n)になる
    - pythonのbisect_leftならrangeを使って空間計算量をO(1)に抑えられるらしい
        - https://github.com/fhiyo/leetcode/pull/45#discussion_r1682470839
- shippableなcapacityを1, そうでないものを0として
[0,...,0,1,...,1]という配列の左端の1の位置を返す
- bool値を使わなかったのは、BinarySearchFuncの第三引数がint型を返す関数であり、bool値同士の演算をint型に変換するのが面倒だったから

```Go
func SumInt(s []int) int {
	sum := 0
	for _, v := range s {
		sum += v
	}
	return sum
}

func shipWithinDays(weights []int, days int) int {
	maxWeight := slices.Max(weights)
	weightsSum := SumInt(weights)
	capacities := make([]int, weightsSum-maxWeight+1)
	for i := range capacities {
		capacities[i] = maxWeight + i
	}
	index, _ := slices.BinarySearchFunc(capacities, 1, func(capacity int, t int) int {
		return isShippable(weights, days, capacity) - t
	})
	return capacities[index]
}

// isShippable returns 1 if shippable and 0 if not
func isShippable(weights []int, days int, capacity int) int {
	day := 1
	weight := 0
	for _, w := range weights {
		if weight+w > capacity {
			day++
			weight = 0
		}
		weight += w
		if day > days {
			return 0
		}
	}
	return 1
}
```

### Step 3
- 日数を調べるよりヘルパー関数で判定できた方が自分は好きなのでstep1の方法
- `isShippable`より`canShip`の方がシンプル
    - https://github.com/goto-untrapped/Arai60/pull/41/files#diff-cc45bac68955c702274e070386dd9a6db7bad032fdc75cf32cbea4781f618685R17
- `low := slices.Max(weights)`とすることに抵抗があったが、割とそうしている人がいる
    - https://github.com/fhiyo/leetcode/pull/45/files#diff-3e42d068b82e2a1be434dc989edc077d304c433f9a25ad4a2b3bc8f9223e43bcR33
- `day` -> `daysRequired`
    - https://github.com/fhiyo/leetcode/pull/45/files#r1682612140
- ヘルパー関数の`canShip()`をinner functionにするかどうか迷った。
    - inner functionにするメリットは、依存関係が生じるリスクをなくせること。
    引数が減ること
    - Goのスライスは参照渡しなのでメモリ使用量が増える心配はしなくてよい
    - inner functionではなく、外で定義した方が個人的には見やすい
    - 機能面的にはinner functionにした方がメリットが多そう

```Go
func SumInts(s []int) int {
	sum := 0
	for _, v := range s {
		sum += v
	}
	return sum
}

func shipWithinDays(weights []int, days int) int {
	canShip := func(capacity int) bool {
		daysRequired := 1
		loadedWeight := 0
		for _, weight := range weights {
			if loadedWeight+weight > capacity {
				daysRequired++
				loadedWeight = 0
			}
			if daysRequired > days {
				return false
			}
			loadedWeight += weight
		}
		return true
	}

	low := slices.Max(weights)
	high := SumInts(weights)
	for low < high {
		middle := low + (high-low)/2
		if canShip(middle) {
			high = middle
		} else {
			low = middle + 1
		}
	}
	return low
}
```