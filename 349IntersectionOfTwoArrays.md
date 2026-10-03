### Step 1

#### 思考ログ
- nums2の要素がnums1にも含まれているかどうかを一つ一つ見ていけば良い
- 気をつけなければならないのは重複
  - 答えに重複を入れないことに気をつける
  - nums1, nums2内の重複要素に気をつける

#### 結果
- 初めて10分以内に解きかつ一発でACをもらえることができた
  - 嬉しい
  - Easy問題ではこれを当たり前にしていきたい
  - ACをもらうことがこの取り組みの目的ではない
- 時間計算量：O(n1 + n2 + intersections) = O(n)
  - 10^3 / 10^8 = 0.01ms が最悪の場合の見積もり実行時間
  - こうやって具体的な時間を見積もる場合には計算量をO(3n)とでもして0.03msとしたくなるが、望ましくないのだろうか？
  - ビッグオー記法はデータ量がめちゃくちゃ大きくなった時にどういう比率で計算時間が大きくなっていきますか？という概念だと理解しているが、
見積もり実行時間は具体的な時間が欲しいので係数をかけても悪くないはず
- 空間計算量：O(n1 + intersections*2) = O(n)

```Go
func intersection(nums1 []int, nums2 []int) []int {
    nums1Elems := make(map[int]struct{}, 1000)
    for _, n1 := range nums1 {
        nums1Elems[n1] = struct{}{}
    }

    intersections := make(map[int]struct{}, 1000)
    for _, n2 := range nums2 {
        if _, ok := nums1Elems[n2]; ok {
            intersections[n2] = struct{}{}
        }
    }

    ans := []int{}
    for n, _ := range intersections {
        ans = append(ans, n)
    }

    return ans
}
```

### Step 2
- https://github.com/seal-azarashi/leetcode/pull/13/files を参考にstep1のコードを修正
- 変更箇所
  - 空間計算量を削るために、nums1とnums2の長さの小さい方を集合化する
    - これにより空間計算量はO(min(n1, n2) + intersection*2)
  - `nums1Elems` -> `nums1UniqueElems`
  - よく考えたらintersectionsという変数名は英語が変だなということでintersectionに変更
  - ansの長さはintersectionのキーの数と同じになるはずなので、宣言時に容量を割り当てる
    - スライスのmakeは`make(type, length, capacity)`

```Go
func intersection(nums1 []int, nums2 []int) []int {
    if len(nums1) > len(nums2) {
        return intersection(nums2, nums1)
    }

    nums1UniqueElems := make(map[int]struct{})
    for _, n1 := range nums1 {
        nums1UniqueElems[n1] = struct{}{}
    }

    intersection := make(map[int]struct{})
    for _, n2 := range nums2 {
        if _, ok := nums1UniqueElems[n2]; ok {
            intersection[n2] = struct{}{}
        }
    }

    ans := make([]int, 0, len(intersection))
    for n, _ := range intersection {
        ans = append(ans, n)
    }

    return ans
}
```

- in-placeな方法でも実装してみた
- 時間計算量：O(n log n) （ソートがボトルネック）
- 空間計算量：O(1)

```Go
func intersection(nums1 []int, nums2 []int) []int {
    if len(nums1) > len(nums2) {
        return intersection(nums2, nums1)
    }

    slices.Sort(nums1)
    slices.Sort(nums2)

    i1, i2 := len(nums1) - 1, len(nums2) - 1
    for i1 >= 0 && i2 >= 0 {
        if nums1[i1] < nums2[i2] {
            i2--
            continue
        }
        if nums1[i1] > nums2[i2] {
            nums1 = slices.Delete(nums1, i1, i1+1)
            i1--
            continue
        }

        if i1 > 0 && nums1[i1] == nums1[i1-1] {
            nums1 = slices.Delete(nums1, i1, i1+1)
            i1--
            continue
        }

        i1--
    }

    if i1 >= 0 {
        nums1 = nums1[i1+1:]
    }

    return nums1
}
```

### Step 3
- step1と同じ方法だが、nums1Setをただの集合ではなく、値としてnums2にも含まれるかどうかを保持するようにした
  - これにより、空間計算量がO(min(n1, n2) + intersections*2) -> O(min(n1, n2) + intersection) と僅かながら改善した

```Go
func intersection(nums1 []int, nums2 []int) []int {
    if len(nums1) > len(nums2) {
        return intersection(nums2, nums1)
    }

    type inNums2Bool bool

    nums1Set := make(map[int]inNums2Bool)
    for _, n1 := range nums1 {
        nums1Set[n1] = false
    }

    for _, n2 := range nums2 {
        if _, ok := nums1Set[n2]; ok {
            nums1Set[n2] = true
        }
    }

    intersection := make([]int, 0, len(nums1Set))
    for n1, inNums2 := range nums1Set {
        if inNums2 {
            intersection = append(intersection, n1)
        }
    }

    return intersection
}
```
