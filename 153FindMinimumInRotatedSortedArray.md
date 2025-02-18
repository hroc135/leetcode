問題: https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/description/

### Step 1
- O(log n)時間のアルゴリズムを書けと書いてあるが、
全く思いつかなかったので、一旦O(n)時間のコードを書いた
- データサイズも5000と小さいのでO(n)時間でも通ると思ったら案の定ACした

```Go
func findMin(nums []int) int {
	return slices.Min(nums)
}
```

- 以下を参考にして理解して何も見ずにコードを書く
    - https://github.com/hayashi-ay/leetcode/pull/45/files#diff-856251eccb601f9962fc7fdd308675f5690975413b45fe6be0950672570bc6caR74
    - https://github.com/hayashi-ay/leetcode/pull/45/files#diff-856251eccb601f9962fc7fdd308675f5690975413b45fe6be0950672570bc6caR1
- テストケース
    - [0] -> 0
    - [0,1] -> 0
    - [1,0] -> 0
    - [0,1,2] -> 0
    - [2,0,1] -> 0
    - [1,2,0] -> 0
    - [1,2,3,0] -> 0

```Go
func findMin(nums []int) int {
	left := 0
	right := len(nums) - 1
	for left < right {
		middle := left + (right-left)/2
		if nums[middle] > nums[len(nums)-1] {
			left = middle + 1
		} else {
			right = middle
		}
	}
	return nums[left]
}
```

### Step 2

#### 2a
- 閉区間の右端の値と真ん中の値を比較して狭めていく方法
- 言語化
1. 二分探索を、 [false, false, false, ..., false, true, true, ture, ..., true] と並んだ配列があったとき、 false と true の境界の位置を求める問題、または一番左の true の位置を求める問題と捉えているか？
    - 最小値より左の要素をfalse、最小値以降の要素をtrueとして、
    一番左のtrue、すなわち最小値を探す問題と捉える
    - [3,4,0,1,2] -> [false,false,true,true,true]
2. 位置を求めるにあたり、答えが含まれる範囲を狭めていく問題と捉えているか？
3. 範囲を考えるにあたり、閉区間・開区間・半開区間の違いを理解できているか？
    - 閉区間を採用
4. 用いた区間の種類に対し、適切な初期値を、理由を理解したうえで、設定できるか？
    - [left,right]=[0,len(nums)-1]
    - 閉区間を採用した理由は、右端の要素を比較に用いる際に、
    index out of rangeを起こしたくないから
    - (下記リンク先を見て追記)最終的に[false,false,[true],true,true]のように、
    左端も右端も一番左のtrueを指すようにしたい
        - https://github.com/seal-azarashi/leetcode/pull/39/files#r1851396321
5. 用いた区間の種類に対し、適切なループ不変条件を、理由を理解したうえで、設定できるか？
    - 終了条件はleft==right==(一番左のtrueのインデックス)
    - なので不変条件はleft<right
    - [left,right]の区間に最小値が存在するので、
    nums[left] >= (最小値), (最小値) <= nums[right]
6. 用いた区間の種類に対し、範囲を狭めるためのロジックを、理由を理解したうえで、適切に記述できるか？
    - leftとrightの中間middleを取る
    - 左側に区間を狭めるとき: nums[middle] < nums[right]
     -> middleが最小値である可能性があるので、rightをmiddleに更新
    - 右側に区間を狭めるとき: nums[middle] > nums[right]
     -> middleは最小値でないことが確定するので、leftをmiddle+1に更新
    - nums[middle] == nums[right]となる時は、
    numsの要素が全てuniqueであることとmiddleがleft寄りになることから、
    left==middle==rightの時にしか起きえない。
    この時、終了条件left==rightより、すでにループを出ている
    - 停止性: left<=middle<=rightで、right<-middle, left<-middle+1のどちらかが起きる。
    middleは左に寄ることからmiddle==right>leftになることはなく、区間が必ず1以上狭まるので停止する
- 言語化してからトップダウンにアルゴリズムをコードに落とし込むとかなりスッキリした
- 整理している中で重要だと感じたのは、middle=(left+right)/2で取ると、middle<rightが成り立つということ
- 「二分探索は鬼門」らしいが、講師陣は入力条件の制約からトップダウン的にアルゴリズムを設計しているか、
<=と<の使い分けを論理的に判断できているか、辺りを気にしている印象
    - https://github.com/seal-azarashi/leetcode/pull/39/files#r1849419449
    - https://github.com/seal-azarashi/leetcode/pull/39/files#r1851404872
    - https://discord.com/channels/1084280443945353267/1233295449985650688/1240269414415339571
    - https://github.com/Ryotaro25/leetcode_first60/pull/46#discussion_r1869993674

```Go
func findMin(nums []int) int {
	left := 0
	right := len(nums) - 1
	for left < right {
		middle := left + (right-left)/2
		switch {
		case nums[middle] < nums[right]:
			right = middle
		case nums[middle] > nums[right]:
			left = middle + 1
		case nums[middle] == nums[right]:
			// This code should be unreachable because all elements of nums are unique and middle<right.
			log.Fatal("Something went wrong.")
		}
	}
	return nums[left]
}
```

- 入力条件が変わった時に上記コードがどのような挙動をするのかの考察
    - numsが空
        - nums[0]を返そうとしてindex out of range。呼び出し側で弾きたい
    - 重複要素あり
        - `case nums[middle] == nums[right]:`に入ってしまう
        - [2,2,2,0,0,0,1,1,1]の場合、左端、右端、ランダムな0のうちどれを返すかで変わってくる
        - 左端を返したいなら、`case nums[middle] < nums[right]:`の<を<=に変える
        - 右端を返したいなら、[2,0,0,0,1]を[false,false,false,true,true]と捉える問題へとだいぶ様変わりする。
        middleが右に寄るように取る(切り上げ)などの工夫が必要そう
- https://github.com/Ryotaro25/leetcode_first60/blob/5cd497a61c1610dfb252de6f0dd2a0823e7b2bec/153.FindMinimuminRotatedSortedArray/step2.cpp#L9
    - 半開区間より閉区間を選びたくなった理由を的確に表現していると感じた

- odaさんが提示しているオプショナル質問を考えてみる(https://github.com/Ryotaro25/leetcode_first60/pull/46#discussion_r1869993674)
    - Q. 2で割る処理がありますがこれは切り捨てでも切り上げでも構わないのでしょうか
        - 構う。切り捨てならmiddle<rightが成り立つことから停止性を保証していたが、
        切り上げだとleft=0,right=1の時にmiddle=1となり、right<-middleへの更新によって区間が狭まらず、無限ループに陥る
    - Q. nums[middle] <= nums[right] とありますが、これは < でもいいですか
        - 良い。というか<を採用している。
        - ただし、<として良いのは、numsがuniqueであることが保証されているから
    - Q. nums[right] は、nums.back() でもいいですか
        - 良い。
        middle<right<=nums.back()だから、nums[middle]<nums.back()ならnums[middle]<nums[right]だし、
        nums[middle]>nums.back()ならnums[middle]>nums[right]なので
        - 個人的には二分探索は調べるべき区間を狭めていくアルゴリズムなので、left~right間で完結させたい気持ちがあり、
        nums[right]を比較に用いる方が好み
        - (以下リンク先を読んで追記) [false,...,false,true,...,true]のうち一番左のtrueを知りたいのだが、
        一番左のtrueの要素はそれより右のものより常に小さいので、どれと比べても良い
            - https://github.com/seal-azarashi/leetcode/pull/39/files#r1851140547
    - Q. right の初期値は nums.size() でもいいですか
        - nums[right]にアクセスしているので、index out of rangeを起こす
        - 初期値をnums.size()にするのなら区間を半開区間として、かつ比較をnums.back()で行うとできそう
            - 2cでやってみよう

#### 2b
- 2aを再帰でやってみる

```Go
func findMin(nums []int) int {
	var findMinHelper func(left int, right int) int
	findMinHelper = func(left, right int) int {
		if left == right {
			return nums[left]
		}
		middle := left + (right-left)/2
		switch {
		case nums[middle] < nums[right]:
			return findMinHelper(left, middle)
		case nums[middle] > nums[right]:
			return findMinHelper(middle+1, right)
		default:
			log.Fatal("Something went wrong.")
			return -1 // unreachable
		}
	}

	return findMinHelper(0, len(nums)-1)
}
```

#### 2c
- 半開区間を用いるとどうなるかを試してみる
1. 二分探索を、 [false, false, false, ..., false, true, true, ture, ..., true] と並んだ配列があったとき、 false と true の境界の位置を求める問題、または一番左の true の位置を求める問題と捉えているか？
    - 2aと同じ
2. 位置を求めるにあたり、答えが含まれる範囲を狭めていく問題と捉えているか？
3. 範囲を考えるにあたり、閉区間・開区間・半開区間の違いを理解できているか？
    - 半開区間を採用
4. 用いた区間の種類に対し、適切な初期値を、理由を理解したうえで、設定できるか？
    - [left,right)=[0,len(nums))
5. 用いた区間の種類に対し、適切なループ不変条件を、理由を理解したうえで、設定できるか？
    - 終了条件はleft==right==(一番左のtrueのインデックス)
    - ここまで考えて半開区間を採用することの辻褄を合わせるのが嫌になった
6. 用いた区間の種類に対し、範囲を狭めるためのロジックを、理由を理解したうえで、適切に記述できるか？

### Step 3

```Go
func findMin(nums []int) int {
	left := 0
	right := len(nums) - 1
	for left < right {
		middle := left + (right-left)/2
		switch {
		case nums[middle] < nums[right]:
			right = middle
			continue
		case nums[middle] > nums[right]:
			left = middle + 1
			continue
		default:
			log.Fatal("nums might contain duplicates.")
		}
	}
	return nums[left]
}
```
