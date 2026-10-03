問題: https://leetcode.com/problems/search-insert-position/description/

### Step 1
- Goの標準パッケージにBinarySearchがあるのでそれを使うことに
- BinarySearchは返り値がintとbool値の二つ。
int型の返り値はtargetがあればそのtargetと同じ値の要素のうち最も若いインデックスが返り、
targetがなければinsert positionが返る。
bool値の返り値はtargetがあったかなかったかどうか

```Go
func searchInsert(nums []int, target int) int {
	index, _ := slices.BinarySearch(nums, target)
	return index
}
```

- ライブラリを使わずに実装する
- テストケース
    - nums=[], target=1 -> 0
    - nums=[0], target=0 -> 0
    - nums=[0], target=-1 -> 0
    - nums=[0], target=1 -> 1
    - nums=[0,2,4,6], target=4 -> 2
    - nums=[0,2,4,6], target=6 -> 3
    - nums=[0,2,4,6], target=7 -> 4
    - nums=[0,2,4,6], target=-1 -> 0
    - nums=[0,2,4,6], target=3 -> 2
    - nums=[0,2,4,6,8], target=3 -> 2
- このコードでは同じ要素が複数ある場合にどのインデックスを返すかが統一されないことに留意
    - nums=[0,0,0,0], target=0 -> 2
- なんとなく半開区間によるインデックス管理を採用したが、
閉区間だとどうなるかstep2でやってみる
- あとは再帰も選択肢
- データ数が少なければ前から順に見ていけば良い
    - メモリへのアクセスが二分探索のようにランダムにならず、
    キャッシュがいい感じに使われるのでむしろこちらの方が速い場合もあると聞いたことがある

```Go
func searchInsert(nums []int, target int) int {
	// left and right are half open index such that [left, right)
	left := 0
	right := len(nums)
	for {
		if left == right {
			return left // not found
		}
		middle := (left + right) / 2
		if nums[middle] == target {
			return middle
		}
		if nums[middle] < target {
			left = middle + 1
			continue
		}
		right = middle
	}
}
```

### Step 2
- 二分探索について、以前discordで議論されていたのを覚えていたので、まずそこから確認してみる
    - https://discord.com/channels/1084280443945353267/1196498607977799853/1268762035173326959
- middleを計算する際にinteger overflowを起こさないための工夫
    - https://github.com/Ryotaro25/leetcode_first60/pull/45#discussion_r1878268512
- 何を探しているのかを明確にする
    - https://discord.com/channels/1084280443945353267/1084283898617417748/1281994919417745528
    - 今回は同じ値の要素がないので、targetが存在すれば最初にtargetと一致する要素のインデックス、targetが存在しなければinsert positionを返す
    - つまり、`nums[i] == target`or`nums[i] < target < nums[i+1]`となるiを返す
    - ただし、`target < nums[0]`なら0を、`nums[len(nums)-1] < target`ならlen(nums)を返す
- discordで二分探索の考え方のステップについて書いてあったので、それに従って言語化してみる
    - https://discord.com/channels/1084280443945353267/1196498607977799853/1269532028819476562

#### 2a
- step1を言語化
1. 二分探索を、 [false, false, false, ..., false, true, true, ture, ..., true] と並んだ配列があったとき、 false と true の境界の位置を求める問題、または一番左の true の位置を求める問題と捉えているか？
    - false: target未満、true: target以上として一番左のtrueの位置を求める問題として捉える
2. 位置を求めるにあたり、答えが含まれる範囲を狭めていく問題と捉えているか？
    - step1の解法だと範囲を狭めていきつつ、たまたまmiddleがヒットしたらmiddleを返すという仕様だった。
    これがいいのか悪いのかよくわからないが、ここは範囲をひたすら狭めていく方法でやってみる
3. 範囲を考えるにあたり、閉区間・開区間・半開区間の違いを理解できているか？
    - [left, right)という半開区間を狭めていく方法を使う
4. 用いた区間の種類に対し、適切な初期値を、理由を理解したうえで、設定できるか？
    - 初期状態として、配列の全ての要素が[left, right)にちょうど含まれている必要があるので、
    left=0, right=len(nums)
5. 用いた区間の種類に対し、適切なループ不変条件を、理由を理解したうえで、設定できるか？
    - ループ不変条件は`nums[left] <= target < nums[right]`と`left < right`
    - https://discord.com/channels/1084280443945353267/1196498607977799853/1269560324818731028 を見ると、終了条件から考えている
    - 終了条件は、leftもrightも一番左のtrueを指している時、つまり、left==rightの時
    - こう考えると不変条件を`left != right`としても良いことになるが、
    上記リンク先では`left < right`になっている。
    こちらの方がわかりやすい。
    一応、left == rightにならずにright < leftになることはないので
    `left != right`としても動くはずではある。
    (実際にleetcode上でもACした)
6. 用いた区間の種類に対し、範囲を狭めるためのロジックを、理由を理解したうえで、適切に記述できるか？
    - まず、middleを取る
    - `nums[middle] < target`、`target <= nums[middle]`の2パターンがあり得る
    - パターン1: 範囲を[middle+1, right)に更新
    - パターン2: 範囲を[left, middle)に更新

```Go
func searchInsert(nums []int, target int) int {
	left := 0
	right := len(nums)
	for left < right {
		middle := left + (right-left)/2
		if nums[middle] < target {
			left = middle + 1
		} else {
			right = middle
		}
	}
	return left
}
```

#### 2b
- 閉区間
- 1,2は2aと同じ
3. 範囲を考えるにあたり、閉区間・開区間・半開区間の違いを理解できているか？
    - 閉区間を使う
4. 用いた区間の種類に対し、適切な初期値を、理由を理解したうえで、設定できるか？
    - 初期状態として、配列の全ての要素が[left, right]にちょうど含まれている必要があるので、
    left=0, right=len(nums)-1
5. 用いた区間の種類に対し、適切なループ不変条件を、理由を理解したうえで、設定できるか？
    - ループ終了時に、false,false],[true,trueとなって欲しい([はleft, ]はright)ので終了条件はleft > right
    - こうしないとinsert positionが右端の場合に困る
    - 不変条件は`left <= right`
6. 用いた区間の種類に対し、範囲を狭めるためのロジックを、理由を理解したうえで、適切に記述できるか？
    - まず、middleを取る
    - `nums[middle] < target`、`target <= nums[middle]`の2パターンがあり得る
    - パターン1: 範囲を[middle+1, right]に更新
    - パターン2: 範囲を[left, middle-1]に更新
        - ここで[left, middle]ではなくmiddle-1にしたのは、
        5番の終了条件のようにleftとrightが逆転する瞬間がないといけないから
        - と理解して一度納得したが`nums[left] <= target <= nums[right]`が不変条件にならないのは気持ち悪い
- 参考: https://github.com/Ryotaro25/leetcode_first60/pull/45/files#r1888663072

```Go
func searchInsert(nums []int, target int) int {
	left := 0
	right := len(nums) - 1
	for left <= right {
		middle := left + (right-left)/2
		if nums[middle] < target {
			left = middle + 1
		} else {
			right = middle - 1
		}
	}
	return left
}
```

#### 2c
- 再帰
- スタックフレームが積まれていくので空間計算量はO(log n)になる

```Go
func searchInsert(nums []int, target int) int {
	var searchInsertHelper func(left int, right int) int
	searchInsertHelper = func(left, right int) int {
		if left == right {
			return left
		}
		middle := left + (right-left)/2
		if nums[middle] < target {
			return searchInsertHelper(middle+1, right)
		} else {
			return searchInsertHelper(left, middle)
		}
	}

	return searchInsertHelper(0, len(nums))
}
```

#### 2d
- 前から舐めていく
    - 入力が小さければこれでも良い
- TLEするかと思ったら通った
    - 入力サイズが高々10^4なので、1e4 / 1e8 = 1e-4 -> 0.1msでできてしまう

```Go
func searchInsert(nums []int, target int) int {
	for i, n := range nums {
		if n < target {
			continue
		}
		return i
	}
	return len(nums)
}
```

### Step 3
- 半開区間のループ
- step2では「答えが含まれる範囲を狭めていく問題」と捉えることを重視して
nums[middle] == targetの時にすぐ答えを返すということをしなかったが、
今回のようにstrictly ascendingならそうした方が直感的だと思った
- 停止性についての確認の仕方
    - https://github.com/seal-azarashi/leetcode/pull/38#discussion_r1845409634

```Go
func searchInsert(nums []int, target int) int {
	left := 0
	right := len(nums)
	for left < right {
		middle := left + (right-left)/2
		if nums[middle] == target {
			return middle
		}
		if nums[middle] < target {
			left = middle + 1
		} else {
			right = middle
		}
	}
	return left
}
```